# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
# ==============================================================================
#
#   Functions related to decorations in strings.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

export get_decorations, remove_decorations

"""
    get_decorations(str::AbstractString)

Return a string with the decorations in `str`.
"""
function get_decorations(str::AbstractString)

    buf = IOBuffer(sizehint = length(str))

    for m in eachmatch(_REGEX_ANSI, str)
        write(buf, m.match)
    end

    return String(take!(buf))
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

    write(buf, _CSI)
    d.bold ? write(buf, "1") : write(buf, "22")
    write(buf, "m")

    write(buf, _CSI)
    d.underline ? write(buf, "4") : write(buf, "24")
    write(buf, "m")

    write(buf, _CSI)
    d.reversed ? write(buf, "7") : write(buf, "27")
    write(buf, "m")

    return String(take!(buf))
end
