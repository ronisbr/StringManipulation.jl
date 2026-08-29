module StringManipulation

import Base: String, @kwdef

############################################################################################
#                                        Constants                                         #
############################################################################################

const _CSI = "\x1b["

# This regex matches all ANSI escape sequences that define decorations. Notice that an
# OSC 8 hyperlink can be terminated by either ST (`\e\\`) or BEL (`\a`), and that its URL
# cannot contain control characters. The latter restriction lets us bail out of a sequence
# that was never terminated instead of consuming the remaining text.
const _REGEX_ANSI_SEQUENCES = Regex(
    raw"\x1B(?:]8;;[^\x00-\x1F\x7F]*(?:\x1B\\|\a)|[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])"
)

# Padding used to align strings. It is written in chunks so that we never need to build
# a string of spaces.
const _SPACES = " "^64

# Escape sequence that reset all decorations.
const _RESET_DECORATIONS = _CSI * "0m"

############################################################################################
#                                        Structures                                        #
############################################################################################

# Enumeration to store the state in `Decoration`.
@enum DecorationState begin
    inactive  = 0
    active    = 1
    unchanged = 2
end

export Decoration

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

const _DEFAULT_DECORATION = Decoration()
const _RESET_DECORATION = Decoration(; reset = true)

############################################################################################
#                                         Includes                                         #
############################################################################################

include("./alignment.jl")
include("./ansi.jl")
include("./crop.jl")
include("./decorations.jl")
include("./highlighting.jl")
include("./state.jl")
include("./split.jl")
include("./layout.jl")
include("./search.jl")
include("./view.jl")
include("./width.jl")

include("./precompilation.jl")

end # module
