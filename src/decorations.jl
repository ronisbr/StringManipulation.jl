## Description #############################################################################
#
# Functions related to decorations in strings.
#
############################################################################################

export drop_inactive_properties, get_decorations, get_and_remove_decorations
export parse_decoration, remove_decorations, replace_default_background, update_decoration

"""
    drop_inactive_properties(decoration::Decoration) -> Decoration

Drop the inactive properties of `decoration` by changing them to inactive. This operation
can be useful to avoid unnecessary escape sequences if the decorations are reset.
"""
function drop_inactive_properties(decoration::Decoration)
    # Unpack fields.
    foreground = decoration.foreground
    background = decoration.background
    bold       = decoration.bold
    italic     = decoration.italic
    underline  = decoration.underline
    reversed   = decoration.reversed

    # If a field is inactive or if it is a reset to a default value, drop it by returning to
    # default.
    if foreground == "39"
        foreground =  ""
    end

    if background == "49"
        background = ""
    end

    if bold == inactive
        bold = unchanged
    end

    if italic == inactive
        italic = unchanged
    end

    if underline == inactive
        underline = unchanged
    end

    if reversed == inactive
        reversed = unchanged
    end

    return Decoration(
        foreground,
        background,
        bold,
        italic,
        reversed,
        underline,
        false,
        decoration.hyperlink_url,
        decoration.hyperlink_url_changed
    )
end

"""
    get_decorations(str::AbstractString) -> String

Return a string with the decorations in `str`.

# Extended Help

## Examples

```julia
julia> get_decorations("This is a \\e[1mbold string\\e[45mwith a different background\\e[0m.")
"\\e[1m\\e[45m\\e[0m"
```
"""
function get_decorations(str::AbstractString)
    buf = IOBuffer(sizehint = sizeof(str))

    for m in eachmatch(_REGEX_ANSI_SEQUENCES, str)
        write(buf, m.match)
    end

    return String(take!(buf))
end

"""
    get_and_remove_decorations(str::AbstractString) -> String, String

Get and remove the decorations in `str`. The first returned string contains the decorations
whereas the second contains the plain text.
"""
function get_and_remove_decorations(str::AbstractString)
    buf_decorations = IOBuffer(sizehint = floor(Int, sizeof(str)))
    buf_plain_str   = IOBuffer(sizehint = floor(Int, sizeof(str)))

    str_i = 1

    # Loop for each match of a ANSI escape sequence.
    for m in eachmatch(_REGEX_ANSI_SEQUENCES, str)
        # Write everything from the previous match up to the last character before the
        # current match.
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
    parse_decoration(code::AbstractString) -> Decoration

