## Description #############################################################################
#
# Definition of types and structures.
#
############################################################################################

export Decoration, TextViewLayout

# == Decorations ===========================================================================

"""
    @enum DecorationState

State of a decoration attribute: `inactive` if it is turned off, `active` if it is turned
on, and `unchanged` if it is not modified.
"""
@enum DecorationState begin
    inactive  = 0
    active    = 1
    unchanged = 2
end

"""
    struct Decoration

Structure to hold the current decoration of a string.

# Fields

- `foreground::String`: SGR parameters of the foreground color, like `"31"` or
    `"38;2;255;0;0"`, or an empty string if it is unchanged.
- `background::String`: SGR parameters of the background color, like `"44"` or `"48;5;201"`,
    or an empty string if it is unchanged.
- `bold::DecorationState`: State of the bold attribute.
- `faint::DecorationState`: State of the faint attribute.
- `italic::DecorationState`: State of the italic attribute.
- `reversed::DecorationState`: State of the reverse video attribute.
- `underline::DecorationState`: State of the underline attribute.
- `strikethrough::DecorationState`: State of the strikethrough attribute.
- `reset::Bool`: `true` if the decoration resets the previous attributes.
- `hyperlink_url::String`: URL of the hyperlink, or an empty string if there is none.
- `hyperlink_url_changed::Bool`: `true` if the decoration changes the hyperlink.
"""
@kwdef struct Decoration
    foreground::String             = ""
    background::String             = ""
    bold::DecorationState          = unchanged
    faint::DecorationState         = unchanged
    italic::DecorationState        = unchanged
    reversed::DecorationState      = unchanged
    underline::DecorationState     = unchanged
    strikethrough::DecorationState = unchanged
    reset::Bool                    = false
    hyperlink_url::String          = ""
    hyperlink_url_changed::Bool    = false
end

# == Text View Layout ======================================================================

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
- `faint_changed::Bool`: Whether the faint state is overridden.
- `faint::DecorationState`: Final faint state.
- `italic_changed::Bool`: Whether the italic state is overridden.
- `italic::DecorationState`: Final italic state.
- `reversed_changed::Bool`: Whether the reversed state is overridden.
- `reversed::DecorationState`: Final reversed state.
- `underline_changed::Bool`: Whether the underline state is overridden.
- `underline::DecorationState`: Final underline state.
- `strikethrough_changed::Bool`: Whether the strikethrough state is overridden.
- `strikethrough::DecorationState`: Final strikethrough state.
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
    faint_changed::Bool
    faint::DecorationState
    italic_changed::Bool
    italic::DecorationState
    reversed_changed::Bool
    reversed::DecorationState
    underline_changed::Bool
    underline::DecorationState
    strikethrough_changed::Bool
    strikethrough::DecorationState
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
- `decoration_states::UInt16`: Packed bold, faint, italic, reversed, underline, and
    strikethrough states, using two bits each in this order.
- `foreground_ref::UInt64`: Packed source range or fallback for the foreground value.
- `background_ref::UInt64`: Packed source range or fallback for the background value.
- `hyperlink_ref::UInt64`: Packed source range or fallback for the hyperlink URL.
"""
struct CompactAnsiTransition
    flags::UInt16
    decoration_states::UInt16
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
    TextViewLayout(
        input_lines::AbstractVector{<:AbstractString};
        kwargs...
    ) -> TextViewLayout

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

# == Text View =============================================================================

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
