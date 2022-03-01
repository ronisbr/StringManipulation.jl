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

    d = Decoration(
        foreground = "35",
        background = "48;5;243",
        underline = StringManipulation.inactive
    )

    expected = "\e[35m\e[48;5;243m\e[24m"
    result = convert(String, d)

    d = Decoration(
        foreground = "35",
        background = "",
        bold = StringManipulation.active
    )

    expected = "\e[35m\e[1m"
    result = convert(String, d)

    d = Decoration(
        foreground = "35",
        background = "",
        bold = StringManipulation.inactive
    )

    expected = "\e[35m\e[22m"
    result = convert(String, d)

    d = Decoration(
        foreground = "",
        background = "45",
        reversed = StringManipulation.active
    )

    expected = "\e[45m\e[7m"
    result = convert(String, d)

    d = Decoration(
        foreground = "",
        background = "45",
        reversed = StringManipulation.inactive
    )

    expected = "\e[45m\e[27m"
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

@testset "Parse decorations" begin
    decoration = parse_decoration("\e[35m\e[48;5;243m\e[4;27m")

    @test decoration.foreground == "35"
    @test decoration.background == "48;5;243"
    @test decoration.underline  == StringManipulation.active
    @test decoration.bold       == StringManipulation.unchanged
    @test decoration.reversed   == StringManipulation.inactive
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
