# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
# ==============================================================================
#
#   Functions to compute the printable width of the string.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

export printable_textwidth, printable_textwidth_per_line

"""
    printable_textwidth(str::AbstractString)

Return the text width of `str` considering only the printable characters, *i.e.*
removing all ANSI escape sequences related to decorations.

!!! note
    Characters like `\\n` and `\\t` are treated as normal characters.
"""
function printable_textwidth(str::AbstractString)
    width = 0

    state = :text

    for c in str
        state = _process_string_state(c, state)
        if state == :text
            width += textwidth(c)
        end
    end

    return width
end

"""
    printable_textwidth_per_line(str::AbstractString)

Return a vector with the printable textwidth of each line in `str`. The lines
are split considering the character `\n`.
"""
function printable_textwidth_per_line(str::AbstractString)
    lines = split(str, '\n')
    num_lines = length(lines)
    lines_width = zeros(Int, num_lines)

    @inbounds for k in 1:num_lines
        lines_width[k] = printable_textwidth(lines[k])
    end

    return lines_width
end
