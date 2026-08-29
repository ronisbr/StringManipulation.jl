## Description #############################################################################
#
# Conversion of the faces of StyledStrings.jl into decorations.
#
############################################################################################

############################################################################################
#                                        Constants                                         #
############################################################################################

# Weights of a face that are shown in bold, and the ones that are shown faint.
const _FACE_BOLD_WEIGHTS  = (:medium, :semibold, :bold, :extrabold, :black)
const _FACE_FAINT_WEIGHTS = (:semilight, :light, :extralight, :thin)

# Slants of a face that are shown in italics.
const _FACE_ITALIC_SLANTS = (:italic, :oblique)

# Colors of the terminal foreground and background, which a reset already selects. Their
# names depend on the version of StyledStrings.jl: `:default` selected both up to 1.12,
# whereas `:foreground` and `:background` select each of them since 1.13.
const _RENAMED_DEFAULT_COLORS = pkgversion(StyledStrings) >= v"1.13"
const _DEFAULT_FOREGROUND = SimpleColor(_RENAMED_DEFAULT_COLORS ? :foreground : :default)
const _DEFAULT_BACKGROUND = SimpleColor(_RENAMED_DEFAULT_COLORS ? :background : :default)

############################################################################################
#                                     Public Functions                                     #
############################################################################################

"""
    Decoration(face::Face; kwargs...) -> Decoration

Create the decoration that renders `face`, a face of **StyledStrings.jl**, in the terminal.

The colors follow the rules of **StyledStrings.jl**: a named color is written as one of the
16 terminal colors, a 24-bit color is written as such or approximated by the 256-color
palette if the terminal does not support true color, and a color that names another face
selects the foreground of that face. An attribute set to its default in `face`, like the
weight `:normal`, `false`, or the default color of the terminal, turns the attribute off,
whereas an attribute left unset (`nothing`) is left unchanged.

Notice that the underline color and style are not represented in a `Decoration`, so that
the text is shown with a plain underline, and that the `font` and the `height` of the face
are ignored because they have no effect in the terminal.

# Keywords

- `reset::Bool`: If `true`, the decoration resets the previous attributes before applying
    the ones in `face`. In this case, the attributes turned off are omitted because the
    reset already turned them off, and `String(Decoration(face))` is the escape sequence
    that shows text with exactly the attributes of `face`.
    (**Default**: `true`)

# Extended help

## Examples

```julia
julia> using StyledStrings

julia> String(Decoration(Face(; weight = :bold, foreground = :red)))
"\\e[0m\\e[31m\\e[1m"

julia> Decoration(Face(; background = :blue)).background
"44"

julia> String(Decoration(Face(; weight = :normal, underline = false); reset = false))
"\\e[22m\\e[24m"
```
"""
function Decoration(face::Face; reset::Bool = true)
    weight    = face.weight
    underline = face.underline

    bold          = _face_attribute_state(weight, _FACE_BOLD_WEIGHTS, reset)
    faint         = _face_attribute_state(weight, _FACE_FAINT_WEIGHTS, reset)
    italic        = _face_attribute_state(face.slant, _FACE_ITALIC_SLANTS, reset)
    reversed      = _face_attribute_state(face.inverse, reset)
    strikethrough = _face_attribute_state(face.strikethrough, reset)

    # The underline can also be a color or a tuple with a color and a style, both of which
    # turn the underline on.
    underline_on = isnothing(underline) ? nothing : (underline !== false)
    underline    = _face_attribute_state(underline_on, reset)

    foreground = _face_color_parameters(face.foreground, '3', reset)
    background = _face_color_parameters(face.background, '4', reset)

    return Decoration(
        foreground,
        background,
        bold,
        faint,
        italic,
        reversed,
        underline,
        strikethrough,
        reset,
        "",
        false,
    )
end

############################################################################################
#                                    Private Functions                                     #
############################################################################################

"""
    _face_attribute_state(value::Union{Nothing, Bool}, reset::Bool) -> DecorationState
    _face_attribute_state(
        value::Union{Nothing, Symbol},
        on::NTuple{N, Symbol},
        reset::Bool,
    ) -> DecorationState where {N}

Return the state of a decoration attribute given the `value` of the field of a face that
controls it. The attribute is unchanged if `value` is `nothing`, and it is on if `value` is
`true` or one of the symbols in `on`. Otherwise, the attribute is off, which is represented
as unchanged if `reset` is `true` because the reset already turns it off.
"""
function _face_attribute_state(value::Union{Nothing, Bool}, reset::Bool)
    isnothing(value) && return unchanged
    value && return active
    return reset ? unchanged : inactive
end

function _face_attribute_state(
    value::Union{Nothing, Symbol}, on::NTuple{N, Symbol}, reset::Bool
) where {N}
    isnothing(value) && return unchanged
    (value ∈ on) && return active
    return reset ? unchanged : inactive
end

# NOTE: The color conversion relies on `StyledStrings.termcolor`, which is not part of the
# public API of StyledStrings.jl. The public `termstyle` cannot be used because it consults
# the terminfo database and silently drops some attributes, like the reverse video, when
# `TERM` is `dumb` or unset. `termcolor` has kept the same signature since the first release
# of StyledStrings.jl, and it handles the named colors, the 24-bit colors with the 8-bit
# fallback, and the colors that name another face.

"""
    _face_color_parameters(
        color::Union{Nothing, SimpleColor},
        category::Char,
        reset::Bool
    ) -> String

Return the SGR parameters that select `color` for `category`, which is `'3'` for the
foreground and `'4'` for the background, like `"31"` or `"48;2;0;95;135"`. Return an empty
string if `color` is `nothing`, if it is the default color of the terminal and `reset` is
`true` because the reset already selects it, or if **StyledStrings.jl** does not know it.
"""
function _face_color_parameters(
    color::Union{Nothing, SimpleColor}, category::Char, reset::Bool
)
    isnothing(color) && return ""

    # The reset already selects the default color of the terminal.
    default = category == '4' ? _DEFAULT_BACKGROUND : _DEFAULT_FOREGROUND
    (reset && (color == default)) && return ""

    # `termcolor` writes the entire escape sequence `\e[<parameters>m`, or nothing if it
    # does not know the color. Hence, we must strip the CSI and the final byte.
    buf = IOBuffer()
    StyledStrings.termcolor(buf, color, category)
    sequence = String(take!(buf))
    isempty(sequence) && return ""

    return String(SubString(sequence, ncodeunits(_CSI) + 1, ncodeunits(sequence) - 1))
end
