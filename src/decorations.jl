# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
# ==============================================================================
#
#   Functions related to decorations in strings.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

export drop_inactive_properties, get_decorations, get_and_remove_decorations
export parse_decoration, remove_decorations, replace_default_background, update_decoration

"""
    drop_inactive_properties(decoration::Decoration)

Drop the inactive properties of `decoration` by changing them to inactive. This
operation can be useful to avoid unnecessary escape sequences if the decorations
are reset.
"""
function drop_inactive_properties(decoration::Decoration)

    # Unpack fields.
    foreground = decoration.foreground
    background = decoration.background
    bold       = decoration.bold
    underline  = decoration.underline
    reversed   = decoration.reversed

    # If a field is inactive or if it is a reset to a default value, drop it by
    # returning to default.
    if foreground == "39"
        foreground =  ""
    end

    if background == "49"
        background = ""
    end

    if bold == inactive
        bold = unchanged
    end

    if underline == inactive
        underline = unchanged
    end

    if reversed == inactive
        reversed = unchanged
    end

    return Decoration(;
        foreground,
        background,
        bold,
        underline,
        reversed
    )
end

"""
    get_decorations(str::AbstractString)

Return a string with the decorations in `str`.
"""
function get_decorations(str::AbstractString)
    buf = IOBuffer(sizehint = sizeof(str))

    for m in eachmatch(_REGEX_ANSI, str)
        write(buf, m.match)
    end

    return String(take!(buf))
end

"""
    get_and_remove_decorations(str::AbstractString)

Get and remove the decorations in `str`. The first returned string contains the
decorations whereas the second contains the plain text.
"""
function get_and_remove_decorations(str::AbstractString)
    buf_decorations = IOBuffer(sizehint = floor(Int, sizeof(str)))
    buf_plain_str = IOBuffer(sizehint = floor(Int, sizeof(str)))

    str_i = 1

    # Loop for each match of a ANSI escape sequence.
    for m in eachmatch(_REGEX_ANSI, str)
        # Write everything from the previous match up to the last character
        # before the current match.
        if m.offset - 1 > 0
            str_f = prevind(str, m.offset)
            write(buf_plain_str, SubString(str, str_i, str_f))
        end

        write(buf_decorations, m.match)

        # `str_i` now have the index just after the current match.
        str_i = m.offset + ncodeunits(m.match)
    end

    # Write the rest of the string.
    write(buf_plain_str, SubString(str, str_i, lastindex(str)))

    return String(take!(buf_decorations)), String(take!(buf_plain_str))
end

"""
    parse_decoration(code::AbstractString)

Parse the decoration in the string `str` and returns an object of type
`Decoration` with it.
"""
function parse_decoration(code::AbstractString)
    state = :text
    buf = IOBuffer(sizehint = floor(Int, sizeof(code)))
    decoration = Decoration()

    for c in code
        state = _process_string_state(c, state)

        if state == :escape_state_begin
            take!(buf)
            write(buf, c)

        elseif state == :escape_state_end
            write(buf, c)
            str = String(take!(buf))
            decoration = update_decoration(decoration, str)

        elseif state == :text
            take!(buf)

        else
            write(buf, c)

        end
    end

    return decoration
end

"""
    remove_decorations(str::AbstractString)

Remove all the decorations added by ANSI escape sequences from the string `str`.
"""
function remove_decorations(str::AbstractString)

    # After some testing, it turns out that using the ANSI regex is way faster
    # than using the string state.
    return replace(str, _REGEX_ANSI => "")
end

