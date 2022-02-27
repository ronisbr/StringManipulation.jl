# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
# ==============================================================================
#
#   Tests related with string decorations.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

@testset "Convert decoration to string" begin
    d = Decoration(
        foreground = "35",
        background = "48;5;243",
        underline = true
    )

    expected = "\e[35m\e[48;5;243m\e[22m\e[4m\e[27m"
    result = convert(String, d)

    @test result == expected
end

@testset "Remove deocations" begin
    str = "Test 😅 \e[38;5;231;48;5;243mTest 😅 \e[38;5;201;48;5;243mTest\e[0m"
    expected = "Test 😅 Test 😅 Test"
    result = remove_decorations(str)
    @test expected == result

    str = "This string does not have decorations"
    result = remove_decorations(str)
    @test result == str
end
