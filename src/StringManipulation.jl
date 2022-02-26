module StringManipulation

################################################################################
#                                  Constants
################################################################################

# Regex that removes all ANSI escape sequences.
const _REGEX_ANSI = r"\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])"

################################################################################
#                                   Includes
################################################################################

include("./constants.jl")

include("./alignment.jl")
include("./crop.jl")
include("./decorations.jl")
include("./state.jl")
include("./split.jl")
include("./width.jl")

end # module
