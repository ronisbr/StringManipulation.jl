module StringManipulation

import Base: convert, String, @kwdef

################################################################################
#                                  Constants
################################################################################

const _CSI = "\x1b["
# Regex that removes all ANSI escape sequences.
const _REGEX_ANSI = r"\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])"
# Escape sequence that reset all decorations.
const _RESET_DECORATIONS = _CSI * "0m"

################################################################################
#                                  Structures
################################################################################

# Enumetation to store the state in `Decoration`.
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

################################################################################
#                                   Includes
################################################################################

include("./constants.jl")

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

# The environment variable `STRING_MANIPULATION_NO_PRECOMPILATION` is used to
# disable the precompilation directives. This option must only be used inside
# Github Actions to improve the coverage results.
if Base.VERSION >= v"1.4.2" && !haskey(ENV, "STRING_MANIPULATION_NO_PRECOMPILATION")
    # This try/catch is necessary in case the precompilation statements do not
    # exists. In this case, StringManipulation.jl will work correctly but
    # without the optimizations.
    try
        include("../precompilation/precompile_StringManipulation.jl")
        include("../precompilation/precompile_StringManipulation_manual.jl")
        _precompile_()
        _precompile_manual_()
    catch
    end
end

end # module
