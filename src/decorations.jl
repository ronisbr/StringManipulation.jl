# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
# ==============================================================================
#
#   Functions related to decorations in strings.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

export remove_decorations

"""
    remove_decorations(str::AbstractString)

Remove all the decorations added by ANSI escape sequences from the string `str`.
"""
function remove_decorations(str::AbstractString)

    # After some testing, it turns out that using the ANSI regex is way faster
    # than using the string state.
    return replace(str, _REGEX_ANSI => "")
end
