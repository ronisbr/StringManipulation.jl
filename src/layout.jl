## Description #############################################################################
#
# Prepared, indexed text layouts used by `textview`.
#
############################################################################################

export TextViewLayout

############################################################################################
#                                   Types and Structures                                   #
############################################################################################

"""
    struct TextSeekCheckpoint

Store a sparse position for seeking by printable column.

# Fields

- `column::Int`: Printable column at the checkpoint.
- `byte_index::Int`: String byte index at the checkpoint.
"""
struct TextSeekCheckpoint
    column::Int
    byte_index::Int
end

"""
    struct TextAnsiEvent

Store a recognized zero-width ANSI event and its position.

# Fields

- `column::Int`: Printable column preceding the event.
- `byte_start::Int`: First byte index of the event.
- `byte_end::Int`: Last byte index of the event.
- `code::String`: ANSI escape sequence.
"""
struct TextAnsiEvent
    column::Int
    byte_start::Int
    byte_end::Int
    code::String
end

"""
    struct AnsiStateTransition

Summarize how a sequence of ANSI events changes a decoration state.

# Fields

- `clear_sgr::Bool`: Whether the transition clears prior SGR attributes.
- `has_sgr::Bool`: Whether the transition contains an SGR event.
- `final_reset::Bool`: Reset state of the final SGR event.
- `foreground_changed::Bool`: Whether the foreground is overridden.
- `foreground::String`: Final foreground value.
- `background_changed::Bool`: Whether the background is overridden.
- `background::String`: Final background value.
- `bold_changed::Bool`: Whether the bold state is overridden.
- `bold::DecorationState`: Final bold state.
- `italic_changed::Bool`: Whether the italic state is overridden.
- `italic::DecorationState`: Final italic state.
- `reversed_changed::Bool`: Whether the reversed state is overridden.
- `reversed::DecorationState`: Final reversed state.
- `underline_changed::Bool`: Whether the underline state is overridden.
- `underline::DecorationState`: Final underline state.
- `hyperlink_changed::Bool`: Whether the hyperlink is overridden.
- `hyperlink_url::String`: Final hyperlink URL.
"""
struct AnsiStateTransition
    clear_sgr::Bool
    has_sgr::Bool
    final_reset::Bool
    foreground_changed::Bool
    foreground::String
    background_changed::Bool
    background::String
    bold_changed::Bool
    bold::DecorationState
    italic_changed::Bool
    italic::DecorationState
    reversed_changed::Bool
    reversed::DecorationState
    underline_changed::Bool
    underline::DecorationState
    hyperlink_changed::Bool
    hyperlink_url::String
end

"""
    struct TextViewLayout

Prepared representation of text for repeated viewport rendering with [`textview`](@ref).

The layout owns canonical `String` lines, cached printable widths, and sparse Unicode
and ANSI checkpoints. Search matches and visual overlays are intentionally not cached and
remain dynamic. Constructing a layout scans the input once and retains metadata proportional
to lines, Unicode scalars at the configured stride, and recognized ANSI events.

# Fields

- `lines::Vector{String}`: Canonical text lines.
- `printable_widths::Vector{Int}`: Printable width of each line.
- `plain_ascii::BitVector`: Whether each line contains only plain ASCII text.
- `ansi_fallback::BitVector`: Whether each line requires generic ANSI parsing.
- `seek_checkpoints::Vector{Vector{TextSeekCheckpoint}}`: Sparse Unicode seek checkpoints.
- `ansi_events::Vector{Vector{TextAnsiEvent}}`: Recognized ANSI events for each line.
- `ansi_prefix_checkpoints::Vector{Vector{Decoration}}`: Cached ANSI prefix states.
- `ansi_suffix_checkpoints::Vector{Vector{AnsiStateTransition}}`: Cached ANSI suffix states.
- `document_ansi_checkpoints::Vector{Decoration}`: ANSI state after each complete line.
- `checkpoint_stride::Int`: Unicode seek checkpoint stride.
- `ansi_checkpoint_stride::Int`: ANSI event checkpoint stride.
"""
struct TextViewLayout
    lines::Vector{String}
    printable_widths::Vector{Int}
    plain_ascii::BitVector
    ansi_fallback::BitVector
    seek_checkpoints::Vector{Vector{TextSeekCheckpoint}}
    ansi_events::Vector{Vector{TextAnsiEvent}}
    ansi_prefix_checkpoints::Vector{Vector{Decoration}}
    ansi_suffix_checkpoints::Vector{Vector{AnsiStateTransition}}
    document_ansi_checkpoints::Vector{Decoration}
    checkpoint_stride::Int
    ansi_checkpoint_stride::Int
