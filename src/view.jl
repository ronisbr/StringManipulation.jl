## Description #############################################################################
#
# Functions to obtain a view of a text.
#
############################################################################################

export textview

"""
    textview([io::IO,] text::AbstractString, view::NTuple{4, Int}; kwargs...)
    textview([io::IO,] lines::Vector{AbstractString}, view::NTuple{4, Int}; kwargs...)

Create a view of `text` or `lines` considering a `view` configuration. The latter is a tuple
with four integers that has the following meaning:

- Top line;
- Number of lines;
- Left column; and
- Number of columns.

If a value equal or lower than 0 is passed to any of those options, its extreme value is
used.

# Keywords

- `active_highlight::String`: ANSI escape sequence that contains the decoration of the
    active highlight. (**Default** = `\\e[30;43m`)
- `active_match::Int`: The match number that is considered active. This match is highlighted
    using `active_highlight` instead of `highlight`.  (**Default** = 0)
- `frozen_columns_at_beginning::Int`: Number of frozen columns that are drawn in the
    beginning. (**Default** = 0)
- `frozen_lines_at_beginning::Int`: Number of frozen lines that are drawn in the beginning.
    (**Default** = 0)
- `highlight::String`: ANSI escape sequence that contains the decoration of the highlight.
    (**Default** = `\\e[7m`)
- `maximum_number_of_columns::Int`: Maximum number of columns in the view, regardless the
    view width. If it is -1, the entire view width will be used. (**Default** = -1)
- `maximum_number_of_lines::Int`: Maximum number of lines in the view, regardless the view
    height. If it is -1, the entire view height will be used. (**Default** = -1)
- `parse_decorations_before_view::Bool`: If `true`, we will scan all the decorations in the
    lines before the view and consider them when rendering the output. Otherwise, everything
    before the beginning of the view will be discarded. If this option is `false`, the
    decoration can be wrong. However, this feature can require a high amount of processing
    depending on the input string size and the view position. (**Default** = `false`)
- `ruler_decoration::String`: ANSI escape sequence that contains the decoration of the
    ruler. (**Default** = `\\e[90m`)
- `show_ruler::Bool`: If `true`, a ruler with the row numbers will be shown to the left of
    the view. (**Default** = `false`)
- `visual_lines::Union{Nothing, Vector{Int}}`: Vector containing the number of the lines
    that will be highlighted with a different background (visual mode). If it is `nothing`,
    no line will be changed. (**Default** = `nothing`)
- `visual_line_backgrounds::Union{String, Vector{String}}`: ANSI code for the background
    decorations of the lines in `visual_lines`. It can be a `Vector{String}`, where a
    background can be specified for each line, or a `String`, where all backgrounds will
    have the same decoration. (**Default** = "44")
- `title_lines::Int`: Number of lines at the beginning of the text to be considered as
    title, meaning that they will be printed statically on the screen regardless the view.
    (**Default** = 0)

If `text::AbstractString` is passed, the following keyword is available:

- `search_regex::Uniont{Nothing, Regex}`: A regex used to highlight matches in the text
    view. (**Default** = `nothing`).

If `lines::Vector{AbstractString}` is passed, the following keyword is available:

- `search_matches::Union{Nothing, Dict{Int, Vector{Tuple{Int, Int}}}}`: The search matches
    that are highlighted in the text view. This dictionary must be created using the
    function [`string_search_per_line`](@ref). (**Default** = `nothing`)

# Returns

If `io` is passed, the view is written to it and the function returns:

- `Int`: Number of cropped lines at the end.
- `Int`: Maximum number cropped characters in a row.

However, if `io` is not passed, the function returns:

- `String`: Text view.
- `Int`: Number of cropped lines at the end.
- `Int`: Maximum number cropped characters in a row.

!!! note

    If only frozen lines are printed, the second returned value is set to 0.

    If only frozen columns are printed, the third returned value is set to 0.
"""
function textview(text::AbstractString, view::NTuple{4, Int}; kwargs...)
    buf = IOBuffer()
    num_cropped_lines, max_cropped_chars = textview(buf, text, view; kwargs...)
    return String(take!(buf)), num_cropped_lines, max_cropped_chars
