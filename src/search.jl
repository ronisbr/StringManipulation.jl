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
    for m in eachmatch(r, undecorated_str)
        # `m.offset` contains the byte in which the match starts. However, we need to obtain
        # the character. Hence, it is necessary to compute the text width from the beginning
        # to the offset.
        push!(search_result, (
            textwidth(@view(undecorated_str[1:m.offset])),
            textwidth(m.match)
        ))
    end

    return search_result
end

"""
    string_search_per_line(str::AbstractString, r::Regex) -> Vector{NTuple{3, Int}}

Search for the pattern in regex `r` in each line of the string `str`, which can also be
passed as a vector of string `lines`. The result will be a vector of `NTuple{3, Int}` with
the line, beginning of the match in this line, and its length, where the two last values are
related to the width of printable characters.
"""
function string_search_per_line(str::AbstractString, r::Regex)
    tokens = split(str, '\n')
    return string_search_per_line(tokens, r)
end

function string_search_per_line(lines::AbstractVector{T}, r::Regex) where T<:AbstractString
    search_results = Dict{Int, Vector{Tuple{Int, Int}}}()

    # Find the matches in each line.
    for l in eachindex(lines)
        search_results_l = string_search(lines[l], r)

        if !isempty(search_results_l)
            search_results[l] = search_results_l
        end
    end

    return search_results
end
