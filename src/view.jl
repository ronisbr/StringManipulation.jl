## Description #############################################################################
#
# Functions to obtain a view of a text.
#
############################################################################################

export textview

############################################################################################
#                                   Types and Structures                                   #
############################################################################################

"""
    abstract type TextViewSource

Represent a source of lines rendered by the shared text-view implementation.
"""
abstract type TextViewSource end

"""
    struct RawTextViewSource{T <: AbstractString} <: TextViewSource

Wrap raw lines for text-view rendering.

# Fields

- `lines::Vector{T}`: Raw lines to render.
"""
struct RawTextViewSource{T <: AbstractString} <: TextViewSource
    lines::Vector{T}
end

"""
    struct PreparedTextViewSource <: TextViewSource

Wrap a prepared layout for text-view rendering.

# Fields

- `layout::TextViewLayout`: Prepared layout to render.
"""
struct PreparedTextViewSource <: TextViewSource
    layout::TextViewLayout
end

############################################################################################
#                                     Public Functions                                     #
############################################################################################

"""
    textview(text::AbstractString, view::NTuple{4, Int}; kwargs...) -> Tuple{String, Int, Int}
    textview(io::IO, text::AbstractString, view::NTuple{4, Int}; kwargs...) -> Tuple{Int, Int}
    textview(lines::Vector{T}, view::NTuple{4, Int}; kwargs...) where {T <: AbstractString} -> Tuple{String, Int, Int}
    textview(io::IO, lines::Vector{T}, view::NTuple{4, Int}; kwargs...) where {T <: AbstractString} -> Tuple{Int, Int}
    textview(layout::TextViewLayout, view::NTuple{4, Int}; kwargs...) -> Tuple{String, Int, Int}
    textview(io::IO, layout::TextViewLayout, view::NTuple{4, Int}; kwargs...) -> Tuple{Int, Int}

Create a view of `text` or `lines` considering a `view` configuration. The latter is a tuple
with four integers that has the following meaning:

- Top line;
- Number of lines;
- Left column; and
- Number of columns.

If a value equal or lower than 0 is passed to any of those options, its extreme value is
used.

A [`TextViewLayout`](@ref) can be constructed once and reused to render multiple viewports.
Prepared layouts keep indexed widths, Unicode boundaries, and ANSI state while search and
visual overlays remain dynamic.

# Keywords

- `active_highlight::String`: Set the ANSI decoration for the active highlight.
    (**Default**: `\\e[30;43m`)
- `active_match::Int`: Select the active match and decorate it with `active_highlight`.
    (**Default**: 0)
- `active_match_location::NTuple{2, Int}`: Select the prepared-layout match as
    `(line, within_line_index)`. Use a nonzero location to take precedence over
    `active_match`.
    (**Default**: `(0, 0)`)
- `frozen_columns_at_beginning::Int`: Keep this many leading columns visible.
    (**Default**: 0)
- `frozen_lines_at_beginning::Int`: Keep this many leading lines visible.
    (**Default**: 0)
- `highlight::String`: Set the ANSI decoration for regular highlights.
    (**Default**: `\\e[7m`)
- `hide_title_lines::Bool`: Hide title lines from the frozen block and fill the view with
    remaining lines when `true`.
    (**Default**: `false`)
- `maximum_number_of_columns::Int`: Limit the number of columns regardless of the view
    width. Use -1 to retain the entire view width.
    (**Default**: -1)
- `maximum_number_of_lines::Int`: Limit the number of lines regardless of the view height.
    Use -1 to retain the entire view height.
    (**Default**: -1)
- `parse_decorations_before_view::Bool`: Scan decorations before the view and restore their
    state when `true`. Use `false` to discard them, which can produce incorrect decorations
    but avoids processing preceding input.
    (**Default**: `false`)
- `ruler_decoration::String`: Set the ANSI decoration for the ruler.
    (**Default**: `\\e[90m`)
- `show_ruler::Bool`: Show a line-number ruler to the left of the view when `true`.
    (**Default**: `false`)
- `visual_lines::Union{Nothing, Vector{Int}}`: Select lines for visual highlighting. Use
    `nothing` to leave all lines unchanged.
    (**Default**: `nothing`)
- `visual_line_backgrounds::Union{String, Vector{String}}`: Set one ANSI background for all
    visual lines or provide one background per line.
    (**Default**: "44")
- `title_lines::Int`: Treat this many leading lines as static titles.
    (**Default**: 0)

If `text::AbstractString` is passed, the following keyword is available:

- `search_regex::Union{Nothing, Regex}`: Highlight text matching this regular expression.
    (**Default**: `nothing`)

If `lines::Vector{T}` where `T <: AbstractString` is passed, the following keyword is
available:

- `search_matches::Union{Nothing, Dict{Int, Vector{Tuple{Int, Int}}}}`: Highlight these
    matches by line. Create the dictionary with [`string_search_per_line`](@ref).
    (**Default**: `nothing`)

# Returns

If `io` is passed, the view is written to it and the function returns a tuple containing:

- `Int`: Number of cropped lines at the end.
- `Int`: Maximum number of cropped characters in a row.

If `io` is not passed, the function returns a tuple containing:

- `String`: Text view.
- `Int`: Number of cropped lines at the end.
- `Int`: Maximum number of cropped characters in a row.

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
    kwargs...,
)
    lines = split(text, '\n')

    search_matches = if !isnothing(search_regex)
        string_search_per_line(lines, search_regex)
    else
        nothing
    end

    return textview(buf, lines, view; search_matches, kwargs...)
end

function textview(
    lines::Vector{T}, view::NTuple{4, Int}; kwargs...
) where {T <: AbstractString}
    buf = IOBuffer()
    num_cropped_lines, max_cropped_chars = textview(buf, lines, view; kwargs...)
    return String(take!(buf)), num_cropped_lines, max_cropped_chars
end

function textview(layout::TextViewLayout, view::NTuple{4, Int}; kwargs...)
    buf = IOBuffer()
    num_cropped_lines, max_cropped_chars = textview(buf, layout, view; kwargs...)
    return String(take!(buf)), num_cropped_lines, max_cropped_chars
end

function textview(
    buf::IO, lines::Vector{T}, view::NTuple{4, Int}; kwargs...
) where {T <: AbstractString}
    return _textview(buf, RawTextViewSource(lines), view; kwargs...)
end

function textview(
    buf::IO,
    layout::TextViewLayout,
    view::NTuple{4, Int};
    active_match_location::NTuple{2, Int} = (0, 0),
    kwargs...,
)
    return _textview(
        buf, PreparedTextViewSource(layout), view; active_match_location, kwargs...
    )
end

"""
    _textview(buf::IO, source::TextViewSource, view::NTuple{4, Int}; kwargs...) -> Tuple{Int, Int}