end

function textview(
    buf::IO,
    text::AbstractString,
    view::NTuple{4, Int};
    search_regex::Union{Nothing, Regex} = nothing,
    kwargs...
)
    lines = split(text, '\n')

    search_matches = if !isnothing(search_regex)
        string_search_per_line(lines, search_regex)
    else
        nothing
    end

    return textview(
        buf,
        lines,
        view;
        search_matches,
        kwargs...
    )
end

function textview(lines::Vector{T}, view::NTuple{4, Int}; kwargs...) where T<:AbstractString
    buf = IOBuffer()
    num_cropped_lines, max_cropped_chars = textview(buf, lines, view; kwargs...)
    return String(take!(buf)), num_cropped_lines, max_cropped_chars
end

function textview(
    buf::IO,
    lines::Vector{T},
    view::NTuple{4, Int};
    active_highlight::String = _CSI * "30;43m",
    active_match::Int = 0,
    frozen_columns_at_beginning::Int = 0,
    frozen_lines_at_beginning::Int = 0,
    highlight::String = _CSI * "7m",
    maximum_number_of_columns::Int = -1,
    maximum_number_of_lines::Int = -1,
    parse_decorations_before_view::Bool = false,
    ruler_decoration::String = _CSI * "90m",
    search_matches::Union{Nothing, Dict{Int, Vector{Tuple{Int, Int}}}} = nothing,
    show_ruler::Bool = false,
    visual_lines::Union{Nothing, Vector{Int}} = nothing,
    visual_line_backgrounds::Union{String, Vector{String}} = "44",
    title_lines::Int = 0
) where T<:AbstractString

    # == Verification of the Input Parameters ==============================================

    start_line  = view[1]
    num_lines   = view[2]
    total_lines = length(lines)

    start_line = clamp(start_line, 1, total_lines)
    num_lines = num_lines ≥ 0 ? clamp(num_lines, 0, total_lines - start_line + 1) : total_lines

    if start_line + num_lines - 1 > total_lines
        num_lines = total_lines - start_line + 1
    end

    if frozen_lines_at_beginning > 0
        start_line = clamp(start_line, frozen_lines_at_beginning + 1, total_lines)
    end

    start_column = max(view[3], 1)

    num_columns = view[4]

    if (frozen_columns_at_beginning > 0) && (start_column ≤ frozen_columns_at_beginning)
        start_column = frozen_columns_at_beginning + 1
    end

    # If the user wants a ruler, compute the required size here.
    ruler_spacing = 0

    if show_ruler
        ruler_spacing = floor(Int, total_lines |> abs |> log10) + 1

        # If the user selected a maximum number of columns, we need to decrease it to take
        # into account the ruler.
        if maximum_number_of_columns ≥ 0
            maximum_number_of_columns = max(maximum_number_of_columns - ruler_spacing - 3, 0)
        end
    end

    if !isnothing(visual_lines)
        if visual_line_backgrounds isa AbstractVector
            (length(visual_lines) != length(visual_line_backgrounds)) && throw(ArgumentError(
                "The length of `visual_line` must be equal to the length of `visual_line_backgrounds`."
            ))

            visual_line_background_vec = visual_line_backgrounds
        else
            visual_line_background_vec = fill("44", length(visual_lines))
        end
    else
        visual_line_background_vec = nothing
    end

    # == Internal Variables ================================================================

    # Count how many matches we passed in the current line that is being processed.
    num_matches = 0

    # Variable to store the maximum number of cropped lines at the end.
    num_cropped_lines_at_end = 0

    # Variable to compute the maximum number of characters cropped in the right.
    max_cropped_chars = 0

    # Variable to store the decorations before the view, including those in the frozen
    # lines. It is used if the option `parse_decorations_before_view` is `true`.
    pre_decorations = ""

    # Check if we have a maximum number of lines.
    if maximum_number_of_lines ≥ 0
        if frozen_lines_at_beginning ≥ maximum_number_of_lines
            frozen_lines_at_beginning = maximum_number_of_lines
            num_lines = 0

        else
            if num_lines > maximum_number_of_lines - frozen_lines_at_beginning
                num_lines = maximum_number_of_lines - frozen_lines_at_beginning
            end

            num_cropped_lines_at_end = total_lines - start_line - (num_lines - 1)
        end
    else
       num_cropped_lines_at_end = total_lines - start_line - (num_lines - 1)
    end

    # Check if we have a maximum number of columns.
    if maximum_number_of_columns ≥ 0
        # Check if we can only draw the frozen columns.
        if frozen_columns_at_beginning ≥ maximum_number_of_columns
            frozen_columns_at_beginning = maximum_number_of_columns
            start_column = frozen_columns_at_beginning + 1
            num_columns = 0

        else
            if num_columns < 0
                num_columns =
                    maximum_number_of_columns - frozen_columns_at_beginning
            else
                num_columns = clamp(
                    num_columns,
                    -1,
                    maximum_number_of_columns - frozen_columns_at_beginning
                )
            end
        end
    end

    # == Frozen Lines ======================================================================

    for l in 1:frozen_lines_at_beginning
        line_active_match = active_match - num_matches

        if !isnothing(search_matches) && haskey(search_matches, l)
            line_search_matches = search_matches[l]
        else
            line_search_matches = nothing
        end

        if show_ruler
            line_number_str = lpad(l, ruler_spacing)
            write(buf, ruler_decoration, " ")
            write(buf, line_number_str, " │")
            write(buf, _CSI, "0m")
        end

        cropped_chars_in_line = 0

        if l ≤ title_lines
            _draw_line_view!(
                buf,
                lines[l],
                line_search_matches,
                line_active_match,
                highlight,
                active_highlight,
                1,
                0,
                num_columns + frozen_columns_at_beginning
            )

        else
            cropped_chars_in_line = _draw_line_view!(
                buf,
                lines[l],
                line_search_matches,
                line_active_match,
                highlight,
                active_highlight,
                start_column,
                num_columns,
                frozen_columns_at_beginning
            )
        end

        # We should not compute the number of cropped chars if we are only printing frozen
        # columns.
        if frozen_columns_at_beginning != maximum_number_of_columns
            max_cropped_chars = max(max_cropped_chars, cropped_chars_in_line)
        end

        # At the last frozen line, we must reset all the decorations.
        if l != frozen_lines_at_beginning
            write(buf, '\n')
        else
            write(buf, _CSI, "0m")
            num_lines > 0 && write(buf, '\n')
        end

        if !isnothing(line_search_matches)
            num_matches += length(line_search_matches)
        end

        # If the user wants, we need to accumulate all the decorations from the beginning of
        # the text up to the first line in the view. Here, we accumulate those related to
        # the frozen lines.
        if parse_decorations_before_view
            pre_decorations *= get_decorations(lines[l])
        end
    end

    for l = (frozen_lines_at_beginning + 1):(start_line - 1)
        # Sum the number of matches between the frozen line and the displayed line. This
        # computation is important to find which match is active.
        if !isnothing(search_matches) && haskey(search_matches, l)
            num_matches += length(search_matches[l])
        end

        # If we need to parse the decorations before the view, obtain the decorations of the
        # current hidden line, and merge with the decorations of the other lines.
        if parse_decorations_before_view
            pre_decorations *= get_decorations(lines[l])
        end
    end

    if parse_decorations_before_view
        d = parse_decoration(pre_decorations)

        # If the pre_decoration is a reset, we just need to reinitialize it since the reset
        # escape sequence was already written to the buffer.
        !d.reset && write(buf, d |> String)
    end

    # == Line Views ========================================================================

    for k in 1:num_lines
        # Get the current line number.
        l = start_line + (k - 1)

        line_active_match = active_match - num_matches

        if !isnothing(search_matches) && haskey(search_matches, l)
            line_search_matches = search_matches[l]
        else
            line_search_matches = nothing
        end

        if show_ruler
            line_number_str = lpad(l, ruler_spacing)
            write(buf, ruler_decoration, " ")
            write(buf, line_number_str, " │")
            write(buf, _CSI, "0m")
        end

        i_vl = isnothing(visual_lines) ? nothing : findfirst(==(l), visual_lines)

        if !isnothing(i_vl)
            is_visual_line = true
            visual_line_background = visual_line_background_vec[i_vl]
        else
            is_visual_line = false
            visual_line_background = ""
        end

        cropped_chars_in_line = _draw_line_view!(
            buf,
            lines[l],
            line_search_matches,
            line_active_match,
            highlight,
            active_highlight,
            start_column,
            num_columns,
            frozen_columns_at_beginning,
            is_visual_line,
            visual_line_background
        )

        # We should not compute the number of cropped chars if we are only printing frozen
        # columns.
        if frozen_columns_at_beginning != maximum_number_of_columns
            max_cropped_chars = max(max_cropped_chars, cropped_chars_in_line)
        end

        k != num_lines && write(buf, '\n')

        if !isnothing(line_search_matches)
            num_matches += length(line_search_matches)
        end
    end

    return num_cropped_lines_at_end, max_cropped_chars