end

"""
    TextViewLayout(
        text::AbstractString;
        kwargs...
    ) -> TextViewLayout

Prepare the lines in `text` for repeated [`textview`](@ref) calls. `checkpoint_stride`
bounds local Unicode seek scans, whereas `ansi_checkpoint_stride` bounds recognized ANSI
event scans.

# Keywords

- `checkpoint_stride::Int`: Set the Unicode seek checkpoint stride.
    (**Default**: 256)
- `ansi_checkpoint_stride::Int`: Set the ANSI event checkpoint stride.
    (**Default**: 32)
"""
function TextViewLayout(
    text::AbstractString; checkpoint_stride::Int = 256, ansi_checkpoint_stride::Int = 32
)
    return TextViewLayout(split(text, '\n'); checkpoint_stride, ansi_checkpoint_stride)
end

"""
    TextViewLayout(
        lines::AbstractVector{<:AbstractString};
        kwargs...
    ) -> TextViewLayout

Prepare `lines` for repeated [`textview`](@ref) calls. Input strings are canonicalized into
an owned `Vector{String}`. Smaller strides use more retained memory in exchange for shorter
local viewport seek scans.

# Keywords

- `checkpoint_stride::Int`: Set the Unicode seek checkpoint stride.
    (**Default**: 256)
- `ansi_checkpoint_stride::Int`: Set the ANSI event checkpoint stride.
    (**Default**: 32)
"""
function TextViewLayout(
    input_lines::AbstractVector{<:AbstractString};
    checkpoint_stride::Int = 256,
    ansi_checkpoint_stride::Int = 32,
)
    checkpoint_stride > 0 || throw(ArgumentError("`checkpoint_stride` must be positive."))
    ansi_checkpoint_stride > 0 ||
        throw(ArgumentError("`ansi_checkpoint_stride` must be positive."))

    lines = String[string(line) for line in input_lines]
    num_lines = length(lines)
    printable_widths = Vector{Int}(undef, num_lines)
    plain_ascii = falses(num_lines)
    ansi_fallback = falses(num_lines)
    seek_checkpoints = [TextSeekCheckpoint[] for _ in 1:num_lines]
    ansi_events = [TextAnsiEvent[] for _ in 1:num_lines]
    ansi_prefix_checkpoints = [Decoration[] for _ in 1:num_lines]
    ansi_suffix_checkpoints = [AnsiStateTransition[] for _ in 1:num_lines]
    document_ansi_checkpoints = Decoration[]
    document_state = Decoration()

    for line_number in eachindex(lines)
        line = lines[line_number]
        is_plain_ascii = all(c -> (' ' ≤ c ≤ '~'), line)
        plain_ascii[line_number] = is_plain_ascii

        if is_plain_ascii
            printable_widths[line_number] = ncodeunits(line)
            push!(document_ansi_checkpoints, document_state)
            continue
        end

        events = ansi_events[line_number]

        # Recognize supported ANSI sequences before scanning Unicode printable widths.
        recognized_bytes = falses(ncodeunits(line))
        event_codes = Dict{Int, Tuple{Int, String}}()
        has_unrecognized_escape = false

        for m in eachmatch(_REGEX_ANSI_SEQUENCES, line)
            byte_start = m.offset
            byte_end = byte_start + ncodeunits(m.match) - 1
            recognized_bytes[byte_start:byte_end] .= true
            code = String(m.match)
            if !(
                startswith(code, "\e]8;;") ||
                (startswith(code, "\e[") && endswith(code, 'm'))
            )
                has_unrecognized_escape = true
            end

            event_codes[byte_start] = (byte_end, code)
        end

        for i in eachindex(codeunits(line))
            if (codeunit(line, i) == 0x1b) && !recognized_bytes[i]
                has_unrecognized_escape = true
                break
            end
        end

        ansi_fallback[line_number] = has_unrecognized_escape

        # Scan Unicode scalars while omitting recognized zero-width ANSI events.
        column = 0
        scalar_count = 0
        column_boundary_byte = firstindex(line)
        has_zero_width_since_boundary = false
        next_checkpoint = checkpoint_stride
        next_scalar_checkpoint = checkpoint_stride
        i = firstindex(line)

        while i ≤ ncodeunits(line)
            if haskey(event_codes, i)
                # Attach zero-width events to their current printable column.
                event_end, code = event_codes[i]
                push!(events, TextAnsiEvent(column, i, event_end, code))
                i = event_end + 1
                if length(events) % ansi_checkpoint_stride == 0
                    checkpoint_byte =
                        has_zero_width_since_boundary ? column_boundary_byte : i
                    push!(
                        seek_checkpoints[line_number],
                        TextSeekCheckpoint(column, checkpoint_byte),
                    )
                end
                continue
            end

            c = line[i]
            if (column ≥ next_checkpoint) || (scalar_count ≥ next_scalar_checkpoint)
                push!(
                    seek_checkpoints[line_number],
                    TextSeekCheckpoint(column, column_boundary_byte),
                )
                next_checkpoint = column + checkpoint_stride
                next_scalar_checkpoint = scalar_count + checkpoint_stride
            end
            character_width = textwidth(c)
            column += character_width
            scalar_count += 1
            i = nextind(line, i)
            if character_width > 0
                column_boundary_byte = i
                has_zero_width_since_boundary = false
            else
                has_zero_width_since_boundary = true
            end
        end
        printable_widths[line_number] = column

        # Cache the complete ANSI state after each full event block.
        prefix = ansi_prefix_checkpoints[line_number]
        state = Decoration()

        for (event_number, event) in enumerate(events)
            state = update_decoration(state, event.code)
            if event_number % ansi_checkpoint_stride == 0
                push!(prefix, state)
            end
        end

        # Summarize each suffix from its corresponding ANSI block to the line end.
        suffix = ansi_suffix_checkpoints[line_number]
        num_blocks = cld(length(events), ansi_checkpoint_stride)
        resize!(suffix, num_blocks)
        suffix_transition = _empty_ansi_transition()

        for block in num_blocks:-1:1
            first_event = (block - 1) * ansi_checkpoint_stride + 1
            last_event = min(block * ansi_checkpoint_stride, length(events))
            block_transition = _empty_ansi_transition()

            for event_number in first_event:last_event
                block_transition = _compose_ansi_transitions(
                    block_transition, _ansi_transition(events[event_number].code)
                )
            end

            suffix_transition = _compose_ansi_transitions(
                block_transition, suffix_transition
            )
            suffix[block] = suffix_transition
        end

        for event in events
            document_state = update_decoration(document_state, event.code)
        end

        push!(document_ansi_checkpoints, document_state)
    end

    return TextViewLayout(
        lines,
        printable_widths,
        plain_ascii,
        ansi_fallback,
        seek_checkpoints,
        ansi_events,
        ansi_prefix_checkpoints,
        ansi_suffix_checkpoints,
        document_ansi_checkpoints,
        checkpoint_stride,
        ansi_checkpoint_stride,
    )