Render a viewport from `source` into `buf` and return its cropping measurements.

# Arguments

- `buf::IO`: Write the rendered viewport to this output buffer.
- `source::TextViewSource`: Provide the raw or prepared lines to render.
- `view::NTuple{4, Int}`: Set the top line, height, left column, and width.

# Keywords

- `active_highlight::String`: Set the active-match ANSI decoration.
    (**Default**: `\\e[30;43m`)
- `active_match::Int`: Select the globally active search match.
    (**Default**: 0)
- `frozen_columns_at_beginning::Int`: Keep this many leading columns visible.
    (**Default**: 0)
- `frozen_lines_at_beginning::Int`: Keep this many leading lines visible.
    (**Default**: 0)
- `highlight::String`: Set the regular-match ANSI decoration.
    (**Default**: `\\e[7m`)
- `hide_title_lines::Bool`: Hide title lines from the frozen block.
    (**Default**: `false`)
- `maximum_number_of_columns::Int`: Limit the rendered viewport width.
    (**Default**: -1)
- `maximum_number_of_lines::Int`: Limit the rendered viewport height.
    (**Default**: -1)
- `parse_decorations_before_view::Bool`: Restore ANSI state from preceding lines.
    (**Default**: `false`)
- `ruler_decoration::String`: Set the ruler ANSI decoration.
    (**Default**: `\\e[90m`)
- `search_matches::Union{Nothing, Dict{Int, Vector{Tuple{Int, Int}}}}`: Provide matches by
    line.
    (**Default**: `nothing`)
- `show_ruler::Bool`: Show line numbers beside the viewport.
    (**Default**: `false`)
- `visual_lines::Union{Nothing, Vector{Int}}`: Select lines for visual highlighting.
    (**Default**: `nothing`)
- `visual_line_backgrounds::Union{String, Vector{String}}`: Set visual-line backgrounds.
    (**Default**: "44")
- `title_lines::Int`: Treat this many leading lines as titles.
    (**Default**: 0)
- `active_match_location::NTuple{2, Int}`: Select a prepared-layout match by line and index.
    (**Default**: `(0, 0)`)
