## Description #############################################################################
#
# Functions to split strings.
#
############################################################################################

export split_string

"""
    split_string(str::AbstractString, size::Int) -> String, String

Split the string `str` after a number of characters that have a specific printable `size`.
This function returns two strings: before and after the split point.

The algorithm ensures that the printable width of the first returned string will always be
equal `size`, unless `size` is negative or larger than the printable size of `str`. In the
first case, the first string is empty, whereas, in the second case, the first string is
equal to `str`.

!!! note

    If the character in the split point needs more than 1 character to be printed (like some
    UTF-8 characters), everything will be filled with spaces.
"""
function split_string(str::AbstractString, size::Int)
    # Buffer with the string before the split point.
    buf₀ = IOBuffer(sizehint = max(size, 1))

    # Buffer with the string after the split point.
    buf₁ = IOBuffer(sizehint = max(length(str) - size, 1))

    state = :text

    # If we are splitting just at the point where a non-printable character is, we need to
    # add all those characters to the string in `buf₀`. This variable is used to handle this
    # case.
    check_ansi_after_split = true

    for c in str
        # == String Before the Split Point =================================================
        if size > 0
            state = _next_string_state(c, state)

            if state == :text
                cw = textwidth(c)
                size -= cw

                # If `size` is negative, then it means that we have a character that
                # occupies more than 1 character. In this case, we fill the string with
                # space.
                if size < 0
                    print(buf₀, " "^(-size))
                    print(buf₁, " "^(cw + size))
                    size = 0
                    continue
                end
            end

            print(buf₀, c)
            continue
        end

        # == String After the Split Point ==================================================

        if check_ansi_after_split
            state = _next_string_state(c, state)

            # All non-printable character just after splitting must go to `buf₀`.
            if state != :text
                print(buf₀, c)
                continue
            end

            # After the first text character, we should add everything to `buf₁`.
            check_ansi_after_split = false
        end

        print(buf₁, c)
    end

    return String(take!(buf₀)), String(take!(buf₁))
end
