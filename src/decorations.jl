# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
# ==============================================================================
#
#   Functions related to decorations in strings.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

export get_decorations, parse_decoration, remove_decorations, update_decoration

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
    decoration = Decoration()

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