"""
function _textview(
    buf::IO,
    source::TextViewSource,
    view::NTuple{4, Int};
    active_highlight::String = _CSI * "30;43m",
    active_match::Int = 0,
    frozen_columns_at_beginning::Int = 0,
    frozen_lines_at_beginning::Int = 0,
    highlight::String = _CSI * "7m",
    hide_title_lines::Bool = false,
    maximum_number_of_columns::Int = -1,
    maximum_number_of_lines::Int = -1,
    parse_decorations_before_view::Bool = false,
    ruler_decoration::String = _CSI * "90m",
    search_matches::Union{Nothing, Dict{Int, Vector{Tuple{Int, Int}}}} = nothing,
    show_ruler::Bool = false,
    visual_lines::Union{Nothing, Vector{Int}} = nothing,
    visual_line_backgrounds::Union{String, Vector{String}} = "44",
    title_lines::Int = 0,
    active_match_location::NTuple{2, Int} = (0, 0),
)

    # == Verification of the Input Parameters ==============================================

    start_line  = view[1]
    num_lines   = view[2]
    total_lines = _source_length(source)

    total_lines == 0 && return 0, 0

    frozen_lines_at_beginning = clamp(frozen_lines_at_beginning, 0, total_lines)
    title_lines = clamp(title_lines, 0, frozen_lines_at_beginning)

    start_line = clamp(start_line, 1, total_lines)

    if frozen_lines_at_beginning > 0
        first_non_frozen_line = frozen_lines_at_beginning + 1

        start_line = if first_non_frozen_line > total_lines
            total_lines + 1
        else
            clamp(start_line, first_non_frozen_line, total_lines)
        end
    end

    available_lines = max(total_lines - start_line + 1, 0)
    num_lines = num_lines ≥ 0 ? clamp(num_lines, 0, available_lines) : available_lines

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
            maximum_number_of_columns = max(
                maximum_number_of_columns - ruler_spacing - 3, 0
            )
        end
    end

    visual_line_backgrounds_by_line = nothing

    if !isnothing(visual_lines)
        if visual_line_backgrounds isa AbstractVector
            (length(visual_lines) != length(visual_line_backgrounds)) && throw(
                ArgumentError(
                    "The length of `visual_line` must be equal to the length of " *
                    "`visual_line_backgrounds`.",
                ),
            )

            backgrounds = visual_line_backgrounds
        else
            backgrounds = Iterators.repeated(visual_line_backgrounds, length(visual_lines))
        end

        visual_line_backgrounds_by_line = Dict{Int, String}()

        for (line, background) in zip(visual_lines, backgrounds)
            if !haskey(visual_line_backgrounds_by_line, line)
                visual_line_backgrounds_by_line[line] = background
            end
        end
    end

    # == Internal Variables ================================================================

    hidden_title_lines = hide_title_lines ? title_lines : 0
    visible_frozen_lines_at_beginning = frozen_lines_at_beginning - hidden_title_lines

    if hidden_title_lines > 0
        num_lines = clamp(num_lines + hidden_title_lines, 0, total_lines - start_line + 1)
    end

    # Count how many matches we passed in the current line that is being processed.
    num_matches = 0

    # Variable to store the maximum number of cropped lines at the end.
    num_cropped_lines_at_end = 0

    # Variable to compute the maximum number of characters cropped in the right.
    max_cropped_chars = 0

    # Variable to store the decorations before the view, including those in the frozen
    # lines. It is used if the option `parse_decorations_before_view` is `true`.
    pre_decorations = parse_decorations_before_view ? IOBuffer() : nothing

    # Check if we have a maximum number of lines.
    if maximum_number_of_lines ≥ 0
        if visible_frozen_lines_at_beginning ≥ maximum_number_of_lines
            frozen_lines_at_beginning = hidden_title_lines + maximum_number_of_lines
            num_lines = 0

        else
            if num_lines > maximum_number_of_lines - visible_frozen_lines_at_beginning
                num_lines = maximum_number_of_lines - visible_frozen_lines_at_beginning
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
                num_columns = maximum_number_of_columns - frozen_columns_at_beginning
            else
                num_columns = clamp(
                    num_columns, -1, maximum_number_of_columns - frozen_columns_at_beginning
                )
            end
        end
    end

    # == Frozen Lines ======================================================================

    for l in 1:frozen_lines_at_beginning
        line_search_matches = if !isnothing(search_matches) && haskey(search_matches, l)
            search_matches[l]
        else
            nothing
        end

        if hide_title_lines && (l ≤ title_lines)
            if !isnothing(line_search_matches)
                num_matches += length(line_search_matches)
            end

            if parse_decorations_before_view && (source isa RawTextViewSource)
                write(pre_decorations, _source_decorations(source, l))
            end

            continue
        end

        line_active_match = _line_active_match(
            active_match_location, l, active_match - num_matches
        )

        if show_ruler
            line_number_str = lpad(l, ruler_spacing)
            write(buf, ruler_decoration, " ")
            write(buf, line_number_str, " │")
            write(buf, _CSI, "0m")
        end

        cropped_chars_in_line = 0

        if l ≤ title_lines
            title_num_columns = 0
            title_frozen_columns_at_beginning = num_columns + frozen_columns_at_beginning

            if title_frozen_columns_at_beginning < 0
                title_num_columns = -1
                title_frozen_columns_at_beginning = 0
            end

            _draw_source_line_view!(
                buf,
                source,
                l,
                line_search_matches,
                line_active_match,
                highlight,
                active_highlight,
                1,
                title_num_columns,
                title_frozen_columns_at_beginning,
            )

        else
            cropped_chars_in_line = _draw_source_line_view!(
                buf,
                source,
                l,
                line_search_matches,
                line_active_match,
                highlight,
                active_highlight,
                start_column,
                num_columns,
                frozen_columns_at_beginning,
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
        if parse_decorations_before_view && (source isa RawTextViewSource)
            write(pre_decorations, _source_decorations(source, l))
        end
    end

    for l in (frozen_lines_at_beginning + 1):(start_line - 1)
        # Sum the number of matches between the frozen line and the displayed line. This
        # computation is important to find which match is active.
        if (active_match_location == (0, 0)) &&
            !isnothing(search_matches) &&
            haskey(search_matches, l)
            num_matches += length(search_matches[l])
        end

        # If we need to parse the decorations before the view, obtain the decorations of the
        # current hidden line, and merge with the decorations of the other lines.
        if parse_decorations_before_view && (source isa RawTextViewSource)
            write(pre_decorations, _source_decorations(source, l))
        end
    end

    if parse_decorations_before_view
        d = if source isa PreparedTextViewSource
            start_line == 1 ? Decoration() :
            source.layout.document_ansi_checkpoints[start_line - 1]
        else
            parse_decoration(String(take!(pre_decorations)))
        end

        # If the pre_decoration is a reset, we just need to reinitialize it since the reset
        # escape sequence was already written to the buffer.
        !d.reset && write(buf, d |> String)
    end

    # == Line Views ========================================================================

    for k in 1:num_lines
        # Get the current line number.
        l = start_line + (k - 1)

        line_active_match = _line_active_match(
            active_match_location, l, active_match - num_matches
        )

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

        visual_line_background = if isnothing(visual_line_backgrounds_by_line)
            nothing
        else
            get(visual_line_backgrounds_by_line, l, nothing)
        end

        if !isnothing(visual_line_background)
            is_visual_line = true
        else
            is_visual_line = false
            visual_line_background = ""
        end

        cropped_chars_in_line = _draw_source_line_view!(
            buf,
            source,
            l,
            line_search_matches,
            line_active_match,
            highlight,
            active_highlight,
            start_column,
            num_columns,
            frozen_columns_at_beginning,
            is_visual_line,
            visual_line_background,
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

"""
    _source_length(source::RawTextViewSource) -> Int

