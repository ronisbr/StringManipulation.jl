# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
# ==============================================================================
#
#   Functions related to decorations in strings.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

export drop_inactive_properties, get_decorations, get_and_remove_decorations
export parse_decoration, remove_decorations, update_decoration

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
    update_decoration(decoration::Decoration, str::String)

Update the current `decoration` given the decorations in the string `str`.
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
