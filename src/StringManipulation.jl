module StringManipulation

import Base: convert, @kwdef

################################################################################
#                                  Constants
################################################################################

const _CSI = "\x1b["
# Regex that removes all ANSI escape sequences.
const _REGEX_ANSI = r"\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])"

################################################################################
#                                  Structures
################################################################################

export Decoration

"""
    struct Decoration

Structure to hold the current decoration of a string.
"""
@kwdef struct Decoration
    foreground::String = ""
    background::String = ""
    bold::Bool         = false
    underline::Bool    = false
    reset::Bool        = false
    reversed::Bool     = false
end

const _DEFAULT_DECORATION = Decoration()

################################################################################
#                                   Includes
################################################################################

include("./constants.jl")

include("./alignment.jl")
include("./ansi.jl")
include("./crop.jl")
include("./decorations.jl")
include("./search.jl")
include("./state.jl")
include("./split.jl")
include("./width.jl")

end # module
