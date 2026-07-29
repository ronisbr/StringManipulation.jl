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
    @test parsed[2] ==
        ("Test 😅 " => Decoration(; foreground = "38;5;231", background = "48;5;243"))
    @test parsed[3] ==
        ("Test" => Decoration(; foreground = "38;5;201", background = "48;5;243"))
    @test parsed[4] == (" End" => Decoration(; reset = true))

    str = "Test \e[38;5;231;48;5;243mTest 😅 \e[38;5;201;48;5;243mTest\e[0m"

    parsed = parse_ansi_string(str)

    @test length(parsed) == 4
    @test parsed[1] == ("Test " => Decoration())
    @test parsed[2] ==
        ("Test 😅 " => Decoration(; foreground = "38;5;231", background = "48;5;243"))
    @test parsed[3] ==
        ("Test" => Decoration(; foreground = "38;5;201", background = "48;5;243"))
    @test parsed[4] == ("" => Decoration(; reset = true))

    str = "\e[38;5;231;48;5;243mTest 😅 \e[38;5;201;48;5;243mTest\e[0m"

    parsed = parse_ansi_string(str)

    @test length(parsed) == 3
    @test parsed[1] ==
        ("Test 😅 " => Decoration(; foreground = "38;5;231", background = "48;5;243"))
    @test parsed[2] ==
        ("Test" => Decoration(; foreground = "38;5;201", background = "48;5;243"))
    @test parsed[3] == ("" => Decoration(; reset = true))
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
    current = Decoration(; foreground = "32", background = "44")
    for code in ("38", "38;5", "38;2;1;2", "48", "48;5", "48;2;1;2")
        @test StringManipulation._parse_ansi_decoration_code(current, code) == current
    end

    # Valid extended colors retain their existing behavior.
    decoration = parse_code("38;5;231;48;2;216;210;203")
    @test decoration.foreground == "38;5;231"
    @test decoration.background == "48;2;216;210;203"
end

@testset "SGR Parameter Scanning" begin
    parse_code(code) = StringManipulation._parse_ansi_decoration_code(Decoration(), code)

    # A parameter is only valid if it is composed of digits. Anything else must be skipped
    # without hiding the parameters that follow it.
    @test parse_code("48;5;-1").background == ""
    @test parse_code("1 ;3").italic == StringManipulation.active
    @test parse_code("38;5; 1;7").reversed == StringManipulation.active

    # Leading zeros must be handled like any other number.
    @test parse_code("007").reversed == StringManipulation.active
    @test parse_code("038;5;231").foreground == "38;5;231"

    # Scanning the parameters instead of splitting them made the amount allocated
    # independent of how many parameters the code has. Notice that we must not require zero
    # allocations here: the returned `Decoration` is not an `isbits` type, so whether its
    # allocation is elided depends on the Julia version.
    sgr_allocations(d, code) =
        @allocated StringManipulation._parse_ansi_decoration_code(d, code)

    decoration = Decoration()
    codes = ("0", "1", "22;24", "22;24;27;23;1;3;4;7")

    # Warm up so that the compilation is not measured.
    for code in codes
        sgr_allocations(decoration, code)
    end

    baseline = sgr_allocations(decoration, first(codes))

    for code in codes
        @test sgr_allocations(decoration, code) == baseline
    end
end

@testset "Reset Followed by Other Codes" begin
    # A reset must not discard the codes that follow it in the same sequence.
    @test String(parse_decoration("\e[0;31m")) == "\e[0m\e[31m"
    @test String(parse_decoration("\e[0m")) == "\e[0m"

    # A code before the reset must be discarded.
    @test String(parse_decoration("\e[1;0;4m")) == "\e[0m\e[4m"

    decoration = parse_decoration("\e[0;31m")
    @test decoration.reset
    @test decoration.foreground == "31"
end

@testset "Omitted SGR Parameters" begin
    # ECMA-48 states that an omitted parameter takes its default value, 0 for SGR.
    @test String(parse_decoration("\e[m")) == "\e[0m"
    @test parse_decoration("\e[m").reset
    @test String(parse_decoration("\e[;31m")) == "\e[0m\e[31m"
end

@testset "Non-SGR CSI Sequences" begin
    # Only the sequences terminated by `m` change the decoration.
    for code in ("\e[1A", "\e[0K", "\e[2J", "\e[3J", "\e[1;1H", "\e[4G", "\e[K")
        decoration = parse_decoration(code)
        @test decoration == Decoration()
        @test String(decoration) == ""
    end

    # A cursor movement between two SGR sequences must not disturb them.
    @test parse_decoration("\e[1m\e[1A\e[31m").bold == StringManipulation.active
    @test parse_decoration("\e[1m\e[1A\e[31m").foreground == "31"

    # They also must not be counted as printable text.
    @test printable_textwidth("a\e[1Ab\e[0Kc") == 3
end

@testset "Hyperlink Terminators" begin
    # An OSC 8 hyperlink can be terminated by either ST or BEL.
    bel = "\e]8;;http://a\aX\e]8;;\a"
    st  = "\e]8;;http://a\e\\X\e]8;;\e\\"

    @test remove_decorations(bel) == "X"
    @test remove_decorations(st) == "X"
    @test printable_textwidth(bel) == 1
    @test printable_textwidth(st) == 1

    @test parse_decoration("\e]8;;http://a\a").hyperlink_url == "http://a"
    @test parse_decoration("\e]8;;http://a\e\\").hyperlink_url == "http://a"
    @test parse_decoration("\e]8;;http://a\a").hyperlink_url_changed
    @test parse_decoration("\e]8;;\a").hyperlink_url == ""

    @test first(first(parse_ansi_string(bel))) == "X"
    @test first(first(parse_ansi_string(st))) == "X"

    # An unterminated hyperlink must not consume the following lines.
    @test occursin(
        "rest of text", join(first.(parse_ansi_string("\e]8;;bad\nrest of text")))
    )
end
