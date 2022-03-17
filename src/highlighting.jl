# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
# ==============================================================================
#
#   Functions related to string highlighting.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

export highlight_search

"""
    highlight_search(lines::Vector{T}, [search_matches::Dict{Int, Vector{Tuple{Int, Int}}} | regex::Regex]; kwargs...) where T <: AbstractString

Return the text composed of the `lines` with the `search_matches` (see
[`string_search_per_line`](@ref)) highlighted. If a `regex` is passed in the
place of `search_matches`, the latter is automatically computed using
[`string_search_per_line`](@ref).

# Keywords

- `active_match::Int`: The match number that is considered active. This match is
    highlighted using `active_highlight` instead of `highlight`.
    (**Default** = 0)
- `highlight::String`: ANSI escape sequence that contains the decoration of the
    highlight. (**Default** = `\\e[7m`)
- `active_highlight::String`: ANSI escape sequence that contains the decoration
    of the active highlight. (**Default** = `\\e[30;43m`.)
- `start_line::Int`: Line to begin the processing.
- `end_line::Int`: Line to end the processing.
"""
function highlight_search(
    lines::Vector{T},
    search_matches::Dict{Int, Vector{Tuple{Int, Int}}};
    active_match::Int = 0,
    highlight::String = _CSI * "7m",
    active_highlight::String = _CSI * "30;43m",
    start_line::Int = 0,
    end_line::Int = 0
) where T <: AbstractString


    buf = IOBuffer()

    if start_line ≤ 0
        start_line = 1
    end

    if end_line ≤ 0
        end_line = length(lines)
    end

    # Count how many matches we have before this line.
    num_matches = 0
    for l = 1:start_line - 1
        if haskey(search_matches, l)
            num_matches += length(search_matches[l])
        end
    end

    for l in start_line:end_line
        if haskey(search_matches, l)
            line_active_match = active_match - num_matches

            search_matches_l = search_matches[l]

            write(buf, highlight_search(
                lines[l],
                search_matches_l;
                active_match = line_active_match,
                highlight,
                active_highlight
            ))

            num_matches += length(search_matches_l)
        else
            write(buf, lines[l])
        end

        l != end_line && write(buf, '\n')
    end

    return String(take!(buf))
end

function highlight_search(
    lines::Vector{T},
    regex::Regex;
    kwargs...
) where T <: AbstractString
    search_matches = string_search_per_line(lines, regex)
    return highlight_search(lines, search_matches; kwargs...)
end

"""
    highlight_search(str::AbstractString, [search_matches::Vector{Tuple{Int, Int}} | regex::Regex]; kwargs...)

Return the text in the string `str` with the `search_matches` (see
[`string_search`](@ref)) highlighted. If a `regex` is passed in the place of
`search_matches`, the latter is automatically computed using
[`string_search`](@ref).

# Keywords

- `active_match::Int`: The match number that is considered active. This match is
    highlighted using `active_highlight` instead of `highlight`.
    (**Default** = 0)
- `highlight::String`: ANSI escape sequence that contains the decoration of the
    highlight. (**Default** = `\\e[7m`)
- `active_highlight::String`: ANSI escape sequence that contains the decoration
    of the active highlight. (**Default** = `\\e[30;43m`.)
- `start_line::Int`: Line to begin the processing.
- `end_line::Int`: Line to end the processing.
"""
function highlight_search(
    str::AbstractString,
    search_matches::Vector{Tuple{Int, Int}};
    active_match::Int = 0,
    highlight::String = _CSI * "7m",
    active_highlight::String = _CSI * "30;43m"
)

    num_matches = length(search_matches)

    if num_matches == 0
        return str
    end

    reset_decoration = convert(String, _RESET_DECORATION)
    h_str = IOBuffer(sizehint = length(str) * length(highlight) * num_matches)

    # Auxiliary variable to store how many characters were processed.
    Δ = 0

    # Store the current decoration of the string.
    decoration = Decoration()

    for i in 1:length(search_matches)
        match = search_matches[i]

        # Split the string in the point indicated by the match.
        str₀, str₁ = split_string(str, match[1] - 1 - Δ)

        # We need to obtain the current decoration and merge it the with one
        # stored in `decoration` to keep track how the string should be printed
        # after the highlight.
        str₀_decorations = get_decorations(str₀)
        decoration = update_decoration(decoration, str₀_decorations)

        # The highlight decoration will be a merge between the current string
        # highlight and the desired one.
        if i != active_match
            highlight_decoration = update_decoration(decoration, highlight)
        else
            highlight_decoration = update_decoration(decoration, active_highlight)
        end

        # Write the to the buffer the string before and the highlight
        # decoration.
        write(h_str, str₀, convert(String, highlight_decoration))

        # Now, we need to split the remaining string using the information on
        # how many characters we have in the match.
        str₂, str₃ = split_string(str₁, match[2])

        # There might be some decoration information inside `str₂` that must be
        # taken into account after the highlight.
        str₂_decorations, str₂_plain = get_and_remove_decorations(str₂)
        decoration = update_decoration(decoration, str₂_decorations)

        # Here we write the string, reset the decoration, and apply the previous
        # decoration stored in `decoration`.
        write(h_str, str₂_plain, reset_decoration)
        write(h_str, convert(String, decoration))

        # All the next matches must consider that we are not in the beginning of
        # the string anymore.
        Δ = match[1] + match[2] - 1
        str = str₃
    end

    # Write the remaining of the string.
    write(h_str, str)

    return String(take!(h_str))
end

function highlight_search(
    str::AbstractString,
    regex::Regex;
    kwargs...
)
    search_matches = string_search(str, regex)
    return highlight_search(str, search_matches; kwargs...)
end

