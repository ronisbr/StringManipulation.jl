# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
# ==========================================================================================
#
#   Tests related to the string alignment.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

@testset "Alignment to The Right" begin
    str = "Test 😃 \e[38;5;231;48;5;243mTest \e[0m😅 Test"

    expected = "                    Test 😃 \e[38;5;231;48;5;243mTest \e[0m😅 Test"
    aligned_str = align_string(str, 40, :r)

    @test aligned_str === expected
    @test printable_textwidth(aligned_str) == 40

    aligned_str = align_string(str, 40, :r; fill = true)

    @test aligned_str === expected
    @test printable_textwidth(aligned_str) == 40

    aligned_str = align_string(str, 10, :r)
    @test str == aligned_str
end

@testset "Alignment to The Center" begin
    str = "Test 😃 \e[38;5;231;48;5;243mTest \e[0m😅 Test"
    expected = "          Test 😃 \e[38;5;231;48;5;243mTest \e[0m😅 Test"
    aligned_str = align_string(str, 40, :c)

    @test aligned_str === expected
    @test printable_textwidth(aligned_str) == 30

    expected = "          Test 😃 \e[38;5;231;48;5;243mTest \e[0m😅 Test          "
    aligned_str = align_string(str, 40, :c; fill = true)

    @test aligned_str === expected
    @test printable_textwidth(aligned_str) == 40

    aligned_str = align_string(str, 10, :c)
    @test str == aligned_str
end

@testset "Alignment to The Left" begin
    str = "Test 😃 \e[38;5;231;48;5;243mTest \e[0m😅 Test"
    aligned_str = align_string(str, 40, :l)

    @test aligned_str === str
    @test printable_textwidth(aligned_str) == 20

    expected = "Test 😃 \e[38;5;231;48;5;243mTest \e[0m😅 Test                    "
    aligned_str = align_string(str, 40, :l; fill = true)

    @test aligned_str == expected
    @test printable_textwidth(aligned_str) == 40

    aligned_str = align_string(str, 10, :l)
    @test str == aligned_str
end

@testset "Multiple Lines Alignment" begin
    str = """
    We have \e[38;5;231;48;5;243mhere\e[0m 😅😃 the first line
    We now have the 😊 \e[38;5;231;48;5;243msecond\e[0m 😃 line"""

    expected_str = "                  We have \e[38;5;231;48;5;243mhere\e[0m 😅😃 the first line\n                 We now have the 😊 \e[38;5;231;48;5;243msecond\e[0m 😃 line"
    aligned_str = align_string_per_line(str, 50, :r)

    @test aligned_str == expected_str
end

@testset "Per-line Alignment Preservation" begin
    @test align_string_per_line("", 4, :l) == ""
    @test align_string_per_line("", 4, :l; fill = true) == "    "
    @test align_string_per_line("\n", 4, :r) == "    \n    "
    @test align_string_per_line("\n\n", 4, :l) == "\n\n"
    @test align_string_per_line("a\n\n", 4, :r) == "   a\n    \n    "
    @test align_string_per_line("a\n\nb\n", 4, :l) == "a\n\nb\n"

    cases = (
        (:l, false, "a\nbb"),
        (:l, true, "a   \nbb  "),
        (:c, false, " a\n bb"),
        (:c, true, " a  \n bb "),
        (:r, false, "   a\n  bb"),
        (:r, true, "   a\n  bb"),
    )

    for (alignment, fill, expected) in cases
        @test align_string_per_line("a\nbb", 4, alignment; fill) == expected
    end

    ansi = "\e[31mA\e[0m\n\e[1mB\e[0m"
    @test align_string_per_line(ansi, 3, :r) == "  \e[31mA\e[0m\n  \e[1mB\e[0m"

    unicode = "界\né"
    @test align_string_per_line(unicode, 4, :r) == "  界\n   é"
    @test align_string_per_line("a\n\nb", 4, :invalid; fill = true) == "a\n\nb"

    parent = "prefix:a\nβ:suffix"
    substring = SubString(parent, 8, 10)
    aligned_substring = align_string_per_line(substring, 4, :r)
    @test aligned_substring == "   a\n   β"
    @test aligned_substring isa String

    @test align_string_per_line(substring, 0, :r) === substring
    @test align_string_per_line(substring, -1, :r; fill = true) === substring
end

@testset "Corner Cases" begin
    str = """
    We have \e[38;5;231;48;5;243mhere\e[0m 😅😃 the first line
    We now have the 😊 \e[38;5;231;48;5;243msecond\e[0m 😃 line"""

    aligned_str = align_string_per_line(str, -1, :l)

    @test aligned_str == str
end