end

############################################################################################
#                                    Private Functions                                     #
############################################################################################

"""
    _empty_ansi_transition() -> AnsiStateTransition

Create an ANSI transition that leaves every decoration unchanged.
"""
function _empty_ansi_transition()

    return AnsiStateTransition(
        false,
        false,
        false,
        false,
        "",
        false,
        "",
        false,
        unchanged,
        false,
        unchanged,
        false,
        unchanged,
        false,
        unchanged,
        false,
        "",
    )
end

"""
    _ansi_transition(code::String) -> AnsiStateTransition

Summarize the decoration changes produced by ANSI sequence `code`.

# Arguments

- `code::String`: ANSI sequence to summarize.
"""
function _ansi_transition(code::String)
    decoration = parse_decoration(code)
    is_sgr = startswith(code, "\e[") && endswith(code, 'm')
    clear_sgr = is_sgr && decoration.reset

    return AnsiStateTransition(
        clear_sgr,
        is_sgr,
        is_sgr && decoration.reset,
        is_sgr && !isempty(decoration.foreground),
        decoration.foreground,
        is_sgr && !isempty(decoration.background),
        decoration.background,
        is_sgr && (decoration.bold != unchanged),
        decoration.bold,
        is_sgr && (decoration.italic != unchanged),
        decoration.italic,
        is_sgr && (decoration.reversed != unchanged),
        decoration.reversed,
        is_sgr && (decoration.underline != unchanged),
        decoration.underline,
        decoration.hyperlink_url_changed,
        decoration.hyperlink_url,
    )