Return the number of raw lines in `source`.

# Arguments

- `source::RawTextViewSource`: Raw source to measure.
"""
_source_length(source::RawTextViewSource) = length(source.lines)

"""
    _source_length(source::PreparedTextViewSource) -> Int

Return the number of prepared lines in `source`.

# Arguments

- `source::PreparedTextViewSource`: Prepared source to measure.
"""
_source_length(source::PreparedTextViewSource) = length(source.layout.lines)

"""
    _source_decorations(source::RawTextViewSource, line_number::Int) -> String

Collect the ANSI decorations from one raw source line.

# Arguments

- `source::RawTextViewSource`: Raw source containing the line.
- `line_number::Int`: One-based line number.
"""
function _source_decorations(source::RawTextViewSource, line_number::Int)
    return get_decorations(source.lines[line_number])
end

"""
    _line_active_match(
        active_match_location::NTuple{2, Int},
        line_number::Int,
        global_line_active_match::Int
    ) -> Int

Resolve the active match index for `line_number`.

# Arguments

- `active_match_location::NTuple{2, Int}`: Explicit line and within-line match index.
- `line_number::Int`: Current one-based line number.
- `global_line_active_match::Int`: Match index computed from the global selection.
"""
function _line_active_match(
    active_match_location::NTuple{2, Int}, line_number::Int, global_line_active_match::Int
)
    if active_match_location != (0, 0)
        return active_match_location[1] == line_number ? active_match_location[2] : 0
    end

    return global_line_active_match
end

"""
    _draw_source_line_view!(
        buf::IO,
        source::RawTextViewSource,
        line_number::Int,
        args...
    ) -> Int

Draw one raw source line using the generic line renderer.

# Arguments

- `buf::IO`: Output buffer.
- `source::RawTextViewSource`: Raw source containing the line.
- `line_number::Int`: One-based line number.
- `args...`: Remaining line-rendering arguments.
"""
function _draw_source_line_view!(
    buf::IO, source::RawTextViewSource, line_number::Int, args...
)
    return _draw_line_view!(buf, source.lines[line_number], args...)
end

"""
    _draw_source_line_view!(
        buf::IO,
        source::PreparedTextViewSource,
        line_number::Int,
        args...
    ) -> Int