Parse the decoration in the string `str` and returns an object of type `Decoration` with it.
"""
function parse_decoration(code::AbstractString)
    state = :text
    buf = IOBuffer(sizehint = floor(Int, sizeof(code)))
    decoration = Decoration()

    for c in code
        state = _next_string_state(c, state)

        if state == :escape_state_begin
            buf.ptr  = 1
            buf.size = 0
            write(buf, c)

        elseif state == :escape_state_end
            write(buf, c)
            str = String(take!(buf))
            decoration = update_decoration(decoration, str)

        elseif state == :text
            buf.ptr  = 1
            buf.size = 0

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
    return replace(str, _REGEX_ANSI_SEQUENCES => "")
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

    # Number of code units in the string.
    str_code_units = ncodeunits(str)

    # The first thing we need to do is to set the new background.
    write(buf_new_str, _CSI, new_background, "m")

    # This variable stores the current decoration when we split the string in each ANSI
    # escape sequence.
    current_decoration = Decoration()

    # Loop for each match of a ANSI escape sequence.
    for m in eachmatch(_REGEX_ANSI_SEQUENCES, str)
        # Write everything from the previous match up to the last character
        # before the current match.
        if m.offset - 1 > 0
            str_f = prevind(str, m.offset)
            write(buf_new_str, SubString(str, str_i, str_f))
        end

        # `str_i` now have the index just after the current match.
        str_i = m.offset + ncodeunits(m.match)

        d = parse_decoration(m.match)
        current_decoration = update_decoration(current_decoration, d)

        # We should only modify the decoration in case of a reset or if the user wants the
        # default background.
        if d.reset
            # If we are at the end of the string, we should not write the reset sequence and
            # treat it after the loop, where we will restore background to the default one.
            # Otherwise, we will have duplicated escape sequences.
            if str_i <= str_code_units
                write(buf_new_str, _CSI, "0m", _CSI, new_background, "m")
                current_decoration = Decoration()
            end

        elseif d.background == "49"
            # If we are at the end of the string, we should not write the background
            # sequence and treat it after the loop, where we will restore background to the
            # default one. Otherwise, we will have duplicated escape sequences.
            if str_i <= str_code_units
                new_decoration = Decoration(
                    foreground = d.foreground,
                    background = new_background,
                    bold       = d.bold,
                    italic     = d.italic,
                    underline  = d.underline,
                    reset      = d.reset,
                )

                write(buf_new_str, String(new_decoration))
            end

        else
            write(buf_new_str, m.match)
        end
    end

    # Write the rest of the string.
    write(buf_new_str, SubString(str, str_i, lastindex(str)))

    # If the last decoration is a reset, we should also reset everything here.
    if current_decoration.reset
        write(buf_new_str, _CSI, "0m")

    # If the last decoration is a background change, or if the background is not modified,
    # we should reset to the terminal default background.
    elseif isempty(current_decoration.background) || (current_decoration.background == "49")
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
    buf = IOBuffer(sizehint = floor(Int, sizeof(code)))
    hyperlink = false

    for c in code
        state = _next_string_state(c, state)

        if state == :escape_state_begin
            buf.ptr  = 1
            buf.size = 0

        elseif state == :escape_hyperlink_3
            # If we reached this state, the next one is the URL. Hence, we clean the buffer
            # and inform that we are processing a hyperlink.
            buf.ptr  = 1
            buf.size = 0
            hyperlink = true

        elseif state == :escape_hyperlink_url
            write(buf, c)

        elseif state == :escape_hyperlink_end
            # The buffer will contain only the new URL.
            hl_url = String(take!(buf))

            decoration = Decoration(
                decoration.foreground,
                decoration.background,
                decoration.bold,
                decoration.italic,
                decoration.reversed,
                decoration.underline,
                decoration.reset,
                hl_url,
                true
            )

        elseif state == :escape_state_end
            if hyperlink
                hyperlink = false
                continue
            end

            str = String(take!(buf))
            decoration = _parse_ansi_decoration_code(decoration, str)

        elseif state == :text
            buf.ptr  = 1
            buf.size = 0

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
    italic     = decoration.italic
    underline  = decoration.underline
    reset      = decoration.reset
    reversed   = decoration.reversed
    hl_url     = decoration.hyperlink_url

    hl_url_changed = new.hyperlink_url_changed

    !isempty(new.foreground)   && (foreground = new.foreground)
    !isempty(new.background)   && (background = new.background)
    new.bold != unchanged      && (bold = new.bold)
    new.italic != unchanged    && (italic = new.italic)
    new.underline != unchanged && (underline = new.underline)
    new.reset                  && (reset = true)
    new.reversed  != unchanged && (reversed = new.reversed)
    hl_url_changed             && (hl_url = new.hyperlink_url)

    return Decoration(
        foreground,
        background,
        bold,
        italic,
        reversed,
        underline,
        reset,
        hl_url,
        hl_url_changed
    )
end

############################################################################################
#                                        Julia API                                         #
############################################################################################

String(d::Decoration) = convert(String, d)

# Convert  `Decoration` to string.
function convert(::Type{String}, d::Decoration)
    # Check if we must change the hyperlink.
    str_hyperlink = if d.hyperlink_url_changed
        "\x1B]8;;$(d.hyperlink_url)\x1B\\"
    else
        ""
    end

    # Check if we have a reset. Notice that a reset **does not** clean the hyperlink.
    d === _DEFAULT_DECORATION && return ""
    d.reset && return "$(str_hyperlink)$(_CSI)0m"

    # TODO: Check if we can avoid adding so many `_CSI`.
    str_foreground = !isempty(d.foreground)   ? "$(_CSI)$(d.foreground)m" : ""
    str_background = !isempty(d.background)   ? "$(_CSI)$(d.background)m" : ""
    str_bold       = d.bold      != unchanged ? "$(_CSI)$(d.bold == active ? "1" : "22")m" : ""
    str_italic     = d.italic    != unchanged ? "$(_CSI)$(d.italic == active ? "3" : "23")m" : ""
    str_underline  = d.underline != unchanged ? "$(_CSI)$(d.underline == active ? "4" : "24")m" : ""
    str_reversed   = d.reversed  != unchanged ? "$(_CSI)$(d.reversed == active ? "7" : "27")m" : ""

    return string(
        str_hyperlink,
        str_foreground,
        str_background,
        str_bold,
        str_italic,
        str_underline,
        str_reversed
    )
end
