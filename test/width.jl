## Description #############################################################################
#
# Tests related to the string width computation.
#
############################################################################################

@testset "Printable Text Width" verbose = true begin
    # Some examples here were obtained from:
    #   https://www.lihaoyi.com/post/BuildyourownCommandLinewithANSIescapecodes.html

    str = "\e[38;5;231;48;5;243mTes\e[3mt Test\e[1m Test\e[0m"
    @test printable_textwidth(str) == 14

    str = "\e[38;5;231;48;5;243m😃\e[3m😄\e[1m😊\e[0m"
    @test printable_textwidth(str) == 6

    str = "\e[1m😃\e[0m\e[4m😅\e[0m\e[7m🥳\e[0m"
    @test printable_textwidth(str) == 6

    # == Hyperlinks (OSC 8) ================================================================

    str = "Test 😅 \e[38;5;231;48;5;243;3m\e]8;;https://ronanarraes.com\e\\Test 😅 \e[38;5;201;48;5;243;23mTest\e[0m"
    @test printable_textwidth(str) == 20

    # == Multi Line Support ================================================================

    str = """
    \e[38;5;231;48;5;243mTes\e[3mt Test\e[1m Test\e[0m
    \e[38;5;231;48;5;243m😃\e[3m😄\e[1m😊\e[0m
    \e[1m😃\e[0m\e[4m😅\e[0m\e[7m🥳\e[0m
    Test 😅 \e[38;5;231;48;5;243;3m\e]8;;https://ronanarraes.com\e\\Test 😅 \e[38;5;201;48;5;243;23mTest\e[0m
    \u001b[30;1m A \u001b[31;1m B \u001b[32;1m C \u001b[33;1m D \u001b[0m
    \u001b[44;1m A \u001b[45;1m B \u001b[46;1m C \u001b[47;1m D \u001b[0m
    \u001b[1m BOLD \u001b[0m\u001b[4m Underline \u001b[0m\u001b[7m Reversed \u001b[0m
    \u001b[1m\u001b[4m\u001b[7m BOLD Underline Reversed \u001b[0m"""

    lines_width = printable_textwidth_per_line(str)

    @test length(lines_width) == 8
    @test lines_width[1] == 14
    @test lines_width[2] == 6
    @test lines_width[3] == 6
    @test lines_width[4] == 20
    @test lines_width[5] == 12
    @test lines_width[6] == 12
    @test lines_width[7] == 27
    @test lines_width[8] == 25
end

@testset "Printable Text Width Without Allocations" begin
    # The width must be computed without materializing the undecorated string.
    @test @allocated(printable_textwidth("plain ascii line")) == 0
    @test @allocated(printable_textwidth("\e[1mbold\e[0m and \e[31mred\e[0m")) == 0
    @test @allocated(printable_textwidth("日本語 and émojis 😅")) == 0

    # The result must match the definition based on `remove_decorations`.
    for str in (
        "",
        "plain",
        "\e[1mbold\e[0m",
        "日本語",
        "😅😅",
        "\e]8;;https://example.com\e\\link\e]8;;\e\\",
        "\e]8;;https://example.com\alink\e]8;;\a",
        "\e[38;5;231;48;5;243mcolored\e[0m",
        "a\tb\nc",
    )
        @test printable_textwidth(str) == textwidth(remove_decorations(str))
    end

    @test printable_textwidth_per_line("ab\n\e[1mcde\e[0m\n日本") == [2, 3, 4]
    @test printable_textwidth_per_line("") == [0]
    @test printable_textwidth_per_line("a\n") == [1, 0]
end
