## Description #############################################################################
#
# Functions to crop strings.
#
############################################################################################

export crop_width_to_fit_string_in_field, left_crop, fit_string_in_field, right_crop

"""
    crop_width_to_fit_string_in_field(str::AbstractString, field_width::Int; kwargs...) -> Int

Get the number of printable characters to be cropped so that the string `str` can fit in the
field with size `field_width`.

# Keywords

- `add_continuation_char::Bool`: If `true`, a continuation character is added to the cropped
    string end. Notice that the returned string always has a printable width of
    `field_size`.
    (**Default** = `true`)
- `add_space_in_continuation_char::Bool`: If `true`, a space is added before the
    continuation character if `crop_size` is `:right`, or after the continuation character
    if `crop_side` if `:left`.
    (**Default** = `false`)
- `continuation_char::Char`: The continuation character to add if the string is cropped.
    (**Default** = `…`)
- `printable_string_width::Int`: Provide the printable string width to reduce the
    computational burden. If this parameters is lower than 0, the printable width is compute
    internally.
    (**Default** = -1)

# Extended Help

## Examples

```julia-repl
julia> crop_width_to_fit_string_in_field("This is a very long string for a very small field", 10)
40
```
"""
function crop_width_to_fit_string_in_field(
    str::AbstractString,
    field_width::Int;
    add_continuation_char::Bool = true,
    add_space_in_continuation_char::Bool = false,
    continuation_char::Char = '…',
    printable_string_width::Int = -1
)
    str_width = if printable_string_width < 0
        printable_textwidth(str)
    else
        printable_string_width
    end

    Δ = str_width - field_width

    # If the field is larger than the string, we do not need to crop.
    (Δ ≤ 0) && return 0

    # If the user is asking for the continuation char, we must crop the string to account
    # for the continuation char.
    cont_str = ""

    if add_continuation_char
        cont_str_width = textwidth(continuation_char)

        if add_space_in_continuation_char
            cont_str_width += 1
        end

        Δ += cont_str_width

        # If we are left with no space, then we must crop the entire string.
        (Δ > str_width) && return str_width
    end

    return Δ
end

"""
    fit_string_in_field(str::AbstractString, field_width::Int; kwargs...) -> String

Crop the string `str` to fit within a field of width `field_width`.

# Keywords

- `add_continuation_char::Bool`: If `true`, a continuation character is added to the cropped
    string end. Notice that the returned string always has a printable width of
    `field_size`.
    (**Default** = `true`)
- `add_space_in_continuation_char::Bool`: If `true`, a space is added before the
    continuation character if `crop_size` is `:right`, or after the continuation character
    if `crop_side` if `:left`.
    (**Default** = `false`)
- `continuation_char::Char`: The continuation character to add if the string is cropped.
    (**Default** = `…`)
- `crop_side::Symbol`: Select from which side the characters must be removed to fit the
    string into the field. It can be `:right` or `:left`.
    (**Default** = `:right`)
- `field_margin::Int`: Consider an additional margin in the field if it must be cropped.
    (**Default** = 0)
- `keep_escape_seq::Bool`: If `true`, the ANSI escape sequences found in the cropped part
    will be kept.
    (**Default** = `true`)
- `printable_string_width::Int`: Provide the printable string width to reduce the
    computational burden. If this parameters is lower than 0, the printable width is compute
    internally.
    (**Default** = -1)

# Extended Help

## Examples

```julia-repl
julia> fit_string_in_field("This is a very long string for a very small field", 10)
"This is a…"

julia> fit_string_in_field("This is a very long string for a very small field", 10; crop_side = :left)
"…all field"
```
"""
function fit_string_in_field(
    str::AbstractString,
    field_width::Int;
    add_continuation_char::Bool = true,
    add_space_in_continuation_char::Bool = false,
    continuation_char::Char = '…',
    crop_side::Symbol = :right,
    field_margin::Int = 0,
    keep_escape_seq::Bool = true,
    printable_string_width::Int = -1
)
    str_width = if printable_string_width < 0
        printable_textwidth(str)
    else
        printable_string_width
    end

    crop = crop_width_to_fit_string_in_field(
        str,
        field_width - field_margin;
        add_continuation_char,
        add_space_in_continuation_char,
        continuation_char,
        printable_string_width = str_width
    )

    (crop ≤ field_margin) && return str

    cont_str = add_continuation_char ? string(continuation_char) : ""

    # == Crop From the Right ===============================================================

    if crop_side == :right
        cropped_str, ansi = right_crop(
            str,
            crop;
            keep_escape_seq,
            printable_string_width = str_width
        )

        add_space_in_continuation_char && return cropped_str * " " * cont_str * ansi

        return cropped_str * cont_str * ansi

    # == Crop from The Left ================================================================

    else
        ansi, cropped_str = left_crop(str, crop)
        result = keep_escape_seq ? ansi : ""

        add_space_in_continuation_char && return result * cont_str * " " * cropped_str

        return result * cont_str * cropped_str
    end
