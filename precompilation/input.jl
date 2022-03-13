# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Descriptions
# ==============================================================================
#
#   Function calls to create the precompilation statements using SnoopCompiler.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function precompilation_input()
    include("../test/runtests.jl")

    # For some reason, the precompilation system is not precompiling `write` if
    # called with a `SubString`. The following code reduced the time to obtained
    # the first view from 0.2s to 0.005s.
    let
        io = IOBuffer()
        write(io, SubString("test", 1, 4))
    end
end
