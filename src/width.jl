## Description #############################################################################
#
# Functions to compute the printable width of the string.
#
############################################################################################

export printable_textwidth, printable_textwidth_per_line

"""
    printable_textwidth(str::AbstractString) -> Int

Return the text width of `str` considering only the printable characters, *i.e.* removing
all ANSI escape sequences related to decorations.

!!! note

    Characters like `\\n` and `\\t` are treated as normal characters.
"""
function printable_textwidth(str::AbstractString)
    # Fast path: a string composed only of printable ASCII characters cannot contain an
    # escape sequence, and each of its characters occupies exactly one column.
    _is_printable_ascii(str) && return ncodeunits(str)

    width = 0
    state = :text

    # We must not materialize the undecorated string only to measure it. Hence, we walk the
    # string once and accumulate the width of the characters outside an escape sequence.
    for c in str
        state = _next_string_state(c, state)
        (state == :text) && (width += textwidth(c))
    end

    return width
end

"""
    printable_textwidth_per_line(str::AbstractString) -> Vector{Int}

Return a vector with the printable textwidth of each line in `str`. The lines are split
considering the character `\n`.
"""
function printable_textwidth_per_line(str::AbstractString)
    # `eachsplit` has no length, meaning a comprehension would grow the vector. Since the
    # number of lines is known from the number of newlines, we can allocate it once.
    widths = Vector{Int}(undef, count('\n', str) + 1)

    for (i, line) in enumerate(eachsplit(str, '\n'))
        widths[i] = printable_textwidth(line)
    end

    return widths
end

############################################################################################
#                                    Private Functions                                     #
############################################################################################

"""
    _is_printable_ascii(str::AbstractString) -> Bool

Return `true` if `str` contains only printable ASCII characters.

Notice that we check the code units instead of the characters because any byte of a
multi-byte UTF-8 sequence is greater than `0x7E`, meaning that such a string is correctly
rejected without being decoded.
"""
function _is_printable_ascii(str::AbstractString)
    return all(b -> 0x20 ≤ b ≤ 0x7E, codeunits(str))
end

"""
    _has_escape_byte(str::AbstractString) -> Bool

Return `true` if `str` contains an escape byte (`0x1b`), meaning that it can contain an ANSI
escape sequence.

Notice that `0x1b` cannot be part of a multi-byte UTF-8 sequence, so scanning the code units
never yields a false positive.
"""
_has_escape_byte(str::AbstractString) = 0x1b ∈ codeunits(str)
