## Description #############################################################################
#
# Tests related with highlights.
#
############################################################################################

@testset "Highlight Searches in Strings" begin
    str      = "Test high\e[1mlight\e[0m in a string with no underlines."
    expected = "Test \e[7mhighlight\e[0m\e[0m in a string with no underlines."
    hstr     = highlight_search(str, r"highlight")
    @test expected == hstr

    str      = "Test high\e[1mlight\e[0m in a string with no underlines."
    expected = "Test \e[30;43mhighlight\e[0m\e[0m in a string with no underlines."
    hstr     = highlight_search(str, r"highlight"; active_match = 1)
    @test expected == hstr

    str      = "Test high\e[4mlight in a string with underlines."
    expected = "Test \e[7mhighlight\e[0m\e[4m in a string with underlines."
    hstr     = highlight_search(str, r"highlight")
    @test expected == hstr

    # No matches in the string.
    hstr = highlight_search(str, r"Nothing to match")
    @test hstr == str
end

@testset "Highlight Searches in Texts With Multiple Lines" begin
    str = """
        Test high\e[1mlight\e[0m in a string with no underlines.
        Test high\e[4mlight in a string with underlines\e[0m.
        Test another high\e[33mlight with colors.
        This is the last line."""
    lines = split(str, '\n')

    expected = """
        Test \e[7mhighlight\e[0m\e[0m in a string with no underlines.
        Test \e[7mhighlight\e[0m\e[4m in a string with underlines\e[0m.
        Test another \e[7mhighlight\e[0m\e[33m with colors.
        This is the last line."""
    hstr = highlight_search(lines, r"highlight")
    @test hstr == expected

    expected = """
        Test \e[7mhighlight\e[0m\e[0m in a string with no underlines.
        Test \e[30;43mhighlight\e[0m\e[4m in a string with underlines\e[0m.
        Test another \e[7mhighlight\e[0m\e[33m with colors.
        This is the last line."""
    hstr = highlight_search(lines, r"highlight"; active_match = 2)
    @test hstr == expected

    expected = """
        Test \e[7mhighlight\e[0m\e[4m in a string with underlines\e[0m.
        Test another \e[30;43mhighlight\e[0m\e[33m with colors."""
    hstr = highlight_search(
        lines, r"highlight"; active_match = 3, start_line = 2, end_line = 3
    )
    @test hstr == expected

    # No matches in the string.
    expected = """
        Test high\e[1mlight\e[0m in a string with no underlines.
        Test high\e[4mlight in a string with underlines\e[0m.
        Test another high\e[33mlight with colors."""
    hstr = highlight_search(
        lines, r"nothing to match"; active_match = 3, start_line = 1, end_line = 3
    )
    @test hstr == expected
end

@testset "Highlight Searches With Out-of-Range Lines" begin
    lines = ["a", "b"]
    matches = Dict(1 => [(1, 1)])
    expected = "\e[7ma\e[0m\nb"

    # `end_line` must be clamped to the number of lines.
    @test highlight_search(lines, matches; end_line = 5) == expected
    @test highlight_search(lines, matches) == expected

    # `start_line` must be clamped to 1.
    @test highlight_search(lines, matches; start_line = -3) == expected
end

@testset "Highlight Searches With Decorations at the Boundaries" begin
    # An escape sequence placed exactly where a match begins must be written before the
    # highlight, whereas one inside the match must be suppressed and reapplied after it.
    str = "ab\e[31mcd\e[0mef"
    matches = string_search(str, r"cd")
    @test highlight_search(str, matches) == "ab\e[31m\e[7mcd\e[0m\e[0mef"

    str = "abcd"
    @test highlight_search(str, [(2, 2)]) == "a\e[7mbc\e[0md"

    # A match that extends past the end of the string must still be closed.
    @test highlight_search("abc", [(2, 10)]) == "a\e[7mbc\e[0m"

    # Wide characters must keep their printable width.
    @test printable_textwidth(highlight_search("日本語", string_search("日本語", r"本"))) ==
        printable_textwidth("日本語")

    # Many matches in a single line must be handled in linear time. This only checks the
    # result, but a quadratic implementation is unusably slow here.
    long = repeat("abc match ", 500)
    long_matches = string_search(long, r"match")
    @test length(long_matches) == 500

    highlighted = highlight_search(long, long_matches)
    @test printable_textwidth(highlighted) == printable_textwidth(long)
    @test count("\e[7m", highlighted) == 500
end
