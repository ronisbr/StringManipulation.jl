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

@testset "Malformed Extended ANSI Colors" begin
    parse_code(code) = StringManipulation._parse_ansi_decoration_code(Decoration(), code)

    for code in ("\e[38;?m", "\e[38;:m", "\e[38;5;:m")
        @test parse_decoration(code) == Decoration()
    end
    @test parse_decoration("\e[48;?;1m").bold == StringManipulation.active
    @test parse_decoration("\e[48;5;:;3m").italic == StringManipulation.active

    # Malformed and unsupported modes are ignored without hiding later SGR tokens.
    @test parse_code("38;invalid;1").bold == StringManipulation.active
    @test parse_code("48;;3").italic == StringManipulation.active
    @test parse_code("38;999;4").underline == StringManipulation.active

    # Malformed 256-color values are ignored for both foreground and background.
    decoration = parse_code("38;5;invalid;1;48;5;;3")
    @test decoration.foreground == ""
    @test decoration.background == ""
    @test decoration.bold == StringManipulation.active
    @test decoration.italic == StringManipulation.active

    overflow = "999999999999999999999999999999999999999999999999999999999999"
    decoration = parse_code("38;5;$overflow;4;48;5;$overflow;7")
    @test decoration.foreground == ""
    @test decoration.background == ""
    @test decoration.underline == StringManipulation.active
    @test decoration.reversed == StringManipulation.active

    # Each malformed RGB component is ignored, and parsing resumes after the RGB tuple.
    @test parse_code("38;2;bad;20;30;1").bold == StringManipulation.active
    @test parse_code("38;2;10;;30;3").italic == StringManipulation.active
    @test parse_code("48;2;10;20;bad;4").underline == StringManipulation.active
    @test parse_code("48;2;$overflow;20;30;7").reversed == StringManipulation.active

    # Missing components terminate cleanly and preserve the current decoration.
    current = Decoration(foreground = "32", background = "44")
    for code in ("38", "38;5", "38;2;1;2", "48", "48;5", "48;2;1;2")
        @test StringManipulation._parse_ansi_decoration_code(current, code) == current
    end

    # Valid extended colors retain their existing behavior.
    decoration = parse_code("38;5;231;48;2;216;210;203")
    @test decoration.foreground == "38;5;231"
    @test decoration.background == "48;2;216;210;203"
end
