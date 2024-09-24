## Description #############################################################################
#
# Internal function to keep track of string state when iterating through the characters.
#
############################################################################################

"""
    _next_string_state(c::Char, state::Symbol = :text) -> Symbol

Return the next string state given the character `c` and the current string `state`.

The following states are possible:

- `:text`: The character is part of the printable text.
- `:escape_state_begin`: Beginning of an ANSI escape sequence (`\\x1b`).
- `:escape_state_opening`: Matches the `[`.
- `:escape_state_1`: First state of an ANSI escape sequence.
- `:escape_state_2`: Second state of an ANSI escape sequence.
- `:escape_state_3`: Third state of an ANSI escape sequence.
- `:escape_hyperlink_opening`: Beginning of an ANSI hyperlink escape sequence (`]`).
- `:escape_hyperlink_1`: First state of an ANSI hyperlink escape sequence (`8`).
- `:escape_hyperlink_2`: Second state of an ANSI hyperlink escape sequence (`;`).
- `:escape_hyperlink_3`: Third state of an ANSI hyperlink escape sequence (`;`).
- `:escape_hyperlink_url`: URL in an ANSI hyperlink escape sequence.
- `:escape_hyperlink_close`: Closing of an ANSI hyperlink escape sequence (`\\x1b`).
- `:escape_state_end`: End of an ANSI escape sequence.
"""
function _next_string_state(c::Char, state::Symbol = :text)
    if state == :text
        # Here, we need to check if an escape sequence is found.
        c == '\x1B' && return :escape_state_begin

    elseif state == :escape_state_begin
        (c == '[') && return :escape_state_opening
        (c == ']') && return :escape_hyperlink_opening
        (('@' ≤ c ≤ 'Z') || ('\\' ≤ c ≤ '_')) && return :escape_state_1

    elseif state == :escape_state_opening
        return _next_string_state(c, :escape_state_1)

    elseif state == :escape_state_1
        ('0' ≤ c ≤ '?') && return :escape_state_1
        return _next_string_state(c, :escape_state_2)

    elseif state == :escape_state_2
        (' ' ≤ c ≤ '/') && return :escape_state_2
        return _next_string_state(c, :escape_state_3)

    elseif state == :escape_state_3
        ('@' ≤ c ≤ '~') && return :escape_state_end

    elseif state == :escape_hyperlink_opening
        (c == '8') && return :escape_hyperlink_1

    elseif state == :escape_hyperlink_1
        (c == ';') && return :escape_hyperlink_2

    elseif state == :escape_hyperlink_2
        (c == ';') && return :escape_hyperlink_3

    elseif state ∈ (:escape_hyperlink_3, :escape_hyperlink_url)
        (c == '\x1B') && return :escape_hyperlink_end
        return :escape_hyperlink_url

    elseif state == :escape_hyperlink_end
        (c == '\\') && return :escape_state_end

    elseif state == :escape_state_end
        # We need to recall this function because the next character can be the beginning of
        # a new ANSI escape sequence.
        return _next_string_state(c, :text)
    end

    return :text
end
