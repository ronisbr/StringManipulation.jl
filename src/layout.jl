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
    struct TextAnsiEvent

Store a recognized zero-width ANSI event, its source offsets, and its parsed transition.

# Fields

- `column::Int`: Printable column preceding the event.
- `byte_start::UInt64`: First source byte index of the event.
- `byte_length::UInt32`: Number of source bytes in the event.
- `transition_index::Int32`: Index of the event's compact parsed transition.
"""
struct TextAnsiEvent
    column::Int
    byte_start::UInt64
    byte_length::UInt32
    transition_index::Int32
end

"""
    struct CompactAnsiTransition

Store parsed event state as packed flags and source-backed value ranges.

# Fields

- `flags::UInt16`: Packed transition-presence and transition-state flags.
- `decoration_states::UInt8`: Packed bold, italic, reversed, and underline states.
- `foreground_ref::UInt64`: Packed source range or fallback for the foreground value.
- `background_ref::UInt64`: Packed source range or fallback for the background value.
- `hyperlink_ref::UInt64`: Packed source range or fallback for the hyperlink URL.
"""
struct CompactAnsiTransition
    flags::UInt16
    decoration_states::UInt8
    foreground_ref::UInt64
    background_ref::UInt64
    hyperlink_ref::UInt64
end

"""
    struct TextLineMetadata

Store indexed metadata for one non-ASCII line. Use `nothing` for plain ASCII lines to avoid
allocating empty per-line metadata vectors.

# Fields

- `seek_checkpoints::Vector{TextSeekCheckpoint}`: Sparse printable-column checkpoints.
- `ansi_events::Vector{TextAnsiEvent}`: Recognized zero-width ANSI events.
- `ansi_transitions::Vector{CompactAnsiTransition}`: Interned compact transitions.
- `ansi_fallback_values::Vector{String}`: Values that cannot reference source bytes.
- `ansi_prefix_checkpoints::Vector{AnsiStateTransition}`: Cached prefix transitions.
- `ansi_suffix_checkpoints::Vector{AnsiStateTransition}`: Cached suffix transitions.
"""
struct TextLineMetadata
    seek_checkpoints::Vector{TextSeekCheckpoint}
    ansi_events::Vector{TextAnsiEvent}
    ansi_transitions::Vector{CompactAnsiTransition}
    ansi_fallback_values::Vector{String}
    ansi_prefix_checkpoints::Vector{AnsiStateTransition}
    ansi_suffix_checkpoints::Vector{AnsiStateTransition}
end

"""
    struct TextViewLayout <: AbstractVector{String}
    TextViewLayout(text::AbstractString; kwargs...) -> TextViewLayout
    TextViewLayout(input_lines::AbstractVector{<:AbstractString}; kwargs...) -> TextViewLayout

Represent text prepared for repeated viewport rendering with [`textview`](@ref).

The layout owns canonical `String` lines, cached printable widths, and sparse Unicode
and ANSI checkpoints. Search matches and visual overlays are intentionally not cached and
remain dynamic. Construction performs one-time linear preprocessing and retains metadata
proportional to lines, Unicode scalars at the configured stride, and recognized ANSI events.

The representation is private. A layout owns its source and is an immutable snapshot. It
provides a read-only `AbstractVector{String}` interface for indexing and iteration. Use
`collect(layout)` when a mutable copy of its lines is required.

# Fields

- `_lines::Vector{String}`: Owned canonical text lines.
- `_printable_widths::Vector{Int}`: Printable width of each line.
- `_plain_ascii::BitVector`: Whether each line contains only plain ASCII text.
- `_ansi_fallback::BitVector`: Whether each line requires generic ANSI parsing.
- `_metadata::Vector{Union{Nothing, TextLineMetadata}}`: Optional indexed line metadata.
- `_document_ansi_checkpoints::Vector{Decoration}`: ANSI state after each complete line.
- `_checkpoint_stride::Int`: Unicode seek-checkpoint stride.
- `_ansi_checkpoint_stride::Int`: ANSI event-checkpoint stride.

# Arguments

- `text::AbstractString`: Text to split into owned canonical lines.
- `input_lines::AbstractVector{<:AbstractString}`: Lines to copy into owned storage.

