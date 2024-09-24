module StringManipulation

import Base: convert, String, @kwdef

############################################################################################
#                                        Constants                                         #
############################################################################################

const _CSI = "\x1b["

# This regex match all the ANSI escape sequences that defines decorations.
const _REGEX_ANSI_SEQUENCES = r"\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])"

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
"""
@kwdef struct Decoration
    foreground::String         = ""
    background::String         = ""
    bold::DecorationState      = unchanged
    underline::DecorationState = unchanged
    reset::Bool                = false
    reversed::DecorationState  = unchanged
end

const _DEFAULT_DECORATION = Decoration()
const _RESET_DECORATION = Decoration(reset = true)

############################################################################################
#                                         Includes                                         #
############################################################################################

include("./alignment.jl")
include("./ansi.jl")
include("./crop.jl")
include("./decorations.jl")
include("./highlighting.jl")
include("./search.jl")
include("./state.jl")
include("./split.jl")
include("./view.jl")
include("./width.jl")

include("./precompilation.jl")

end # module
