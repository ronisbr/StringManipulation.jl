StringManupulation.jl
=====================

[![CI](https://github.com/ronisbr/StringManipulation.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/ronisbr/PrettyNumbers.jl/actions/workflows/ci.yml)

This package has the purpose to provide several functions to manipulate strings
with ANSI escape sequences, like alignment and cropping.

## Alignment

The function `align_string` can be used to align the string in a field with a
specific size to the left, center, or right.

```julia
julia> align_string(
       "A string with emojis 😃😃 and \e[4mdecoration\e[0m to be aligned",
       80,
       :c
       ) |> print
             A string with emojis 😃😃 and decoration to be aligned

julia> align_string(
       "A string with emojis 😃😃 and \e[4mdecoration\e[0m to be aligned",
       80,
       :r
       ) |> print
                          A string with emojis 😃😃 and decoration to be aligned
```

If the string has multiple lines, then all can be aligned at once using the
function `align_string_per_line`.

```julia
julia> str = """
       We have \e[38;5;231;48;5;243mhere\e[0m 😅😃 the first line
       We now have the 😊 \e[38;5;231;48;5;243msecond\e[0m 😃 line""";

julia> align_string_per_line(str, 80, :r) |> print
                                                We have here 😅😃 the first line
                                               We now have the 😊 second 😃 line
```

## Cropping

### Left cropping

The function `left_crop` can be used to crop a field of specific width to the
left of the string. In this case, the function return the ANSI escape sequence
(non-printable string) in the cropped field, and the cropped string.

```julia
julia> str = "Test 😅 \e[38;5;231;48;5;243mTest 😅 \e[38;5;201;48;5;243mTest\e[0m";

julia> left_crop(str, 9)
("\e[38;5;231;48;5;243m", "est 😅 \e[38;5;201;48;5;243mTest\e[0m")
```

### Right cropping

The function `right_crop` can be used to crop a field of specific width to the
right of the string. In this case, the function return the cropped string, and
the ANSI escape sequence (non-printable string) in the cropped field.

```julia
julia> str = "Test 😅 \e[38;5;231;48;5;243mTest 😅 \e[38;5;201;48;5;243mTest\e[0m";

julia> right_crop(str, 5)
("Test 😅 \e[38;5;231;48;5;243mTest 😅", "\e[38;5;201;48;5;243m\e[0m")
```

If the keyword `keep_escape_seq` is set to `false`, then the ANSI escape
sequence in the cropped field will not be computed. This can lead to a
substantial increase in the performance for very long string.

```julia
julia> right_crop(str, 5; keep_escape_seq = false)
("Test 😅 \e[38;5;231;48;5;243mTest 😅", "")
```

## Printable text width

The printable text width of a string can be computed using the function
`printable_textwidth`:

```julia
julia> str = "Test 😅 \e[38;5;231;48;5;243mTest 😅 \e[38;5;201;48;5;243mTest\e[0m";

julia> printable_textwidth(str)
20
```

If the string has multiple lines, then the function
`printable_textwidth_per_line` can be used to compute the printable text width
of each one of them:

```julia
julia> str = """
       Test 😅 \e[38;5;231;48;5;243mTest 😅 \e[38;5;201;48;5;243mTest\e[0m
       Test 😅 \e[38;5;231;48;5;243mTest 😅 \e[38;5;201;48;5;243mTest Test\e[0m
       Test 😅 \e[38;5;231;48;5;243mTest 😅 \e[38;5;201;48;5;243mTest Test Test\e[0m""";

julia> printable_textwidth_per_line(str)
3-element Vector{Int64}:
 20
 25
 30
```