# Keywords

- `checkpoint_stride::Int`: Set the Unicode seek-checkpoint stride.
    (**Default**: 256)
- `ansi_checkpoint_stride::Int`: Set the ANSI event-checkpoint stride.
    (**Default**: 32)

# Returns

- `TextViewLayout`: Owned immutable snapshot with a read-only vector interface.
"""
struct TextViewLayout <: AbstractVector{String}
    _lines::Vector{String}
    _printable_widths::Vector{Int}
    _plain_ascii::BitVector
    _ansi_fallback::BitVector
    _metadata::Vector{Union{Nothing, TextLineMetadata}}
    _document_ansi_checkpoints::Vector{Decoration}
    _checkpoint_stride::Int
    _ansi_checkpoint_stride::Int

    """
        TextViewLayout(text::AbstractString; kwargs...) -> TextViewLayout

    Prepare an owned immutable layout from newline-delimited `text`.

    # Arguments

    - `text::AbstractString`: Text to split into owned canonical lines.

    # Keywords

    - `checkpoint_stride::Int`: Set the Unicode seek-checkpoint stride.
        (**Default**: 256)
    - `ansi_checkpoint_stride::Int`: Set the ANSI event-checkpoint stride.
        (**Default**: 32)

    # Returns

    - `TextViewLayout`: Prepared owned snapshot of `text`.
    """
    function TextViewLayout(
        text::AbstractString; checkpoint_stride::Int = 256, ansi_checkpoint_stride::Int = 32
    )
        return TextViewLayout(split(text, '\n'); checkpoint_stride, ansi_checkpoint_stride)
    end

    """
        TextViewLayout(
            input_lines::AbstractVector{<:AbstractString};
            kwargs...
        ) -> TextViewLayout

    Prepare an owned immutable layout from `input_lines`.

    # Arguments

    - `input_lines::AbstractVector{<:AbstractString}`: Lines to copy into owned storage.

    # Keywords

    - `checkpoint_stride::Int`: Set the Unicode seek-checkpoint stride.
        (**Default**: 256)
    - `ansi_checkpoint_stride::Int`: Set the ANSI event-checkpoint stride.
        (**Default**: 32)

    # Returns

    - `TextViewLayout`: Prepared owned snapshot of `input_lines`.
    """
    function TextViewLayout(
        input_lines::AbstractVector{<:AbstractString};
        checkpoint_stride::Int = 256,
        ansi_checkpoint_stride::Int = 32,
    )
        components = _prepare_text_view_layout(
            input_lines; checkpoint_stride, ansi_checkpoint_stride
        )

        return new(
            components.lines,
            components.printable_widths,
            components.plain_ascii,
            components.ansi_fallback,
            components.metadata,
            components.document_ansi_checkpoints,
            checkpoint_stride,
            ansi_checkpoint_stride,
        )
    end
end

"""
    Base.IndexStyle(::Type{TextViewLayout}) -> IndexLinear

Return linear indexing for [`TextViewLayout`](@ref).

# Returns

- `IndexLinear`: Linear array-indexing style.
"""
Base.IndexStyle(::Type{TextViewLayout}) = IndexLinear()

"""
    Base.size(layout::TextViewLayout) -> Tuple{Int}

Return the one-dimensional size of `layout`.

# Arguments

- `layout::TextViewLayout`: Layout to measure.

# Returns

- `Tuple{Int}`: One-element tuple containing the number of lines.
"""
Base.size(layout::TextViewLayout) = (length(layout._lines),)

"""
    Base.getindex(layout::TextViewLayout, index::Int) -> String

Return the canonical line at `index`.

# Arguments

- `layout::TextViewLayout`: Layout containing the line.
- `index::Int`: Linear line index.

# Returns

- `String`: Canonical line at `index`.
"""
Base.getindex(layout::TextViewLayout, index::Int) = layout._lines[index]

"""
    _prepare_text_view_layout(
        input_lines::AbstractVector{<:AbstractString};
        kwargs...
    ) -> NamedTuple

Prepare owned source lines for an inner [`TextViewLayout`](@ref) constructor.

# Arguments

