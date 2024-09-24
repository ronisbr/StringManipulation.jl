## Description #############################################################################
#
# Internal function to keep track of string state when iterating through the characters.
#
############################################################################################

"""
    _process_string_state(c::Char, state::Symbol = :text)

Return the current state of the string given the new character `c` and the previous state
`state`.

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
function _process_string_state(c::Char, state::Symbol = :text)
    if state == :text
        # Here, we need to check if an escape sequence is found.
        c == '\x1b' && return :escape_state_begin
    end

    if state == :escape_state_begin
        (c == '[') && return :escape_state_opening
        (c == ']') && return :escape_hyperlink_opening
        (('@' ≤ c ≤ 'Z') || ('\\' ≤ c ≤ '_')) && return :escape_state_1
    end

    state == :escape_state_opening && return _process_string_state(c, :escape_state_1)

    if state == :escape_state_1
        ('0' ≤ c ≤ '?') && return :escape_state_1
        return _process_string_state(c, :escape_state_2)
    end

    if state == :escape_state_2
        (' ' ≤ c ≤ '/') && return :escape_state_2
        return _process_string_state(c, :escape_state_3)
    end

    if state == :escape_state_3
        ('@' ≤ c ≤ '~') && return :escape_state_end
    end

    if state == :escape_hyperlink_opening
        (c == '8') && return :escape_hyperlink_1
    end

    if state == :escape_hyperlink_1
        (c == ';') && return :escape_hyperlink_2
    end

    if state == :escape_hyperlink_2
        (c == ';') && return :escape_hyperlink_3
    end

    if state ∈ (:escape_hyperlink_3, :escape_hyperlink_url)
        (c == '\x1b') && return :escape_hyperlink_end
        return :escape_hyperlink_url
    end

    if state == :escape_hyperlink_end
        (c == '\\') && return :escape_state_end
    end

    if state == :escape_state_end
        # We need to recall this function because the next character can be the beginning of
        # a new ANSI escape sequence.
        return _process_string_state(c, :text)
    end

    # If we reached this point, the character is part of the printable text or it is part of
    # an unsupported escape sequence. In the latter, we should assume it is printable.
    return :text
end
