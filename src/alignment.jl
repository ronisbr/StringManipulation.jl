## Description #############################################################################
#
# Functions to align strings.
#
############################################################################################

export align_string, align_string_per_line, padding_for_string_alignment

"""
    align_string(str::AbstractString, field_width::Int, alignment::Symbol; kwargs...) -> String

Align the string `str` in the field with width `field_width` using `alignment`, which can
be:

- `:l`: Align the string to the left;
- `:c`: Align the string in the center;
- `:r`: Align the string in the right.

!!! note

    If the printable width of `str` is higher than `field_width`, nothing will be changed.

!!! note

    This function treats `\\n` as a normal characters. If one wants to align every line, use
    the function [`align_string_per_line`](@ref).

# Keyword

- `fill::Bool`: If `true`, the string will be filled with spaces to the right so that the
    resulting string has printable width `field_size` if the initial string printable width
    is lower than it.
    (**Default** = `false`)
- `printable_string_width::Int`: Provide the printable string width to reduce the
    computational burden. If this parameters is lower than 0, the printable width is compute
    internally.
    (**Default** = -1)

# Extended Help

## Examples

```julia-repl
julia> align_string("My String", 92, :c) |> println
                                         My String

julia> align_string("My String", 92, :l) |> println
My String

julia> align_string("My String", 92, :r) |> println
                                                                                   My String
```
"""
function align_string(
    str::AbstractString,
    field_width::Int,
    alignment::Symbol;
    fill::Bool = false,
    printable_string_width::Int = -1
)
    padding = padding_for_string_alignment(
        str,
        field_width,
        alignment;
        fill,
        printable_string_width
    )

    isnothing(padding) && return str

    lpad, rpad = padding
    return " "^lpad * str * " "^rpad
end

"""
    align_string_per_line(str::AbstractString, field_width::Int, alignment::Symbol; kwargs...) -> String

Align each line of the string `str` in the field with width `field_width` using `alignment`,
which can be:

- `:l`: Align the string to the left;
- `:c`: Align the string in the center;
- `:r`: Align the string in the right.

!!! note

    If the printable width of `str` is higher than `field_width`, nothing will be changed.

# Keyword

- `fill::Bool`: If `true`, the string will be filled with spaces to the right so that the
    resulting string has printable width `field_size` if the initial string printable width
    is lower than it.
    (**Default** = `false`)

# Extended Help

## Examples

```julia-repl
julia> align_string_per_line(\"\"\"
       This is a string
       with multiple
       lines.\"\"\", 92, :c) |> println
                                      This is a string
                                       with multiple
                                           lines.

julia> align_string_per_line(\"\"\"
       This is a string
       with multiple
       lines.\"\"\", 92, :l) |> println
This is a string
with multiple
lines.

julia> align_string_per_line(\"\"\"
       This is a string
       with multiple
       lines.\"\"\", 92, :r) |> println
                                                                            This is a string
                                                                               with multiple
                                                                                      lines.
```
"""
function align_string_per_line(
    str::AbstractString,
    field_width::Int,
    alignment::Symbol;
    fill::Bool = false
)
    (field_width ≤ 0) && return str

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
    padding_for_string_alignment(str::AbstractString, field_width::Int, alignment::Symbol; kwargs...) -> Union{Nothing, NTuple{2, Int}}

Return the left and right padding required to align the string `str` in a field with width
`field_width` using the `alignment`, which can be:

- `:l`: Align the string to the left;
- `:c`: Align the string in the center;
- `:r`: Align the string in the right.

This function can return `nothing` in the following conditions:

1. The string does not need to be modified;
2. The alignment symbol is unknown; or
3. The printable width of `str` is longer than `field_width`.

!!! note

    This function treats `\\n` as a normal characters.

# Keyword

- `fill::Bool`: If `true`, the string will be filled with spaces to the right so that the
    resulting string has printable width `field_size` if the initial string printable width
    is lower than it.
    (**Default** = `false`)
- `printable_string_width::Int`: Provide the printable string width to reduce the
    computational burden. If this parameters is lower than 0, the printable width is compute
    internally.
    (**Default** = -1)

# Extended Help

## Examples

```julia-repl
julia> padding_for_string_alignment("My string", 92, :c)
(41, 0)

julia> padding_for_string_alignment("My string", 92, :l)

julia> padding_for_string_alignment("My string", 92, :r)
(83, 0)
```
"""
function padding_for_string_alignment(
    str::AbstractString,
    field_width::Int,
    alignment::Symbol;
    fill::Bool = false,
    printable_string_width::Int = -1
)
    str_width = if printable_string_width < 0
        printable_textwidth(str)
    else
        printable_string_width
    end

    (field_width ≤ str_width) && return nothing

    # Compute the padding given the alignment type.
    if (alignment == :l) && fill
        rpad = field_width - str_width
        return 0, rpad

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