- `input_lines::AbstractVector{<:AbstractString}`: Source lines to copy and index.

# Keywords

- `checkpoint_stride::Int`: Set the Unicode seek-checkpoint stride.
    (**Default**: 256)
- `ansi_checkpoint_stride::Int`: Set the ANSI event-checkpoint stride.
    (**Default**: 32)

# Returns

- `NamedTuple`: Owned lines and all derived layout metadata.
"""
function _prepare_text_view_layout(
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
    metadata = Vector{Union{Nothing, TextLineMetadata}}(nothing, num_lines)
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

        line_metadata = TextLineMetadata(
            TextSeekCheckpoint[],
            TextAnsiEvent[],
            CompactAnsiTransition[],
            String[],
            AnsiStateTransition[],
            AnsiStateTransition[],
        )
        metadata[line_number] = line_metadata
        events = line_metadata.ansi_events
        transition_indices = Dict{AnsiStateTransition, Int32}()

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
                transition = _ansi_transition(code)
                compact_transition = _compact_ansi_transition(
                    transition, code, i, line_metadata.ansi_fallback_values
                )
                transition_index = get(transition_indices, transition, Int32(0))
                if iszero(transition_index)
                    push!(line_metadata.ansi_transitions, compact_transition)
                    transition_index = Int32(length(line_metadata.ansi_transitions))
                    transition_indices[transition] = transition_index
                end
                event_length = event_end - i + 1
                event_length ≤ typemax(UInt32) ||
                    throw(ArgumentError("ANSI event is too large."))
                push!(
                    events,
                    TextAnsiEvent(
                        column, UInt64(i), UInt32(event_length), transition_index
                    ),
                )
                i = event_end + 1
                if length(events) % ansi_checkpoint_stride == 0
                    checkpoint_byte =
                        has_zero_width_since_boundary ? column_boundary_byte : i
                    push!(
                        line_metadata.seek_checkpoints,
                        TextSeekCheckpoint(column, checkpoint_byte),
                    )
                end
                continue
            end

            c = line[i]
            if (column ≥ next_checkpoint) || (scalar_count ≥ next_scalar_checkpoint)
                push!(
                    line_metadata.seek_checkpoints,
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
        prefix = line_metadata.ansi_prefix_checkpoints
        prefix_transition = _empty_ansi_transition()

        for (event_number, event) in enumerate(events)
            prefix_transition = _compose_ansi_transitions(
                prefix_transition, _event_transition(line, line_metadata, event)
            )
            if event_number % ansi_checkpoint_stride == 0
                push!(prefix, prefix_transition)
            end
        end

        # Summarize each suffix from its corresponding ANSI block to the line end.
        suffix = line_metadata.ansi_suffix_checkpoints
        num_blocks = cld(length(events), ansi_checkpoint_stride)
        resize!(suffix, num_blocks)
        suffix_transition = _empty_ansi_transition()

        for block in num_blocks:-1:1
            first_event = (block - 1) * ansi_checkpoint_stride + 1
            last_event = min(block * ansi_checkpoint_stride, length(events))
            block_transition = _empty_ansi_transition()

            for event_number in first_event:last_event
                block_transition = _compose_ansi_transitions(
                    block_transition,
                    _event_transition(line, line_metadata, events[event_number]),
                )
            end

            suffix_transition = _compose_ansi_transitions(
                block_transition, suffix_transition
            )
            suffix[block] = suffix_transition
        end

        for event in events
            document_state = _apply_ansi_transition(
                document_state, _event_transition(line, line_metadata, event)
            )
        end

        push!(document_ansi_checkpoints, document_state)
    end

    return (;
        lines,
        printable_widths,
        plain_ascii,
        ansi_fallback,
        metadata,
        document_ansi_checkpoints,
    )
end

############################################################################################
#                                    Private Functions                                     #
############################################################################################

const _ANSI_CLEAR_SGR = UInt16(1) << 0
const _ANSI_HAS_SGR = UInt16(1) << 1
const _ANSI_FINAL_RESET = UInt16(1) << 2
const _ANSI_FOREGROUND_CHANGED = UInt16(1) << 3
const _ANSI_BACKGROUND_CHANGED = UInt16(1) << 4
const _ANSI_BOLD_CHANGED = UInt16(1) << 5
const _ANSI_ITALIC_CHANGED = UInt16(1) << 6
const _ANSI_REVERSED_CHANGED = UInt16(1) << 7
const _ANSI_UNDERLINE_CHANGED = UInt16(1) << 8
const _ANSI_HYPERLINK_CHANGED = UInt16(1) << 9
const _ANSI_FALLBACK_REF = typemax(UInt32)

"""
    _event_transition(
        line::String,
        metadata::TextLineMetadata,
        event::TextAnsiEvent
    ) -> AnsiStateTransition

