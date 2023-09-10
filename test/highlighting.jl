# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
# ==========================================================================================
#
#   Tests related with highlights.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

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

@testset "Highlight Searches in Texts with Multiple Lines" begin
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
        lines,
        r"highlight";
        active_match = 3,
        start_line = 2,
        end_line = 3
    )
    @test hstr == expected

    # No matches in the string.
    expected = """
        Test high\e[1mlight\e[0m in a string with no underlines.
        Test high\e[4mlight in a string with underlines\e[0m.
        Test another high\e[33mlight with colors."""
    hstr = highlight_search(
        lines,
        r"nothing to match";
        active_match = 3,
        start_line = 1,
        end_line = 3
    )
    @test hstr == expected
end