Draw one prepared source line using its fastest compatible renderer.

# Arguments

- `buf::IO`: Output buffer.
- `source::PreparedTextViewSource`: Prepared source containing the line.
- `line_number::Int`: One-based line number.
- `args...`: Remaining line-rendering arguments.
"""
function _draw_source_line_view!(
    buf::IO, source::PreparedTextViewSource, line_number::Int, args...
)
    layout = source.layout
    if layout.plain_ascii[line_number]
        return _draw_ascii_line_view!(buf, layout, line_number, args...)
    end

    if layout.ansi_fallback[line_number]
        return _draw_line_view!(buf, layout.lines[line_number], args...)
    end

    return _draw_indexed_line_view!(buf, layout, line_number, args...)
end

"""
    _draw_indexed_line_view!(
        buf::IO,
        layout::TextViewLayout,
        line_number::Int,
        line_search_matches::Union{Nothing, Vector{Tuple{Int, Int}}},
        line_active_match::Int,
        highlight::String,
        active_highlight::String,
        start_column::Int,
        num_columns::Int,
        frozen_columns_at_beginning::Int,
        visual_line::Bool = false,
        visual_line_background::String = ""
    ) -> Int

Draw one indexed prepared line and return its cropped printable width.

# Arguments

- `buf::IO`: Output buffer.
- `layout::TextViewLayout`: Prepared layout containing the line.
- `line_number::Int`: One-based line number.
- `line_search_matches::Union{Nothing, Vector{Tuple{Int, Int}}}`: Search matches.
- `line_active_match::Int`: Active match within the line.
- `highlight::String`: Regular-match decoration.
- `active_highlight::String`: Active-match decoration.
- `start_column::Int`: First printable viewport column.
- `num_columns::Int`: Number of printable columns to draw.
- `frozen_columns_at_beginning::Int`: Number of frozen columns.
- `visual_line::Bool`: Whether to apply a visual background.
- `visual_line_background::String`: Visual background decoration.
"""
function _draw_indexed_line_view!(
    buf::IO,
    layout::TextViewLayout,
    line_number::Int,
    line_search_matches::Union{Nothing, Vector{Tuple{Int, Int}}},
    line_active_match::Int,
    highlight::String,
    active_highlight::String,
    start_column::Int,
    num_columns::Int,
    frozen_columns_at_beginning::Int,
    visual_line::Bool = false,
    visual_line_background::String = "",
)
    if frozen_columns_at_beginning > 0
        left, frozen_width = _prepared_line_segment(
            layout, line_number, 1, frozen_columns_at_beginning; preserve_end_state = false
        )

        if visual_line
            if frozen_width < frozen_columns_at_beginning
                left *= " "^(frozen_columns_at_beginning - frozen_width)
            end

            left = replace_default_background(left, visual_line_background)
        end

        if !isnothing(line_search_matches)
            left = highlight_search(
                left,
                line_search_matches;
                active_highlight,
                active_match = line_active_match,
                highlight,
                min_column = 1,
                max_column = frozen_columns_at_beginning,
                start_column = 1,
            )
        end

        write(buf, left, _RESET_DECORATIONS)
    end

    line_str, visible_width = _prepared_line_segment(
        layout, line_number, start_column, num_columns
    )

    available_width = max(layout.printable_widths[line_number] - start_column + 1, 0)

    if (num_columns ≥ 0) && visual_line && (visible_width < num_columns)
        line_str *= " "^(num_columns - visible_width)
    end

    cropped_chars = num_columns < 0 ? 0 : max(available_width - num_columns, 0)

    if visual_line && (num_columns ≥ 0)
        line_str = replace_default_background(line_str, visual_line_background)
    end

    if !isnothing(line_search_matches)
        line_str = highlight_search(
            line_str,
            line_search_matches;
            active_highlight,
            active_match = line_active_match,
            highlight,
            start_column,
            min_column = start_column,
            max_column = start_column + num_columns - 1,
        )
    end

    write(buf, line_str)

    return cropped_chars
end

"""
    _prepared_line_segment(
        layout::TextViewLayout,
        line_number::Int,
        start_column::Int,
        num_columns::Int;
        preserve_end_state::Bool = true
    ) -> Tuple{String, Int}

Extract a printable-width segment while preserving its ANSI state.

# Arguments

- `layout::TextViewLayout`: Prepared layout containing the line.
- `line_number::Int`: One-based line number.
- `start_column::Int`: First printable column to include.
- `num_columns::Int`: Number of printable columns to include.

