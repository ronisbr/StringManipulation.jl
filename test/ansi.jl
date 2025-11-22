## Description #############################################################################
#
# Tests related to the ANSI escape sequences.
#
############################################################################################

@testset "Parsing ANSI Strings" begin
    str = "Test \e[38;5;231;48;5;243mTest 😅 \e[38;5;201;48;5;243mTest\e[0m End"

    parsed = parse_ansi_string(str)

    @test length(parsed) == 4
    @test parsed[1] == ("Test " => Decoration())
    @test parsed[2] == (
        "Test 😅 " => Decoration(
            foreground = "38;5;231",
            background = "48;5;243"
        )
    )
    @test parsed[3] == (
        "Test" => Decoration(
            foreground = "38;5;201",
            background = "48;5;243"
        )
    )
    @test parsed[4] == (" End" => Decoration(reset = true))

    str = "Test \e[38;5;231;48;5;243mTest 😅 \e[38;5;201;48;5;243mTest\e[0m"

    parsed = parse_ansi_string(str)

    @test length(parsed) == 4
    @test parsed[1] == ("Test " => Decoration())
    @test parsed[2] == (
        "Test 😅 " => Decoration(
            foreground = "38;5;231",
            background = "48;5;243"
        )
    )
    @test parsed[3] == (
        "Test" => Decoration(
            foreground = "38;5;201",
            background = "48;5;243"
        )
    )
    @test parsed[4] == ("" => Decoration(reset = true))

    str = "\e[38;5;231;48;5;243mTest 😅 \e[38;5;201;48;5;243mTest\e[0m"

    parsed = parse_ansi_string(str)

    @test length(parsed) == 3
    @test parsed[1] == (
        "Test 😅 " => Decoration(
            foreground = "38;5;231",
            background = "48;5;243"
        )
    )
    @test parsed[2] == (
        "Test" => Decoration(
            foreground = "38;5;201",
            background = "48;5;243"
        )
    )
    @test parsed[3] == ("" => Decoration(reset = true))
end