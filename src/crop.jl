# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
# ==============================================================================
#
#   Functions to crop strings.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

export left_crop, right_crop

"""
    left_crop(str::AbstractString, crop_width::Int)

Left crop from `str` a field with printable width `crop_width`.

This function return two strings:

- The ANSI escape sequence (non-printable string) in the cropped field; and
- The cropped string.
"""
function left_crop(str::AbstractString, crop_width::Int)
    buf_ansi = IOBuffer()
    buf_str = IOBuffer()
    state = :text

    for c in str
        if crop_width ≤ 0
            print(buf_str, c)
        else
            state = _process_string_state(c, state)

            if state == :text
                crop_width -= textwidth(c)

                # If `crop_width` is negative, then it means that we have a
                # character that occupies more than 1 character. In this case,
                # we fill the string with space.
                if crop_width < 0
                    print(buf_str, " "^(-crop_width))
                    crop_width = 0
                end
            else
                print(buf_ansi, c)
            end
        end
    end

    return String(take!(buf_ansi)), String(take!(buf_str))
end

"""
    left_crop(str::AbstractString, crop_width::Int)

Right crop from `str` a field with printable width `crop_width`.

This function return two strings:

- The cropped string; and
- The ANSI escape sequence (non-printable string) in the cropped field.

# Keyword

- `keep_escape_seq::Bool`: If `false`, then the ANSI escape sequence in the
    cropped field will not be computed. In this case, the second argument
    returned is always empty. (**Default** = `true`)

!!! note
    If the keyword `keep_escape_seq` is set to `true`, then all the string must
    be processed, which can lead to a substantial increase in computational
    time.
"""
function right_crop(
    str::AbstractString,
    crop_width::Int;
    keep_escape_seq::Bool = true
)
    buf_str = IOBuffer()
    buf_ansi = IOBuffer()

    str_width = printable_textwidth(str)
    remaining_chars = str_width - crop_width
    state = :text

    for c in str
        state = _process_string_state(c, state)

        if remaining_chars ≤ 0
            !keep_escape_seq && break
            state != :text && print(buf_ansi, c)
        else
            if state == :text
                Δ = textwidth(c)
                remaining_chars -= Δ

                # If `remaining_chars` is negative, then it means that we have a
                # character that occupies more than 1 character. In this case,
                # we fill the string with space.
                if remaining_chars < 0
                    print(buf_str, " "^(-remaining_chars))
                    remaining_chars = 0
                else
                    print(buf_str, c)
                end
            else
                print(buf_str, c)
            end
        end
    end

    return String(take!(buf_str)), String(take!(buf_ansi))
end
