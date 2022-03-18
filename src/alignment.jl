# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
# ==============================================================================
#
#   Functions to align strings.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

export align_string, align_string_per_line, get_padding_for_string_alignment

"""
    align_string(str::AbstractString, field_width::Int, alignment::Symbol; fill::Bool = false )

Align the string `str` in the field with width `field_width` using `alignment`.

`alignment` can be:

- `:l`: Align the string to the left;
- `:c`: Align the string in the center;
- `:r`: Align the string in the right.

!!! note
    If the printable width of `str` is higher than `field_width`, then nothing
    will be changed.

!!! note
    This function treats `\n` as a normal characters. If one wants to align
    every line, then use the function [`align_string_per_line`](@ref).

# Keyword

- `fill::Bool`: If `true`, the string will be filled with spaces to the right so
    that the resulting string has printable width `field_size` if the initial
    string printable width is lower than it.
- `printable_string_width::Int`: Provide the printable string width to reduce
    the computational burden. If this parameters is lower than 0, the printable
    width is compute internally. (**Default** = -1)
"""
function align_string(
    str::AbstractString,
    field_width::Int,
    alignment::Symbol;
    fill::Bool = false,
    printable_string_width::Int = -1
)
    padding = get_padding_for_string_alignment(
        str,
        field_width,
        alignment;
        fill,
        printable_string_width
    )

    if isnothing(padding)
        return str
    else
        lpad, rpad = padding
        return " "^lpad * str * " "^rpad
    end
end

"""
    align_string_per_line(str::AbstractString, field_width::Int, alignment::Symbol; fill::Bool = false)

Align each line of the string `str` in the field with width `field_width` using
`alignment`.

`alignment` can be:

- `:l`: Align the string to the left;
- `:c`: Align the string in the center;
- `:r`: Align the string in the right.

!!! note
    If the printable width of `str` is higher than `field_width`, then nothing
    will be changed.

# Keyword

- `fill::Bool`: If `true`, the each line will be filled with spaces to the right
    so that the resulting string has printable width `field_size` if the initial
    string printable width is lower than it.
"""
function align_string_per_line(
    str::AbstractString,
    field_width::Int,
    alignment::Symbol;
    fill::Bool = false
)
    if field_width ≤ 0
        return str
    end

    # Split the lines.
    lines = split(str, '\n')
    num_lines = length(lines)

    # Align each one of them.
    buf = IOBuffer(sizehint = floor(Int, sizeof(str) + num_lines * div(field_width, 2)))

    @inbounds for i in 1:num_lines
        write(buf, align_string(lines[i], field_width, alignment; fill))
        i != num_lines && write(buf, '\n')
    end

    return String(take!(buf))
end

"""
    get_padding_for_string_alignment(str::AbstractString, field_width::Int, alignment::Symbol; kwargs...)

Return the left and right padding required to align the string `str` in a field
with width `field_width` using the `alignment`.

`alignment` can be:

- `:l`: Align the string to the left;
- `:c`: Align the string in the center;
- `:r`: Align the string in the right.

!!! note
    If the printable width of `str` is higher than `field_width`, then nothing
    is returned.

!!! note
    This function treats `\n` as a normal characters.

# Keyword

- `fill::Bool`: If `true`, the string will be filled with spaces to the right so
    that the resulting string has printable width `field_size` if the initial
    string printable width is lower than it.
- `printable_string_width::Int`: Provide the printable string width to reduce
    the computational burden. If this parameters is lower than 0, the printable
    width is compute internally. (**Default** = -1)
"""
function get_padding_for_string_alignment(
    str::AbstractString,
    field_width::Int,
    alignment::Symbol;
    fill::Bool = false,
    printable_string_width::Int = -1
)

    str_width = printable_string_width < 0 ?
        printable_textwidth(str) :
        printable_string_width

    if field_width ≤ str_width
        return nothing
    end

    # Compute the padding given the alignment type.
    if alignment == :l
        # In this case, we only need to modify the string if `fill` is `true`.
        if fill
            rpad = field_width - str_width
            return 0, rpad
        end

    elseif alignment == :c
        lpad = div(field_width - str_width, 2)
        rpad = fill ? (field_width - str_width - lpad) : 0
        return lpad, rpad

    elseif alignment == :r
        lpad = field_width - str_width
        return lpad, 0
    end

    return nothing
end