end

############################################################################################
#                                    Private Functions                                     #
############################################################################################

# Draw a line view and return the number of right characters that was cropped.
function _draw_line_view!(
    buf::IO,
    line::AbstractString,
    line_search_matches::Union{Nothing, Vector{Tuple{Int, Int}}},
    line_active_match::Int,
    highlight::String,
    active_highlight::String,
    start_column::Int,
    num_columns::Int,
    frozen_columns_at_beginning::Int,
    visual_line::Bool = false,
    visual_line_background::String = ""
)
    line_str = string(line)

    # Frozen columns.
    if frozen_columns_at_beginning > 0
        left, _ = split_string(line_str, frozen_columns_at_beginning)

        # If this is a visual line, we must ensure that the frozen row has the minimum
        # number of characters to fill the frozen space.
        if visual_line
            w = printable_textwidth(left)
            if w < frozen_columns_at_beginning
                left = string(left, " "^(frozen_columns_at_beginning - w))
            end
            left = replace_default_background(left, visual_line_background)
        end

        # If we have matches, we should have highlight those in the frozen columns.
        if !isnothing(line_search_matches)
            left = highlight_search(
                left,
                line_search_matches;
                active_highlight,
                active_match = line_active_match,
                highlight,
                min_column = 1,
                max_column = frozen_columns_at_beginning,
                start_column = 1
            )
        end

        write(buf, left, _RESET_DECORATIONS)
    end

    left_ansi  = ""
    right_ansi = ""

    if start_column > 0
        # TODO: Can we improve this?
        # Maybe we can improve the performance by creating a function that remove a certain
        # number of characters from the left/right and also returns the ANSI escape
        # sequence.
        left, line_str = split_string(line_str, start_column - 1)

        # Here we simplify the decorations to avoid too many escape sequences.
        left_ansi = get_decorations(left) |> parse_decoration |> String
    end

    if num_columns ≥ 0
        # If this is a visual line, we change the default background.
        if visual_line
            w = printable_textwidth(line_str)

            if w < num_columns
                line_str = line_str * " "^(num_columns - w)
            end
        end

        line_str, right = split_string(line_str, num_columns)

        # Here we simplify the decorations to avoid too many escape sequences.
        right_ansi = get_decorations(right) |> parse_decoration |> String

        # Compute the amount of printable cropped characters in the right string.
        cropped_chars = printable_textwidth(right)

        # Compute the complete line for this view.
        line_str = string(left_ansi, line_str, right_ansi)

        if visual_line
            # If this is a visual line, let's change its background.
            line_str = replace_default_background(line_str, visual_line_background)
        end
    else
        cropped_chars = 0
        line_str = string(left_ansi, line_str)
    end

    # Now that we have what we will print to the buffer, we can highlight the matches if
    # they exist in the visible area.
    if !isnothing(line_search_matches)
        line_str = highlight_search(
            line_str,
            line_search_matches;
            active_highlight,
            active_match = line_active_match,
            highlight,
            start_column = start_column,
            min_column = start_column,
            max_column = start_column + num_columns - 1
        )
    end

    write(buf, line_str)

    return cropped_chars
end
