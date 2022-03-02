# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Descriptions
# ==============================================================================
#
#   Function that generates the precompilation statements.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

using SnoopCompile

run(`rm -rf ../src/precompile/precompile_StringManipulation.jl`)

using Pkg
Pkg.build("StringManipulation")
using PrettyTables

include("input.jl")

function create_precompile_files()
    tinf = @snoopi_deep precompilation_input()
    ttot, pcs = SnoopCompile.parcel(tinf)
    SnoopCompile.write("../src/precompile/", pcs)

    # Remove all precompile files that are not related to StringManipulation.jl.
    run(`bash -c "find ../src/precompile/precompile* -maxdepth 1 ! -name \"*StringManipulation*\" -type f -exec rm -f {} \\;"`)
end

create_precompile_files()