# Keywords

- `preserve_end_state::Bool`: Append the state after the viewport when `true`.
    (**Default**: `true`)
"""
function _prepared_line_segment(
    layout::TextViewLayout,
    line_number::Int,
    start_column::Int,
    num_columns::Int;
    preserve_end_state::Bool = true,
)
    line = layout.lines[line_number]
    total_width = layout.printable_widths[line_number]
    start_size = max(start_column - 1, 0)
    start_seek = _prepared_seek(layout, line_number, start_size)
    start_byte = start_seek.byte_index
    start_padding = start_seek.right_padding
    available_width = max(total_width - start_size, 0)

    prefix = String(_ansi_summary_before(layout, line_number, start_byte))
    if num_columns < 0
        body = start_byte > ncodeunits(line) ? "" : String(SubString(line, start_byte))

        return string(prefix, " "^start_padding, body), available_width
    end

    end_seek = if num_columns == 0
        PreparedSeekResult(start_byte, start_byte, 0, 0, "")
    else
        _prepared_seek(
            layout, line_number, start_size + num_columns; right_boundary = false
        )
    end

    end_byte = end_seek.byte_index
    end_padding = end_seek.left_padding
    body = if start_byte ≥ end_byte
        ""
    else
        String(SubString(line, start_byte, prevind(line, end_byte)))
    end
    suffix = if preserve_end_state
        String(_ansi_summary_after(layout, line_number, end_seek.state_byte_index))
    else
        ""
    end

    width = min(num_columns, available_width)
    visible_start_padding = min(start_padding, num_columns)

    return (
        string(
            prefix,
            " "^visible_start_padding,
            body,
            " "^end_padding,
            end_seek.attached_ansi,
            suffix,
        ),
        width
    )
end

"""
    struct PreparedSeekResult

Store the byte boundary, padding, and ANSI data produced by a prepared seek.

# Fields

- `byte_index::Int`: Byte index selected for slicing.
- `state_byte_index::Int`: Byte index selected for ANSI state reconstruction.
- `left_padding::Int`: Spaces required to the left of a split wide character.
- `right_padding::Int`: Spaces required to the right of a split wide character.
- `attached_ansi::String`: ANSI events attached to the selected boundary.
"""
struct PreparedSeekResult
    byte_index::Int
    state_byte_index::Int
    left_padding::Int
    right_padding::Int
    attached_ansi::String
end

"""
    _prepared_seek(
        layout::TextViewLayout,
        line_number::Int,
        size::Int;
        right_boundary::Bool = true
    ) -> PreparedSeekResult

Seek `size` printable columns into a prepared line from a sparse checkpoint.

# Arguments

- `layout::TextViewLayout`: Prepared layout containing the line.
- `line_number::Int`: One-based line number.
- `size::Int`: Printable width to seek.

# Keywords

- `right_boundary::Bool`: Assign a split wide character to the right side when `true`.
    (**Default**: `true`)
"""
function _prepared_seek(
    layout::TextViewLayout, line_number::Int, size::Int; right_boundary::Bool = true
)
    checkpoints = layout.seek_checkpoints[line_number]
    checkpoint_column = 0
    checkpoint_byte = 1
    low = 1
    high = length(checkpoints)

    # Locate the last sparse checkpoint not beyond the requested printable column.
    while low ≤ high
        middle = (low + high) >>> 1
        checkpoint = checkpoints[middle]
        if checkpoint.column ≤ size
            checkpoint_column = checkpoint.column
            checkpoint_byte = checkpoint.byte_index
            low = middle + 1
        else
            high = middle - 1
        end
    end

    return _prepared_seek_from(
        layout, line_number, checkpoint_byte, size - checkpoint_column; right_boundary
    )
end

"""
    _prepared_seek_from(
        layout::TextViewLayout,
        line_number::Int,
        byte_index::Int,
        size::Int;
        right_boundary::Bool = true
    ) -> PreparedSeekResult

Seek a printable width from a known byte checkpoint.

# Arguments

- `layout::TextViewLayout`: Prepared layout containing the line.
- `line_number::Int`: One-based line number.
- `byte_index::Int`: Byte index at which to begin scanning.
- `size::Int`: Remaining printable width to seek.

# Keywords

- `right_boundary::Bool`: Assign a split wide character to the right side when `true`.
    (**Default**: `true`)