end

"""
    left_crop(str::AbstractString, crop_width::Int) -> String, String

Return a string obtained by cropping the left characters of `str` so that its printable
width is reduced by `crop_width` display units.

# Returns

- `String`: ANSI escape sequence (non-printable string) in the cropped part.
- `String`: Cropped string.

# Extended Help

## Examples

```julia-repl
julia> left_crop("\\e[1mPlease, crop this string.", 8)
("\\e[1m", "crop this string.")
```
"""
function left_crop(str::AbstractString, crop_width::Int)
    buf_ansi = IOBuffer()
    buf_str  = IOBuffer(sizehint = floor(Int, sizeof(str) - crop_width))
    state    = :text

    for c in str
        if crop_width ≤ 0
            write(buf_str, c)
            continue
        end

        state = _next_string_state(c, state)

        # If we are not in a text section, just write the character to the ANSI buffer.
        if state != :text
            write(buf_ansi, c)
            continue
        end

        crop_width -= textwidth(c)

        # If `crop_width` is negative, it means that we have a character that occupies
        # more than 1 character. In this case, we fill the string with space.
        if crop_width < 0
            write(buf_str, " "^(-crop_width))
            crop_width = 0
        end
    end

    return String(take!(buf_ansi)), String(take!(buf_str))
end

"""
    right_crop(str::AbstractString, crop_width::Int; kwargs...) -> String, String

Return a string obtained by cropping the right characters of `str` given a field with a
printable width of `crop_width`.

# Returns

- `String`: Cropped string.
- `String`: ANSI escape sequence (non-printable string) in the cropped part.

# Keyword

- `keep_escape_seq::Bool`: If `false`, the ANSI escape sequence in the cropped field will
    not be computed. In this case, the second argument returned is always empty.
    (**Default** = `true`)
- `printable_string_width::Int`: Provide the printable string width to reduce the
    computational burden. If this parameters is lower than 0, the printable width is compute
    internally. (**Default** = -1)

!!! warning

    If the keyword `keep_escape_seq` is set to `true`, all the string must be processed,
    which can lead to a substantial increase in computational time.

# Examples

```julia-repl
julia> right_crop("\e[1mPlease, crop this \e[0mstring.", 8)
("\e[1mPlease, crop this", "\e[0m")

julia> right_crop("\e[1mPlease, crop this \e[0mstring.", 8; keep_escape_seq = false)
("\e[1mPlease, crop this", "")
```
"""
function right_crop(
    str::AbstractString,
    crop_width::Int;
    keep_escape_seq::Bool = true,
    printable_string_width::Int = -1
)
    buf_ansi = IOBuffer()
    buf_str  = IOBuffer(sizehint = floor(Int, max(0, sizeof(str) - crop_width)))
    state    = :text

    str_width = if printable_string_width < 0
        printable_textwidth(str)
    else
        printable_string_width
    end

    remaining_chars = str_width - crop_width

    for c in str
        state = _next_string_state(c, state)

        if remaining_chars <= 0
            !keep_escape_seq && break
            state != :text && write(buf_ansi, c)
            continue
        end

        # If we are not in a text section, just write the character to the ANSI buffer.
        if state != :text
            write(buf_str, c)
            continue
        end

        Δ = textwidth(c)
        remaining_chars -= Δ

        # If `remaining_chars` is negative, it means that we have a character that
        # occupies more than 1 character. In this case, we fill the string with
        # space.
        if remaining_chars < 0
            write(buf_str, " "^(-remaining_chars))
            remaining_chars = 0
            continue
        end

        write(buf_str, c)
    end

    return String(take!(buf_str)), String(take!(buf_ansi))
end
