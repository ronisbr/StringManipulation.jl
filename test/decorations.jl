# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
# ==============================================================================
#
#   Tests related with string decorations.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

@testset "Remove deocations" begin
    str = "Test 😅 \e[38;5;231;48;5;243mTest 😅 \e[38;5;201;48;5;243mTest\e[0m"
    expected = "Test 😅 Test 😅 Test"
    result = remove_decorations(str)
    @test expected == result

    str = "This string does not have decorations"
    result = remove_decorations(str)
    @test result == str
end