"""
function _prepared_seek_from(
    layout::TextViewLayout,
    line_number::Int,
    byte_index::Int,
    size::Int;
    right_boundary::Bool = true,
)
    line = layout.lines[line_number]
    events = layout.ansi_events[line_number]
    event_number = _first_event_at_or_after(events, byte_index)
    remaining = size
    i = byte_index

    # Scan printable widths, skipping zero-width ANSI events at each byte boundary.
    while i ≤ ncodeunits(line)
        if (event_number ≤ length(events)) && (events[event_number].byte_start == i)
            i = events[event_number].byte_end + 1
            event_number += 1
            continue
        end

        remaining ≤ 0 && return PreparedSeekResult(i, i, 0, 0, "")
        character_byte = i
        c = line[i]
        character_width = textwidth(c)
        remaining -= character_width
        i = nextind(line, i)

        if remaining < 0
            # Replace the hidden portion of a split wide character with viewport padding.
            ansi_begin = i

            # Keep ANSI events attached immediately after the split character boundary.
            while (event_number ≤ length(events)) && (events[event_number].byte_start == i)
                i = events[event_number].byte_end + 1
                event_number += 1
            end

            if right_boundary

                return PreparedSeekResult(
                    i, i, -remaining, character_width + remaining, ""
                )
            end

            attached_ansi =
                ansi_begin == i ? "" : String(SubString(line, ansi_begin, prevind(line, i)))

            return PreparedSeekResult(
                character_byte, i, -remaining, character_width + remaining, attached_ansi
            )
        end
    end

    end_byte = ncodeunits(line) + 1

    return PreparedSeekResult(end_byte, end_byte, 0, 0, "")
end

"""
    _first_event_at_or_after(
        events::Vector{TextAnsiEvent},
        byte_index::Int
    ) -> Int

Find the first ANSI event whose start is not before `byte_index`.

# Arguments

- `events::Vector{TextAnsiEvent}`: Byte-ordered ANSI events.
- `byte_index::Int`: Byte boundary to locate.
"""
function _first_event_at_or_after(events::Vector{TextAnsiEvent}, byte_index::Int)
    low = 1
    high = length(events)

    while low ≤ high
        middle = (low + high) >>> 1
        if events[middle].byte_start < byte_index
            low = middle + 1
        else
            high = middle - 1
        end
    end

    return low
end

"""
    _ansi_summary_before(
        layout::TextViewLayout,
        line_number::Int,
        byte_index::Int
    ) -> Decoration

Reconstruct the ANSI state immediately before a viewport boundary.

# Arguments

- `layout::TextViewLayout`: Prepared layout containing the line.
- `line_number::Int`: One-based line number.
- `byte_index::Int`: Viewport start byte index.
"""
function _ansi_summary_before(layout::TextViewLayout, line_number::Int, byte_index::Int)
    events = layout.ansi_events[line_number]
    event_count = _first_event_at_or_after(events, byte_index) - 1
    stride = layout.ansi_checkpoint_stride
    full_blocks = event_count ÷ stride

    # Restore the nearest prefix state, then replay only its trailing local events.
    state =
        full_blocks == 0 ? Decoration() :
        layout.ansi_prefix_checkpoints[line_number][full_blocks]
    for event_number in (full_blocks * stride + 1):event_count
        state = update_decoration(state, events[event_number].code)
    end

    return state
end

"""
    _ansi_summary_after(
        layout::TextViewLayout,
        line_number::Int,
        byte_index::Int
    ) -> Decoration

Reconstruct the ANSI state produced after a viewport boundary.

# Arguments

- `layout::TextViewLayout`: Prepared layout containing the line.
- `line_number::Int`: One-based line number.
- `byte_index::Int`: Viewport end byte index.
"""
function _ansi_summary_after(layout::TextViewLayout, line_number::Int, byte_index::Int)
    events = layout.ansi_events[line_number]
    first_event = _first_event_at_or_after(events, byte_index)
    first_event > length(events) && return Decoration()
    stride = layout.ansi_checkpoint_stride
    next_block = cld(first_event, stride) + 1
    last_local_event = min((next_block - 1) * stride, length(events))
    state = Decoration()

    # Replay through the next block boundary, then apply its cached suffix transition.
    for event_number in first_event:last_local_event
        state = update_decoration(state, events[event_number].code)
    end

    suffix = layout.ansi_suffix_checkpoints[line_number]

    if next_block ≤ length(suffix)
        state = _apply_ansi_transition(state, suffix[next_block])
    end

    return state
end

"""
    _draw_ascii_line_view!(
        buf::IO,
        layout::TextViewLayout,
        line_number::Int,
        line_search_matches::Union{Nothing, Vector{Tuple{Int, Int}}},
        line_active_match::Int,
        highlight::String,
        active_highlight::String,
        start_column::Int,
        num_columns::Int,
        frozen_columns_at_beginning::Int,
        visual_line::Bool = false,
        visual_line_background::String = ""
    ) -> Int

Draw one plain ASCII prepared line and return its cropped width.

# Arguments