"""
    replace_default_background(str::AbstractString, new_background::AbstractString) -> String

Replace the default background in `str` by the one in `new_background`. The latter must be
represented using a valid ANSI escape sequence that sets the background.

Internally, this function replaces the ANSI sequences that resets the decoration (`\e[0m`)
and sets the default background (`\e[49m`) with the new background while keeping all the
other supported decorations.
"""
function replace_default_background(str::AbstractString, new_background::AbstractString)
    # Buffer to store the new string.
    buf_new_str = IOBuffer(sizehint = floor(Int, sizeof(str)))

    str_i = 1

    # The first thing we need to do is to set the new background.
    write(buf_new_str, _CSI, new_background, "m")

    # This variable stores the current decoration when we split the string in each ANSI
    # escape sequence.
    current_decoration = Decoration()

    # Loop for each match of a ANSI escape sequence.
    for m in eachmatch(_REGEX_ANSI, str)
        # Write everything from the previous match up to the last character
        # before the current match.
        if m.offset - 1 > 0
            str_f = prevind(str, m.offset)
            write(buf_new_str, SubString(str, str_i, str_f))
        end

        d = parse_decoration(m.match)
        current_decoration = update_decoration(current_decoration, d)

        # We should only the decoration in case of a reset or if the user wants the default
        # background.
        if d.reset
            write(buf_new_str, _CSI, "0m", _CSI, new_background, "m")

        elseif d.background == "49"
            new_decoration = Decoration(
                foreground = d.foreground,
                background = new_background,
                bold       = d.bold,
                underline  = d.underline,
                reset      = d.reset,
            )

            write(buf_new_str, String(new_decoration))

        else
            write(buf_new_str, m.match)
        end

        # `str_i` now have the index just after the current match.
        str_i = m.offset + ncodeunits(m.match)
    end

    # Write the rest of the string.
    write(buf_new_str, SubString(str, str_i, lastindex(str)))

    # If the decoration at the end of string contains no background or the default one, we
    # should reset it also here.
    if isempty(current_decoration.background) || (current_decoration.background == "49")
        write(buf_new_str, _CSI, "49m")
    end

    return String(take!(buf_new_str))
end

"""
    update_decoration(decoration::Decoration, str::String) -> Decoration
    update_decoration(decoration::Decoration, new::Decoration) -> Decoration

Update the current `decoration` given the decorations in the string `str` or in `new`.
"""
function update_decoration(decoration::Decoration, code::String)
    state = :text
    buf = IOBuffer()

    for c in code
        state = _process_string_state(c, state)

        if state == :escape_state_begin
            take!(buf)

        elseif state == :escape_state_end
            str = String(take!(buf))
            decoration = _parse_ansi_code(decoration, str)

        elseif state == :text
            take!(buf)

        elseif state != :escape_state_opening
            write(buf, c)

        end
    end

    return decoration
end

function update_decoration(decoration::Decoration, new::Decoration)
    foreground = decoration.foreground
    background = decoration.background
    bold       = decoration.bold
    underline  = decoration.underline
    reset      = decoration.reset
    reversed   = decoration.reversed

    !isempty(new.foreground)   && (foreground = new.foreground)
    !isempty(new.background)   && (background = new.background)
    new.bold != unchanged      && (bold = new.bold)
    new.underline != unchanged && (underline = new.underline)
    new.reset                  && (reset = true)
    new.reversed  != unchanged && (reversed = new.reversed)

    return Decoration(
        foreground,
        background,
        bold,
        underline,
        reset,
        reversed
    )
end

################################################################################
#                                     API
################################################################################

String(d::Decoration) = convert(String, d)

# Convert  `Decoration` to string.
function convert(::Type{String}, d::Decoration)
    # Check if we have a reset.
    d === _DEFAULT_DECORATION && return ""
    d.reset && return "$(_CSI)0m"

    # TODO: Check if we can avoid adding so many `_CSI`.
    buf = IOBuffer()

    if !isempty(d.foreground)
        write(buf, _CSI)
        write(buf, d.foreground)
        write(buf, "m")
    end

    if !isempty(d.background)
        write(buf, _CSI)
        write(buf, d.background)
        write(buf, "m")
    end

    if d.bold != unchanged
        write(buf, _CSI)
        d.bold == active ? write(buf, "1") : write(buf, "22")
        write(buf, "m")
    end

    if d.underline != unchanged
        write(buf, _CSI)
        d.underline == active ? write(buf, "4") : write(buf, "24")
        write(buf, "m")
    end

    if d.reversed != unchanged
        write(buf, _CSI)
        d.reversed == active ? write(buf, "7") : write(buf, "27")
        write(buf, "m")
    end

    return String(take!(buf))
end
