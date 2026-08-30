## Description #############################################################################
#
# Conversion of the faces of StyledStrings.jl into decorations.
#
############################################################################################

export face_color_rgb

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

# Named tuple used by StyledStrings.jl to store a 24-bit color.
const _RGBTuple = NamedTuple{(:r, :g, :b), NTuple{3, UInt8}}

# 24-bit values of the 16 terminal colors, copied from the ones StyledStrings.jl uses to
# render the faces in HTML (`HTML_BASIC_COLORS`, which is not part of its public API).
const _TERMINAL_COLORS_RGB = Dict{Symbol, _RGBTuple}(
    :black          => (r = 0x1c, g = 0x1a, b = 0x23),
    :red            => (r = 0xa5, g = 0x1c, b = 0x2c),
    :green          => (r = 0x25, g = 0xa2, b = 0x68),
    :yellow         => (r = 0xe5, g = 0xa5, b = 0x09),
    :blue           => (r = 0x19, g = 0x5e, b = 0xb3),
    :magenta        => (r = 0x80, g = 0x3d, b = 0x9b),
    :cyan           => (r = 0x00, g = 0x97, b = 0xa7),
    :white          => (r = 0xdd, g = 0xdc, b = 0xd9),
    :bright_black   => (r = 0x76, g = 0x75, b = 0x7a),
    :grey           => (r = 0x76, g = 0x75, b = 0x7a),
    :gray           => (r = 0x76, g = 0x75, b = 0x7a),
    :bright_red     => (r = 0xed, g = 0x33, b = 0x3b),
    :bright_green   => (r = 0x33, g = 0xd0, b = 0x79),
    :bright_yellow  => (r = 0xf6, g = 0xd2, b = 0x2c),
    :bright_blue    => (r = 0x35, g = 0x83, b = 0xe4),
    :bright_magenta => (r = 0xbf, g = 0x60, b = 0xca),
    :bright_cyan    => (r = 0x26, g = 0xc6, b = 0xda),
    :bright_white   => (r = 0xf6, g = 0xf5, b = 0xf4),
)

# Maximum number of faces followed when a color names another face, guarding cycles.
const _MAX_FACE_COLOR_DEPTH = 16

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
"\\e[0;31;1m"

julia> Decoration(Face(; background = :blue)).background
"44"

julia> String(Decoration(Face(; weight = :normal, underline = false); reset = false))
"\\e[22;24m"
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

"""
    face_color_rgb(color::Union{Nothing, SimpleColor}) -> Union{Nothing, NamedTuple}

Return the 24-bit value of `color`, a color of a face of **StyledStrings.jl**, as the named
tuple `(; r, g, b)` with `UInt8` fields, or `nothing` if it has no fixed value.

A 24-bit color is returned as is. One of the 16 terminal colors, like `:red` or
`:bright_blue`, is mapped to the value **StyledStrings.jl** uses to render it in HTML. A
symbol that names another face selects the foreground of that face, following the chain
until a fixed color is found. The default colors of the terminal (`:default`,
`:foreground`, and `:background`), an unknown name, and `nothing` return `nothing`.

# Examples

```julia
julia> using StyledStrings

julia> face_color_rgb(SimpleColor(:red))
(r = 0xa5, g = 0x1c, b = 0x2c)

julia> face_color_rgb(SimpleColor(0x005f87))
(r = 0x00, g = 0x5f, b = 0x87)

julia> face_color_rgb(SimpleColor(:default))

julia> face_color_rgb(Face(; foreground = :error).foreground)
(r = 0xa5, g = 0x1c, b = 0x2c)
```
"""
face_color_rgb(color::Union{Nothing, SimpleColor}) = _face_color_rgb(color, 0)

############################################################################################
#                                    Private Functions                                     #
############################################################################################

"""
    _face_color_rgb(color::Union{Nothing, SimpleColor}, depth::Int) -> Union{Nothing, NamedTuple}

Implementation of `face_color_rgb`, in which `depth` is the number of faces followed so far
when the color names another face.
"""
function _face_color_rgb(color::Union{Nothing, SimpleColor}, depth::Int)
    isnothing(color) && return nothing

    value = color.value
    (value isa _RGBTuple) && return value

    rgb = get(_TERMINAL_COLORS_RGB, value, nothing)
    isnothing(rgb) || return rgb

    (value ∈ (:default, :foreground, :background)) && return nothing
    (depth >= _MAX_FACE_COLOR_DEPTH) && return nothing

    # `getface` returns the default face for an unknown name, whose foreground is the
    # default color of the terminal. Hence, unknown names return `nothing` above.
    foreground = StyledStrings.getface(value).foreground
    (foreground == color) && return nothing

    return _face_color_rgb(foreground, depth + 1)
end

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