Return the interned transition referenced by `event`.

# Arguments

- `line::String`: Owned source line containing the event values.
- `metadata::TextLineMetadata`: Indexed metadata containing compact transitions.
- `event::TextAnsiEvent`: Event that references the requested transition.

# Returns

- `AnsiStateTransition`: Materialized transition for `event`.
"""
function _event_transition(line::String, metadata::TextLineMetadata, event::TextAnsiEvent)
    transition = metadata.ansi_transitions[Int(event.transition_index)]
    flags = transition.flags
    states = transition.decoration_states

    return AnsiStateTransition(
        !iszero(flags & _ANSI_CLEAR_SGR),
        !iszero(flags & _ANSI_HAS_SGR),
        !iszero(flags & _ANSI_FINAL_RESET),
        !iszero(flags & _ANSI_FOREGROUND_CHANGED),
        _ansi_source_value(line, metadata.ansi_fallback_values, transition.foreground_ref),
        !iszero(flags & _ANSI_BACKGROUND_CHANGED),
        _ansi_source_value(line, metadata.ansi_fallback_values, transition.background_ref),
        !iszero(flags & _ANSI_BOLD_CHANGED),
        DecorationState(states & 0x03),
        !iszero(flags & _ANSI_ITALIC_CHANGED),
        DecorationState((states >> 2) & 0x03),
        !iszero(flags & _ANSI_REVERSED_CHANGED),
        DecorationState((states >> 4) & 0x03),
        !iszero(flags & _ANSI_UNDERLINE_CHANGED),
        DecorationState((states >> 6) & 0x03),
        !iszero(flags & _ANSI_HYPERLINK_CHANGED),
        _ansi_source_value(line, metadata.ansi_fallback_values, transition.hyperlink_ref),
    )
end

"""
    _compact_ansi_transition(
        transition::AnsiStateTransition,
        code::String,
        byte_start::Int,
        fallback_values::Vector{String}
    ) -> CompactAnsiTransition

Pack a parsed transition using source offsets for variable string values.

# Arguments

- `transition::AnsiStateTransition`: Parsed transition to pack.
- `code::String`: Source ANSI code represented by the transition.
- `byte_start::Int`: First byte index of `code` in its source line.
- `fallback_values::Vector{String}`: Storage for values that cannot reference source bytes.

# Returns

- `CompactAnsiTransition`: Packed source-backed transition.
"""
function _compact_ansi_transition(
    transition::AnsiStateTransition,
    code::String,
    byte_start::Int,
    fallback_values::Vector{String},
)
    flags = UInt16(0)
    transition.clear_sgr && (flags |= _ANSI_CLEAR_SGR)
    transition.has_sgr && (flags |= _ANSI_HAS_SGR)
    transition.final_reset && (flags |= _ANSI_FINAL_RESET)
    transition.foreground_changed && (flags |= _ANSI_FOREGROUND_CHANGED)
    transition.background_changed && (flags |= _ANSI_BACKGROUND_CHANGED)
    transition.bold_changed && (flags |= _ANSI_BOLD_CHANGED)
    transition.italic_changed && (flags |= _ANSI_ITALIC_CHANGED)
    transition.reversed_changed && (flags |= _ANSI_REVERSED_CHANGED)
    transition.underline_changed && (flags |= _ANSI_UNDERLINE_CHANGED)
    transition.hyperlink_changed && (flags |= _ANSI_HYPERLINK_CHANGED)

    states =
        UInt8(transition.bold) |
        (UInt8(transition.italic) << 2) |
        (UInt8(transition.reversed) << 4) |
        (UInt8(transition.underline) << 6)

    return CompactAnsiTransition(
        flags,
        states,
        _ansi_source_ref(code, transition.foreground, byte_start, fallback_values),
        _ansi_source_ref(code, transition.background, byte_start, fallback_values),
        _ansi_source_ref(code, transition.hyperlink_url, byte_start, fallback_values),
    )
end

"""
    _ansi_source_ref(
        code::String,
        value::String,
        byte_start::Int,
        fallback_values::Vector{String}
    ) -> UInt64

