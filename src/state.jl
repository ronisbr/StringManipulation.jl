# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
# ==============================================================================
#
#   Internal function to keep track of string state when iterating through the
#   characters.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

"""
    _process_string_state(c::Char, state::Symbol = :text)

Return the current state of the string given the new character `c` and the
previous state `state`.

The following states are possible:

- `:text`: The character is part of the printable text.
- `:escape_state_begin`: Beginning of an ANSI escape sequence.
- `:escape_state_opening`: Matches the `[`.
- `:escape_state_1`: First state of an ANSI escape sequence.
- `:escape_state_2`: Second state of an ANSI escape sequence.
- `:escape_state_3`: Third state of an ANSI escape sequence.
- `:escape_state_end`: End of an ANSI escape sequence.
"""
function _process_string_state(c::Char, state::Symbol = :text)
    if state == :text
        # Here, we need to check if an escape sequence is found.
        if c == '\x1b'
            state = :escape_state_begin
        end

    elseif state == :escape_state_begin
        if (c == '[')
            state = :escape_state_opening

        elseif ('@' ≤ c ≤ 'Z') || ('\\' ≤ c ≤ '_')
            state = :escape_state_1
        else
            state = :text
        end

    elseif state == :escape_state_opening
        state = :escape_state_1
        return _process_string_state(c, state)

    elseif state == :escape_state_1
        if !('0' ≤ c ≤ '?')
            state = :escape_state_2
            return _process_string_state(c, state)
        end

    elseif state == :escape_state_2
        if !(' ' ≤ c ≤ '/')
            state = :escape_state_3
            return _process_string_state(c, state)
        end

    elseif state == :escape_state_3
        if ('@' ≤ c ≤ '~')
            state = :escape_state_end
        else
            state = :text
        end
    elseif state == :escape_state_end
        state = :text

        # We need to recall this function because the next character can be the
        # beginning of a new ANSI escape sequence.
        return _process_string_state(c, state)
    end

    return state
end
