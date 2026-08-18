## Description #############################################################################
#
# Functions related to string highlighting.
#
############################################################################################

export highlight_search

"""
    highlight_search(
        lines::Vector{T},
        search_matches::Dict{Int, Vector{Tuple{Int, Int}}};
        kwargs...
    ) where T <: AbstractString -> String
    highlight_search(
        lines::Vector{T},
        regex::Regex;
        kwargs...
    ) where T <: AbstractString -> String

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
    will be processed. This value is clamped to the number of lines.
    (**Default** = 0)
- `highlight::String`: ANSI escape sequence that contains the decoration of the highlight.
    (**Default** = `\\e[7m`)
- `max_column::Int`: Stop processing if the match is after this column. If it is equal or
    lower than 0, this limit will not be considered.
    (**Default** = 0)
- `min_column::Int`: Do not process matches before this column. If it is equal or lower than
    0, this limit will not be considered.
    (**Default** = 0)
- `start_line::Int`: Line to begin the processing. This value is clamped to 1.
    (**Default** = 0)
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
    start_line::Int = 0,
) where {T <: AbstractString}
    buf = IOBuffer()

    start_line = max(start_line, 1)

    # `end_line` must be clamped to the number of lines. Otherwise, we would try to access
    # a line that does not exist.
    end_line = end_line ≤ 0 ? length(lines) : min(end_line, length(lines))

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

            write(
                buf,
                highlight_search(
                    lines[l],
                    search_matches_l;
                    active_match = line_active_match,
                    highlight,
                    active_highlight,
                    min_column,
                    max_column,
                ),
            )

            num_matches += length(search_matches_l)
        else
            write(buf, lines[l])
        end

        (l != end_line) && write(buf, '\n')
    end

    return String(take!(buf))
end

function highlight_search(
    lines::Vector{T}, regex::Regex; kwargs...
) where {T <: AbstractString}
    search_matches = string_search_per_line(lines, regex)
    return highlight_search(lines, search_matches; kwargs...)
end

"""
    highlight_search(
        str::AbstractString,
        search_matches::Vector{Tuple{Int, Int}};
        kwargs...
    ) -> String
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
    start_column::Int = 1,
)
    num_matches = length(search_matches)

    (num_matches == 0) && return String(str)

    # The matches are sorted by their initial column. Hence, we can use a binary search to
    # find the first and the last match that can be visible in this view, avoiding a scan
    # over all of them.
    first_match = 1
    if (start_column > 1) || (min_column > 1)
        first_visible_column = max(start_column, min_column)
        low = 1
        high = num_matches
        while low ≤ high
            middle = (low + high) >>> 1
            match = search_matches[middle]
            if match[1] + match[2] - 1 < first_visible_column
                low = middle + 1
            else
                high = middle - 1
            end
        end
        first_match = low
    end

    last_match = num_matches
    if max_column > 0
        low = first_match
        high = num_matches
        while low ≤ high
            middle = (low + high) >>> 1
            if search_matches[middle][1] ≤ max_column
                low = middle + 1
            else
                high = middle - 1
            end
        end
        last_match = high
    end

    h_str = IOBuffer(; sizehint = sizeof(str))

    # Buffer to accumulate the ANSI escape sequence we are currently processing.
    buf_ansi = IOBuffer()

    # Current decoration of the string, considering every escape sequence seen so far.
    decoration = Decoration()

    state = :text

    # Printable column of the character we are processing. The first character of `str` is
    # at `start_column` because the string was already cropped by the caller.
    column = start_column

    match_index      = first_match
    match_end_column = 0
    in_match         = false

    for c in str
        state = _next_string_state(c, state)

        # == ANSI Escape Sequences =========================================================

        if state != :text
            write(buf_ansi, c)

            if state == :escape_state_end
                ansi = String(take!(buf_ansi))
                decoration = update_decoration(decoration, ansi)

                # Inside a match, the escape sequences must not be written because they
                # would override the highlight decoration. They are applied again when the
                # match ends.
                in_match || write(h_str, ansi)
            end

            continue
        end

        # == Printable Characters ==========================================================

        match_index, match_end_column, in_match = _apply_match_boundaries!(
            h_str,
            search_matches,
            decoration,
            column,
            match_index,
            match_end_column,
            in_match,
            last_match,
            active_match,
            highlight,
            active_highlight,
            start_column,
            min_column,
        )

        character_width = textwidth(c)
        next_column     = column + character_width

        # If a boundary falls strictly inside this character, we cannot break it. Hence, we
        # replace the character by spaces, keeping the printable width unchanged.
        boundary = if in_match
            match_end_column
        elseif match_index ≤ last_match
            search_matches[match_index][1]
        else
            typemax(Int)
        end

        if column < boundary < next_column
            for _ in column:(boundary - 1)
                write(h_str, ' ')
            end

            column = boundary

            match_index, match_end_column, in_match = _apply_match_boundaries!(
                h_str,
                search_matches,
                decoration,
                column,
                match_index,
                match_end_column,
                in_match,
                last_match,
                active_match,
                highlight,
                active_highlight,
                start_column,
                min_column,
            )

            for _ in boundary:(next_column - 1)
                write(h_str, ' ')
            end

            column = next_column
            continue
        end

        write(h_str, c)
        column = next_column
    end

    # A match can begin or end after the last character of the string, for example when the
    # line was cropped. Hence, we must process the remaining boundaries here.
    match_index, match_end_column, in_match = _apply_match_boundaries!(
        h_str,
        search_matches,
        decoration,
        column,
        match_index,
        match_end_column,
        in_match,
        last_match,
        active_match,
        highlight,
        active_highlight,
        start_column,
        min_column,
    )

    # If a match extends past the end of the string, we still must close its highlight.
    in_match && write(h_str, _RESET_DECORATIONS, String(decoration))

    return String(take!(h_str))