end

"""
    _apply_ansi_transition(
        decoration::Decoration,
        transition::AnsiStateTransition
    ) -> Decoration

Apply `transition` to `decoration` and return the resulting state.

# Arguments

- `decoration::Decoration`: Initial decoration state.
- `transition::AnsiStateTransition`: Summarized changes to apply.
"""
function _apply_ansi_transition(decoration::Decoration, transition::AnsiStateTransition)
    # A reset clears inherited SGR attributes before later overrides are applied.
    if transition.clear_sgr
        foreground = ""
        background = ""
        bold = unchanged
        italic = unchanged
        reversed = unchanged
        underline = unchanged
    else
        foreground = decoration.foreground
        background = decoration.background
        bold = decoration.bold
        italic = decoration.italic
        reversed = decoration.reversed
        underline = decoration.underline
    end

    transition.foreground_changed && (foreground = transition.foreground)
    transition.background_changed && (background = transition.background)
    transition.bold_changed && (bold = transition.bold)
    transition.italic_changed && (italic = transition.italic)
    transition.reversed_changed && (reversed = transition.reversed)
    transition.underline_changed && (underline = transition.underline)

    reset = transition.has_sgr ? transition.final_reset : decoration.reset
    hyperlink_url =
        transition.hyperlink_changed ? transition.hyperlink_url : decoration.hyperlink_url
    hyperlink_changed = transition.hyperlink_changed || decoration.hyperlink_url_changed

    return Decoration(
        foreground,
        background,
        bold,
        italic,
        reversed,
        underline,
        reset,
        hyperlink_url,
        hyperlink_changed,
    )
end

"""
    _compose_ansi_transitions(
        first::AnsiStateTransition,
        second::AnsiStateTransition
    ) -> AnsiStateTransition

Compose sequential transitions so that `second` is applied after `first`.

# Arguments

- `first::AnsiStateTransition`: Earlier transition.
- `second::AnsiStateTransition`: Later transition.
"""
function _compose_ansi_transitions(first::AnsiStateTransition, second::AnsiStateTransition)
    # Later resets discard earlier SGR overrides, while later fields override earlier ones.
    second_clears = second.clear_sgr

    return AnsiStateTransition(
        first.clear_sgr || second.clear_sgr,
        first.has_sgr || second.has_sgr,
        second.has_sgr ? second.final_reset : first.final_reset,
        second.foreground_changed || (!second_clears && first.foreground_changed),
        second.foreground_changed ? second.foreground : first.foreground,
        second.background_changed || (!second_clears && first.background_changed),
        second.background_changed ? second.background : first.background,
        second.bold_changed || (!second_clears && first.bold_changed),
        second.bold_changed ? second.bold : first.bold,
        second.italic_changed || (!second_clears && first.italic_changed),
        second.italic_changed ? second.italic : first.italic,
        second.reversed_changed || (!second_clears && first.reversed_changed),
        second.reversed_changed ? second.reversed : first.reversed,
        second.underline_changed || (!second_clears && first.underline_changed),
        second.underline_changed ? second.underline : first.underline,
        second.hyperlink_changed || first.hyperlink_changed,
        second.hyperlink_changed ? second.hyperlink_url : first.hyperlink_url,
    )
end
