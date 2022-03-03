# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
# ==============================================================================
#
#   Functions to align strings.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

export align_string, align_string_per_line

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
    that the resulting string has printable witdh `field_size` if the initial
    string printable width is lower than it.
"""
function align_string(
    str::AbstractString,
    field_width::Int,
    alignment::Symbol;
    fill::Bool = false
)
    str_width = printable_textwidth(str)

    if field_width < str_width
        return str
    end

    # Compute the padding given the alignment type.
    if alignment == :l
        # In this case, we only need to modify the string if `fill` is `true`.
        if fill
            Δ = field_width - str_width
            return str * " "^Δ
        end
    elseif alignment == :c
        Δ = div(field_width - str_width, 2)
        str = " "^Δ * str

        if fill
            Δ = field_width - str_width - Δ
            str = str * " "^Δ
        end
    elseif alignment == :r
        Δ = field_width - str_width
        str = " "^Δ * str
    end

    return str
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
    so that the resulting string has printable witdh `field_size` if the initial
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