Encode a source byte range for `value`. Retain a fallback only when normalization means that
the parsed value does not occur verbatim in the source event.

# Arguments

- `code::String`: Source ANSI code containing `value` when it can be referenced.
- `value::String`: Parsed value to reference or retain as a fallback.
- `byte_start::Int`: First byte index of `code` in its source line.
- `fallback_values::Vector{String}`: Storage for values without a source reference.

# Returns

- `UInt64`: Packed source range or fallback index.
"""
function _ansi_source_ref(
    code::String, value::String, byte_start::Int, fallback_values::Vector{String}
)
    isempty(value) && return UInt64(0)
    range = findfirst(value, code)

    if isnothing(range)
        push!(fallback_values, value)
        return (UInt64(_ANSI_FALLBACK_REF) << 32) | UInt64(length(fallback_values))
    end

    source_start = byte_start + first(range) - 1
    source_end = byte_start + last(range) - 1
    if source_end > typemax(UInt32)
        push!(fallback_values, value)
        return (UInt64(_ANSI_FALLBACK_REF) << 32) | UInt64(length(fallback_values))
    end

    return (UInt64(source_start) << 32) | UInt64(source_end)
end

"""
    _ansi_source_value(
        line::String,
        fallback_values::Vector{String},
        reference::UInt64
    ) -> String

Materialize a parsed value from its owned source line or uncommon normalized fallback.

# Arguments

- `line::String`: Owned source line containing source-backed values.
- `fallback_values::Vector{String}`: Retained normalized fallback values.
- `reference::UInt64`: Packed source range or fallback index.

# Returns

- `String`: Materialized parsed value.
"""
function _ansi_source_value(
    line::String, fallback_values::Vector{String}, reference::UInt64
)
    iszero(reference) && return ""
    source_start = UInt32(reference >> 32)
    source_end = UInt32(reference & typemax(UInt32))

    if source_start == _ANSI_FALLBACK_REF
        return fallback_values[Int(source_end)]
    end

    return String(SubString(line, Int(source_start), Int(source_end)))
end

"""
    _empty_ansi_transition() -> AnsiStateTransition

Create an ANSI transition that leaves every decoration unchanged.

# Returns

- `AnsiStateTransition`: Transition that preserves every decoration field.
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
    _ansi_transition_string(transition::AnsiStateTransition) -> String

Render a transition canonically while retaining a reset that precedes later overrides.

# Arguments

- `transition::AnsiStateTransition`: Transition to render.

# Returns

- `String`: Canonical ANSI sequence for `transition`.
"""
function _ansi_transition_string(transition::AnsiStateTransition)
    decoration = Decoration(
        transition.foreground_changed ? transition.foreground : "",
        transition.background_changed ? transition.background : "",
        transition.bold_changed ? transition.bold : unchanged,
        transition.italic_changed ? transition.italic : unchanged,
        transition.reversed_changed ? transition.reversed : unchanged,
        transition.underline_changed ? transition.underline : unchanged,
        false,
        transition.hyperlink_changed ? transition.hyperlink_url : "",
        transition.hyperlink_changed,
    )
    reset = transition.clear_sgr ? "\e[0m" : ""

    return string(reset, String(decoration))
end

"""
    _ansi_transition(code::String) -> AnsiStateTransition

Summarize the decoration changes produced by ANSI sequence `code`.

# Arguments

- `code::String`: ANSI sequence to summarize.

# Returns

- `AnsiStateTransition`: Parsed state changes produced by `code`.
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

# Returns

- `Decoration`: Decoration state after applying `transition`.
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

# Returns

- `AnsiStateTransition`: Transition equivalent to applying `first` and then `second`.
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
