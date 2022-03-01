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
        underline = StringManipulation.active
    )

    expected = "\e[35m\e[48;5;243m\e[4m"
    result = convert(String, d)

    @test result == expected
end

@testset "Get decorations" begin
    str = "Test 😅 \e[38;5;231;48;5;243mTest 😅 \e[38;5;201;48;5;243mTest\e[0m"
    expected = "\e[38;5;231;48;5;243m\e[38;5;201;48;5;243m\e[0m"
    result = get_decorations(str)
    @test expected == result
end

@testset "Get and remove decorations" begin
    str = "Test 😅 \e[38;5;231;48;5;243mTest 😅 \e[38;5;201;48;5;243mTest\e[0m"
    expected_decorations = "\e[38;5;231;48;5;243m\e[38;5;201;48;5;243m\e[0m"
    expected_text = "Test 😅 Test 😅 Test"
    decorations, text = get_and_remove_decorations(str)
    @test expected_decorations == decorations
    @test expected_text === text
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