end

"""
    _apply_match_boundaries!(
        h_str::IOBuffer,
        search_matches::Vector{Tuple{Int, Int}},
        decoration::Decoration,
        column::Int,
        match_index::Int,
        match_end_column::Int,
        in_match::Bool,
        last_match::Int,
        active_match::Int,
        highlight::String,
        active_highlight::String,
        start_column::Int,
        min_column::Int
    ) -> Int, Int, Bool

Open and close in `h_str` all the highlights whose boundary is at `column`, advancing over
the matches that are not visible in the view.

A highlight is opened by writing `highlight`, or `active_highlight` if the match is the
active one, and closed by writing a reset followed by `decoration`, which restores the
decoration of the text that was suppressed inside the match.

# Returns

- `Int`: Index of the next match to be processed.
- `Int`: Column just after the end of the match being processed.
- `Bool`: `true` if we are inside a match after processing the boundaries.
"""
function _apply_match_boundaries!(
    h_str::IOBuffer,
    search_matches::Vector{Tuple{Int, Int}},
    decoration::Decoration,
    column::Int,
    match_index::Int,
    match_end_column::Int,
    in_match::Bool,
    last_match::Int,
    active_match::Int,
    highlight::String,
    active_highlight::String,
    start_column::Int,
    min_column::Int,
)
    while true
        if in_match
            (column < match_end_column) && break

            write(h_str, _RESET_DECORATIONS, String(decoration))
            in_match = false
            match_index += 1

        else
            (match_index > last_match) && break

            match = search_matches[match_index]
            match_last_column = match[1] + match[2] - 1

            # Skip the matches that are not visible in this view.
            if (match_last_column < start_column) ||
                ((min_column > 0) && (match_last_column < min_column))
                match_index += 1
                continue
            end

            (column < match[1]) && break

            write(h_str, match_index == active_match ? active_highlight : highlight)
            in_match         = true
            match_end_column = match[1] + match[2]
        end
    end

    return match_index, match_end_column, in_match
end

function highlight_search(str::AbstractString, regex::Regex; kwargs...)
    search_matches = string_search(str, regex)
    return highlight_search(str, search_matches; kwargs...)
end
