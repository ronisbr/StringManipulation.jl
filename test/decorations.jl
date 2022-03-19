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

@testset "Drop inactive decorations" begin
    decoration = Decoration(
        foreground = "39",
        background = "49",
        bold       = StringManipulation.inactive,
        underline  = StringManipulation.inactive,
        reversed   = StringManipulation.inactive
    )

    decoration = drop_inactive_properties(decoration)

    @test decoration === Decoration()

    decoration = Decoration(
        foreground = "39",
        background = "245",
        bold       = StringManipulation.inactive,
        underline  = StringManipulation.inactive,
        reversed   = StringManipulation.inactive
    )

    decoration = drop_inactive_properties(decoration)

    @test decoration === Decoration(background = "245")
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

# Those tests are also used to verify the function `_parse_ansi_code`.
@testset "Parse decorations" begin
    decoration = parse_decoration("\e[35m\e[48;5;243m\e[4;27m")

    @test decoration.foreground == "35"
    @test decoration.background == "48;5;243"
    @test decoration.underline  == StringManipulation.active
    @test decoration.bold       == StringManipulation.unchanged
    @test decoration.reversed   == StringManipulation.inactive

    decoration = parse_decoration("\e[45;1m")

    @test decoration.foreground == ""
    @test decoration.background == "45"
    @test decoration.underline  == StringManipulation.unchanged
    @test decoration.bold       == StringManipulation.active
    @test decoration.reversed   == StringManipulation.unchanged

    decoration = parse_decoration("\e[48;5;243;7;22m")

    @test decoration.foreground == ""
    @test decoration.background == "48;5;243"
    @test decoration.underline  == StringManipulation.unchanged
    @test decoration.bold       == StringManipulation.inactive
    @test decoration.reversed   == StringManipulation.active

    decoration = parse_decoration("\e[39;49;1;7m")

    @test decoration.foreground == "39"
    @test decoration.background == "49"
    @test decoration.underline  == StringManipulation.unchanged
    @test decoration.bold       == StringManipulation.active
    @test decoration.reversed   == StringManipulation.active

    decoration = parse_decoration("\e[92;103;24m")

    @test decoration.foreground == "92"
    @test decoration.background == "103"
    @test decoration.underline  == StringManipulation.inactive
    @test decoration.bold       == StringManipulation.unchanged
    @test decoration.reversed   == StringManipulation.unchanged

    # Parse decorations with text in the middle.
    decoration = parse_decoration("\e[35m\e[48;5;243mThis text should be discarded\e[4;27m")

    @test decoration.foreground == "35"
    @test decoration.background == "48;5;243"
    @test decoration.underline  == StringManipulation.active
    @test decoration.bold       == StringManipulation.unchanged
    @test decoration.reversed   == StringManipulation.inactive

    # Unsupported escape sequences.
    decoration = parse_decoration("\e]8")
    @test decoration === Decoration()

    # True-color mode.
    decoration = parse_decoration("\e[38;2;28;101;140;48;2;216;210;203mFirst decoration")

    @test decoration.foreground == "38;2;28;101;140"
    @test decoration.background == "48;2;216;210;203"
    @test decoration.underline  == StringManipulation.unchanged
    @test decoration.bold       == StringManipulation.unchanged
    @test decoration.reversed   == StringManipulation.unchanged
end

@testset "Remove decorations" begin
    str = "Test 😅 \e[38;5;231;48;5;243mTest 😅 \e[38;5;201;48;5;243mTest\e[0m"
    expected = "Test 😅 Test 😅 Test"
    result = remove_decorations(str)
    @test expected == result

    str = "This string does not have decorations"
    result = remove_decorations(str)
    @test result == str
end

@testset "Update decorations" begin
    decoration = Decoration()

    decoration = update_decoration(decoration, "\e[38;5;231m")
    @test decoration.foreground == "38;5;231"
    @test decoration.background == ""
    @test decoration.underline  == StringManipulation.unchanged
    @test decoration.bold       == StringManipulation.unchanged
    @test decoration.reversed   == StringManipulation.unchanged
    @test decoration.reset      == false

    decoration = update_decoration(decoration, "\e[48;5;243m")
    @test decoration.foreground == "38;5;231"
    @test decoration.background == "48;5;243"
    @test decoration.underline  == StringManipulation.unchanged
    @test decoration.bold       == StringManipulation.unchanged
    @test decoration.reversed   == StringManipulation.unchanged
    @test decoration.reset      == false

    decoration = update_decoration(decoration, "\e[4;27m")
    @test decoration.foreground == "38;5;231"
    @test decoration.background == "48;5;243"
    @test decoration.underline  == StringManipulation.active
    @test decoration.bold       == StringManipulation.unchanged
    @test decoration.reversed   == StringManipulation.inactive
    @test decoration.reset      == false

    decoration = update_decoration(decoration, "\e[0m")
    @test decoration.foreground == ""
    @test decoration.background == ""
    @test decoration.underline  == StringManipulation.unchanged
    @test decoration.bold       == StringManipulation.unchanged
    @test decoration.reversed   == StringManipulation.unchanged
    @test decoration.reset      == true

    decoration = update_decoration(decoration, "\e[33m")
    @test decoration.foreground == "33"
    @test decoration.background == ""
    @test decoration.underline  == StringManipulation.unchanged
    @test decoration.bold       == StringManipulation.unchanged
    @test decoration.reversed   == StringManipulation.unchanged
    @test decoration.reset      == false

    # Update decorations with text in the middle.
    decoration = Decoration()

    decoration = update_decoration(
        decoration,
        "\e[38;5;231mThis text should be discarded\e[48;5;243m"
    )
    @test decoration.foreground == "38;5;231"
    @test decoration.background == "48;5;243"
    @test decoration.underline  == StringManipulation.unchanged
    @test decoration.bold       == StringManipulation.unchanged
    @test decoration.reversed   == StringManipulation.unchanged
    @test decoration.reset      == false

    decoration = update_decoration(
        decoration,
        "This also should be discarded\e[4;27m"
    )
    @test decoration.foreground == "38;5;231"
    @test decoration.background == "48;5;243"
    @test decoration.underline  == StringManipulation.active
    @test decoration.bold       == StringManipulation.unchanged
    @test decoration.reversed   == StringManipulation.inactive
    @test decoration.reset      == false

    # True-color mode.
    decoration = Decoration()
    decoration = update_decoration(
        decoration,
        "\e[38;2;28;101;140;48;2;216;210;203mFirst decoration"
    )

    @test decoration.foreground == "38;2;28;101;140"
    @test decoration.background == "48;2;216;210;203"
    @test decoration.underline  == StringManipulation.unchanged
    @test decoration.bold       == StringManipulation.unchanged
    @test decoration.reversed   == StringManipulation.unchanged

    decoration = update_decoration(
        decoration,
        "\e[38;2;57;138;185;1mSecond decoration"
    )

    @test decoration.foreground == "38;2;57;138;185"
    @test decoration.background == "48;2;216;210;203"
    @test decoration.underline  == StringManipulation.unchanged
    @test decoration.bold       == StringManipulation.active
    @test decoration.reversed   == StringManipulation.unchanged
end
