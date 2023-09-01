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

@testset "Corner Cases" begin
    str = """
    We have \e[38;5;231;48;5;243mhere\e[0m 😅😃 the first line
    We now have the 😊 \e[38;5;231;48;5;243msecond\e[0m 😃 line"""

    aligned_str = align_string_per_line(str, -1, :l)

    @test aligned_str == str
end
