## Description #############################################################################
#
# Functions related to string highlighting.
#
############################################################################################

export highlight_search

"""
    highlight_search(lines::Vector{T}, search_matches::Dict{Int, Vector{Tuple{Int, Int}}}; kwargs...) where T <: AbstractString -> String
    highlight_search(lines::Vector{T}, regex::Regex]; kwargs...) where T <: AbstractString -> String

Return the text composed of the `lines` with the `search_matches` (see
[`string_search_per_line`](@ref)) highlighted. If a `regex` is passed in the place of
`search_matches`, the latter is automatically computed using
[`string_search_per_line`](@ref).

# Keywords

- `active_match::Int`: The match number that is considered active. This match is highlighted
    using `active_highlight` instead of `highlight`.
    (**Default** = 0)
- `active_highlight::String`: ANSI escape sequence that contains the decoration of the
    active highlight.
    (**Default** = `\\e[30;43m`.)
- `end_line::Int`: Line to end the processing. If it is equal or lower than 0, all lines
    will be processed.
    (**Default** = 0)
- `highlight::String`: ANSI escape sequence that contains the decoration of the highlight.
    (**Default** = `\\e[7m`)
- `max_column::Int`: Stop processing if the match is after this column. If it is equal or
    lower than 0, this limit will not be considered.
    (**Default** = 0)
- `min_column::Int`: Do not process matches before this column. If it is equal or lower than
    0, this limit will not be considered.
    (**Default** = 0)
- `start_line::Int`: Line to begin the processing.
    (**Default** = 1)
"""
function highlight_search(
    lines::Vector{T},
    search_matches::Dict{Int, Vector{Tuple{Int, Int}}};
    active_highlight::String = _CSI * "30;43m",
    active_match::Int = 0,
    end_line::Int = 0,
    highlight::String = _CSI * "7m",
    max_column::Int = 0,
    min_column::Int = 0,
    start_line::Int = 0
) where T <: AbstractString

    buf = IOBuffer()

    start_line = max(start_line, 1)

    if end_line ≤ 0
        end_line = length(lines)
    end

    # Count how many matches we have before this line.
    num_matches = 0
    for l in 1:(start_line - 1)
        !haskey(search_matches, l) && continue
        num_matches += length(search_matches[l])
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
                active_highlight,
                min_column,
                max_column
            ))

            num_matches += length(search_matches_l)
        else
            write(buf, lines[l])
        end

        (l != end_line) && write(buf, '\n')
    end

    return String(take!(buf))
end

function highlight_search(lines::Vector{T}, regex::Regex; kwargs...) where T <: AbstractString
    search_matches = string_search_per_line(lines, regex)
    return highlight_search(lines, search_matches; kwargs...)
end

"""
    highlight_search(str::AbstractString, search_matches::Vector{Tuple{Int, Int}}; kwargs...) -> String
    highlight_search(str::AbstractString, regex::Regex; kwargs...) -> String

Return the text in the string `str` with the `search_matches` (see [`string_search`](@ref))
highlighted. If a `regex` is passed in the place of `search_matches`, the latter is
automatically computed using [`string_search`](@ref).

# Keywords

- `active_match::Int`: The match number that is considered active. This match is highlighted
    using `active_highlight` instead of `highlight`.
    (**Default** = 0)
- `active_highlight::String`: ANSI escape sequence that contains the decoration of the
    active highlight.
    (**Default** = `\\e[30;43m`.)
- `highlight::String`: ANSI escape sequence that contains the decoration of the highlight.
    (**Default** = `\\e[7m`)
- `max_column::Int`: Stop processing if the match is after this column. If it is equal or
    lower than 0, this limit will not be considered.
    (**Default** = 0)
- `min_column::Int`: Do not process matches before this column. If it is equal or lower than
    0, this limit will not be considered.
    (**Default** = 0)
- `start_column::Int`: The algorithm will consider that the first character in `str` is in
    this column.
    (**Default** = 1)
"""
function highlight_search(
    str::AbstractString,
    search_matches::Vector{Tuple{Int, Int}};
    active_highlight::String = _CSI * "30;43m",
    active_match::Int = 0,
    highlight::String = _CSI * "7m",
    max_column::Int = 0,
    min_column::Int = 0,
    start_column::Int = 1
)
    num_matches = length(search_matches)

    (num_matches == 0) && return str

    reset_decoration = convert(String, _RESET_DECORATION)
    h_str = IOBuffer(sizehint = floor(Int, sizeof(str)))

    # Auxiliary variable to store the index of the first character in the current string
    # part we are processing.
    Δ = start_column - 1

    # Store the current decoration of the string.
    decoration = Decoration()

    for i in 1:length(search_matches)
        match = search_matches[i]

        # If the match is before `start_column`, just skip it.
        ((match[1] + match[2] - 1) < start_column) && continue

        # If the match is before `min_column`, just skip it.
        ((min_column > 0) && ((match[1] + match[2] - 1) < min_column)) && continue

        # If the match is after `max_column`, we can stop the process.
        ((max_column > 0) && (match[1] > max_column)) && break

        # Split the string in the point indicated by the match.
        str₀, str₁ = split_string(str, match[1] - 1 - Δ)

        # We need to obtain the current decoration and merge it the with one stored in
        # `decoration` to keep track how the string should be printed after the highlight.
        str₀_decorations = get_decorations(str₀)
        decoration = update_decoration(decoration, str₀_decorations)

        # Check if we are in the active highlight or not.
        hd = i != active_match ? highlight : active_highlight

        # Write the to the buffer the string before and the highlight decoration.
        write(h_str, str₀, hd)

        # Now, we need to split the remaining string using the information on how many
        # characters we have in the match. Notice that we must take into account the case
        # where the match happened before the first character in `str`, i.e., before the
        # `start_column`. This case only happens when `match[1] - 1 - Δ` is negative.
        match_size = min(0, match[1] - 1 - Δ) + match[2]
        str₂, str₃ = split_string(str₁, match_size)

        # There might be some decoration information inside `str₂` that must be taken into
        # account after the highlight.
        str₂_decorations, str₂_plain = get_and_remove_decorations(str₂)
        decoration = update_decoration(decoration, str₂_decorations)

        # Here we write the string, reset the decoration, and apply the previous decoration
        # stored in `decoration`.
        write(h_str, str₂_plain, reset_decoration)
        write(h_str, convert(String, decoration))

        # All the next matches must consider that we are not in the beginning of the string
        # anymore.
        Δ = match[1] - 1 + match[2]
        str = str₃
    end

    # Write the rest of the string.
    write(h_str, str)

    return String(take!(h_str))
end

function highlight_search(str::AbstractString, regex::Regex; kwargs...)
    search_matches = string_search(str, regex)
    return highlight_search(str, search_matches; kwargs...)
end