- `buf::IO`: Output buffer.
- `layout::TextViewLayout`: Prepared layout containing the line.
- `line_number::Int`: One-based line number.
- `line_search_matches::Union{Nothing, Vector{Tuple{Int, Int}}}`: Search matches.
- `line_active_match::Int`: Active match within the line.
- `highlight::String`: Regular-match decoration.
- `active_highlight::String`: Active-match decoration.
- `start_column::Int`: First viewport column.
- `num_columns::Int`: Number of columns to draw.
- `frozen_columns_at_beginning::Int`: Number of frozen columns.
- `visual_line::Bool`: Whether to apply a visual background.
- `visual_line_background::String`: Visual background decoration.
"""
function _draw_ascii_line_view!(
    buf::IO,
    layout::TextViewLayout,
    line_number::Int,
    line_search_matches::Union{Nothing, Vector{Tuple{Int, Int}}},
    line_active_match::Int,
    highlight::String,
    active_highlight::String,
    start_column::Int,
    num_columns::Int,
    frozen_columns_at_beginning::Int,
    visual_line::Bool = false,
    visual_line_background::String = "",
)
    line = layout.lines[line_number]
    width = layout.printable_widths[line_number]

    if frozen_columns_at_beginning > 0
        frozen_width = min(frozen_columns_at_beginning, width)
        left = frozen_width == 0 ? "" : String(SubString(line, 1, frozen_width))

        if visual_line
            if frozen_width < frozen_columns_at_beginning
                left *= " "^(frozen_columns_at_beginning - frozen_width)
            end
            left = replace_default_background(left, visual_line_background)
        end

        if !isnothing(line_search_matches)
            left = highlight_search(
                left,
                line_search_matches;
                active_highlight,
                active_match = line_active_match,
                highlight,
                min_column = 1,
                max_column = frozen_columns_at_beginning,
                start_column = 1,
            )
        end

        write(buf, left, _RESET_DECORATIONS)
    end

    first_visible = min(start_column, width + 1)
    available_width = max(width - first_visible + 1, 0)
    visible_width = num_columns < 0 ? available_width : min(num_columns, available_width)
    line_str = if visible_width == 0
        ""
    else
        String(SubString(line, first_visible, first_visible + visible_width - 1))
    end

    if (num_columns ≥ 0) && visual_line && (visible_width < num_columns)
        line_str *= " "^(num_columns - visible_width)
    end

    cropped_chars = num_columns < 0 ? 0 : max(available_width - num_columns, 0)

    if visual_line && (num_columns ≥ 0)
        line_str = replace_default_background(line_str, visual_line_background)
    end

    if !isnothing(line_search_matches)
        line_str = highlight_search(
            line_str,
            line_search_matches;
            active_highlight,
            active_match = line_active_match,
            highlight,
            start_column,
            min_column = start_column,
            max_column = start_column + num_columns - 1,
        )
    end

    write(buf, line_str)

    return cropped_chars
end

"""
    _draw_line_view!(
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

Draw a line view to the provided IO buffer `buf` with syntax highlighting and search match
indicators.

# Arguments
- `buf::IO`: The output buffer to write the formatted line view to.
- `line::AbstractString`: The line content to be displayed.
- `line_search_matches::Union{Nothing, Vector{Tuple{Int, Int}}}`: Vector of tuples
    indicating the start and length of search matches, or `nothing` if there are no matches.
- `line_active_match::Int`: Index of the currently active/selected match to highlight
    differently.
- `highlight::String`: ANSI color code string for regular search match highlighting.
- `active_highlight::String`: ANSI color code string for the active match highlighting.
- `start_column::Int`: The column index where the view should begin (for horizontal
    scrolling).
- `num_columns::Int`: The number of columns to display in the view.
- `frozen_columns_at_beginning::Int`: Number of columns to keep frozen/always visible at the
    start.
- `visual_line::Bool`: Whether to apply visual line mode styling.
    (**Default**: `false`)
- `visual_line_background::String`: ANSI color code for visual line background.
    (**Default**: `""`)
"""
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
    visual_line_background::String = "",
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

        # If we have matches, we should highlight those in the frozen columns.
        if !isnothing(line_search_matches)
            left = highlight_search(
                left,
                line_search_matches;
                active_highlight,
                active_match = line_active_match,
                highlight,
                min_column = 1,
                max_column = frozen_columns_at_beginning,
                start_column = 1,
            )
        end

        write(buf, left, _RESET_DECORATIONS)
    end

    left_ansi  = ""
    right_ansi = ""

    if start_column > 0
        # TODO: Can we improve this?
        # Maybe we can improve performance by creating a function that removes a certain
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
            max_column = start_column + num_columns - 1,
        )
    end

    write(buf, line_str)

    return cropped_chars
end
