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
equal to `size`, unless `size` is negative or larger than the printable size of `str`. In the
first case, the first string is empty, whereas, in the second case, the first string is
equal to `str`.

!!! note

    If the character at the split point needs more than one column to be printed (like some
    UTF-8 characters), it is replaced by spaces on both sides so that the printable width of
    each returned string is preserved.
"""
function split_string(str::AbstractString, size::Int)
    # Buffers with the string before and after the split point. Notice that we hint them
    # with a number of bytes, so we must use `sizeof` and not `length`, which counts the
    # characters and requires a full scan of the string. We also clamp the hints to the size
    # of the string because `size` is a printable width given by the caller and can be
    # arbitrarily large.
    string_size = sizeof(str)
    buf₀ = IOBuffer(; sizehint = clamp(size, 1, max(string_size, 1)))
    buf₁ = IOBuffer(; sizehint = clamp(string_size - size, 1, max(string_size, 1)))

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

                # Printable width still available in the string before the split point.
                available_width = size

                size -= cw

                # If `size` is negative, the character straddles the split point because it
                # occupies more than one column. Since a character cannot be broken, we
                # replace it by spaces on both sides so that the printable width of each
                # part is preserved.
                if size < 0
                    write(buf₀, " "^available_width)
                    write(buf₁, " "^(cw - available_width))
                    size = 0
                    continue
                end
            end

            write(buf₀, c)
            continue
        end

        # == String After the Split Point ==================================================

        if check_ansi_after_split
            state = _next_string_state(c, state)

            # All non-printable character just after splitting must go to `buf₀`.
            if state != :text
                write(buf₀, c)
                continue
            end

            # After the first text character, we should add everything to `buf₁`.
            check_ansi_after_split = false
        end

        write(buf₁, c)
    end

    return String(take!(buf₀)), String(take!(buf₁))
end
