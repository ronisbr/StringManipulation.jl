# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
# ==============================================================================
#
#   Functions to crop strings.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

export left_crop, fit_string_in_field, right_crop

"""
    left_crop(str::AbstractString, crop_width::Int)

Left crop from `str` a field with printable width `crop_width`.

This function return two strings:

- The ANSI escape sequence (non-printable string) in the cropped field; and
- The cropped string.
"""
function left_crop(str::AbstractString, crop_width::Int)
    buf_ansi = IOBuffer()
    buf_str = IOBuffer(sizehint = floor(Int, sizeof(str) - crop_width))
    state = :text

    for c in str
        if crop_width ≤ 0
            write(buf_str, c)
        else
            state = _process_string_state(c, state)

            if state == :text
                crop_width -= textwidth(c)

                # If `crop_width` is negative, then it means that we have a
                # character that occupies more than 1 character. In this case,
                # we fill the string with space.
                if crop_width < 0
                    write(buf_str, " "^(-crop_width))
                    crop_width = 0
                end
            else
                write(buf_ansi, c)
            end
        end
    end

    return String(take!(buf_ansi)), String(take!(buf_str))
end

"""
    fit_string_in_field(str::AbstractString, field_width::Int; kwargs...)

Crop the string `str` to fit it in a field with width `field_width`.

# Keywords

- `add_continuation_char::Bool`: If `true`, a continuation character is added to
    the cropped string end. Notice that the returned string always has a
    printable width of `field_size`. (**Default** = `true`)
- `add_space_in_continuation_char::Bool`: If `true`, a space is added before the
    continuation character if `crop_size` is `:right`, or after the continuation
    character if `crop_side` if `:left`. (**Default** = `false`)
- `continuation_char::Char`: The continuation character to add if the string is
    cropped. (**Default** = `…`)
- `crop_side::Symbol`: Select from which side the characters must be removed to
    fit the string into the field. It can be `:right` or `:left`.
    (**Default** = `:right`)
- `keep_ansi::Bool`: If `true`, the ANSI escape sequences found in the cropped
    part will be kept. (**Default** = `true`)
- `printable_string_width::Int`: Provide the printable string width to reduce
    the computational burden. If this parameters is lower than 0, the printable
    width is compute internally. (**Default** = -1)
"""
function fit_string_in_field(
    str::AbstractString,
    field_width::Int;
    add_continuation_char::Bool = true,
    add_space_in_continuation_char::Bool = false,
    continuation_char::Char = '…',
    crop_side::Symbol = :right,
    keep_ansi::Bool = true,
    printable_string_width::Int = -1
)

    str_width = printable_string_width < 0 ?
        printable_textwidth(str) :
        printable_string_width

    Δ = str_width - field_width

    # If the field is larger than the string, then just return it.
    if Δ ≤ 0
        return str
    end

    # If the user is asking for the continuation char, then we must crop the
    # string to account for the continuation char.
    cont_str = ""

    if add_continuation_char
        if crop_side == :right

            if add_space_in_continuation_char
                cont_str = " " * string(continuation_char)
            else
                cont_str = string(continuation_char)
            end

        else
            cont_str = string(continuation_char)

            if add_space_in_continuation_char
                cont_str *= " "
            end
        end

        wcont_str = textwidth(cont_str)

        Δ += wcont_str

        # If we are left with no space, then just return the continuation char.
        if Δ > str_width
            # We just need to check if the user wants to keep the ANSI escape
            # sequences.
            ansi = ""

            if keep_ansi
                ansi = get_decorations(str)
            end

            return string(continuation_char) * ansi
        end
    end

    # Crop from the right
    # ==========================================================================

    if crop_side == :right
        cropped_str, ansi = right_crop(
            str,
            Δ;
            keep_escape_seq = keep_ansi,
            printable_string_width = str_width
        )

        return cropped_str * cont_str * ansi

    # Crop from the left
    # ==========================================================================

    else
        ansi, cropped_str = left_crop(str, Δ)

        if keep_ansi
            return ansi * cont_str * cropped_str
        else
            return cont_str * cropped_str
        end
    end
end

"""
    right_crop(str::AbstractString, crop_width::Int; kwargs...)

Right crop from `str` a field with printable width `crop_width`.

This function return two strings:

- The cropped string; and
- The ANSI escape sequence (non-printable string) in the cropped field.

# Keyword

- `keep_escape_seq::Bool`: If `false`, then the ANSI escape sequence in the
    cropped field will not be computed. In this case, the second argument
    returned is always empty. (**Default** = `true`)
- `printable_string_width::Int`: Provide the printable string width to reduce
    the computational burden. If this parameters is lower than 0, the printable
    width is compute internally. (**Default** = -1)

!!! note
    If the keyword `keep_escape_seq` is set to `true`, then all the string must
    be processed, which can lead to a substantial increase in computational
    time.
"""
function right_crop(
    str::AbstractString,
    crop_width::Int;
    keep_escape_seq::Bool = true,
    printable_string_width::Int = -1
)
    buf_ansi = IOBuffer()
    buf_str = IOBuffer(sizehint = floor(Int, sizeof(str) - crop_width))

    str_width = printable_string_width < 0 ?
        printable_textwidth(str) :
        printable_string_width

    remaining_chars = str_width - crop_width
    state = :text

    for c in str
        state = _process_string_state(c, state)

        if remaining_chars ≤ 0
            !keep_escape_seq && break
            state != :text && write(buf_ansi, c)
        else
            if state == :text
                Δ = textwidth(c)
                remaining_chars -= Δ

                # If `remaining_chars` is negative, then it means that we have a
                # character that occupies more than 1 character. In this case,
                # we fill the string with space.
                if remaining_chars < 0
                    write(buf_str, " "^(-remaining_chars))
                    remaining_chars = 0
                else
                    write(buf_str, c)
                end
            else
                write(buf_str, c)
            end
        end
    end

    return String(take!(buf_str)), String(take!(buf_ansi))
end
