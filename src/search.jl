## Description #############################################################################
#
# Functions to perform searches in strings.
#
############################################################################################

export string_search, string_search_per_line

"""
    string_search(str::AbstractString, r::Regex) -> Vector{Tuple{Int, Int}}

Search for the pattern in regex `r` in the string `str`. The result will be a vector of
`Tuple{Int, Int}` with the beginning of the match and its length, where both values are
related to the width of printable characters.
"""
function string_search(str::AbstractString, r::Regex)
    # Remove the decorations so that we can search by regex.
    undecorated_str = remove_decorations(str)

    # Vector with the match tuples.
    search_result = Tuple{Int, Int}[]

    # Find all matches.
    # We track the current byte offset and accumulated text width so that each match only
    # scans the delta from the previous one, giving O(n) total work instead of O(n * k) when
    # there are k matches.
    prev_offset       = 1
    accumulated_width = 0

    @views for m in eachmatch(r, undecorated_str)
        # Advance the accumulated width only from the previous offset to the start of this
        # match, avoiding a full rescan from byte 1 each time.
        accumulated_width += textwidth(undecorated_str[prev_offset:(m.offset)])
        prev_offset = nextind(undecorated_str, m.offset)

        push!(search_result, (accumulated_width, textwidth(m.match)))
    end

    return search_result
end

"""
    string_search_per_line(
        str::AbstractString,
        r::Regex
    ) -> Dict{Int, Vector{Tuple{Int, Int}}}
    string_search_per_line(
        lines::AbstractVector{T},
        r::Regex
    ) -> Dict{Int, Vector{Tuple{Int, Int}}} where {T <: AbstractString}
    string_search_per_line(
        layout::TextViewLayout,
        r::Regex
    ) -> Dict{Int, Vector{Tuple{Int, Int}}}

Search each source line for regex `r`. Map matching line numbers to tuples containing the
printable-column beginning and printable width of each match.

# Arguments

- `str::AbstractString`: Newline-delimited text to search.
- `lines::AbstractVector{T}`: String lines to search.
- `layout::TextViewLayout`: Prepared layout to search.
- `r::Regex`: Regular expression to match.

# Returns

- `Dict{Int, Vector{Tuple{Int, Int}}}`: Matches grouped by one-based line number.
"""
function string_search_per_line(str::AbstractString, r::Regex)
    return _internal__string_search_per_line(eachsplit(str, '\n'), r)
end

function string_search_per_line(
    lines::AbstractVector{T}, r::Regex
) where {T <: AbstractString}
    return _internal__string_search_per_line(lines, r)
end

function string_search_per_line(layout::TextViewLayout, r::Regex)
    return _internal__string_search_per_line(layout._lines, r)
end

function _internal__string_search_per_line(it, r::Regex)
    search_results = Dict{Int, Vector{Tuple{Int, Int}}}()

    # Find the matches in each line.
    for (i, line) in enumerate(it)
        search_results_l = string_search(line, r)
        isempty(search_results_l) && continue
        search_results[i] = search_results_l
    end

    return search_results
end
