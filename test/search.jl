## Description #############################################################################
#
# Tests related with string searching.
#
############################################################################################

@testset "String Search" begin
    str = """
        Test 1 😅 \e[38;5;231;48;5;243mTest 2 😅 \e[38;5;201;48;5;243mTest\e[0m
        Test 1 😅 \e[38;5;231;48;5;243mTest 2 😅 \e[38;5;201;48;5;243mTest\e[0m
        """

    expected = [(11, 9), (35, 9)]
    search_result = string_search(str, r"Test 2 😅")
    @test search_result == expected

    @test string_search("one two one three one", r"one") == [(1, 3), (9, 3), (19, 3)]
end

@testset "String Search With Unicode" begin
    @test string_search("ééé", r"é") == [(1, 1), (2, 1), (3, 1)]

    # The reported column must be the one where the match begins. Hence, it must not
    # include the width of the first character of the match itself.
    @test string_search("😅😅😅", r"😅") == [(1, 2), (3, 2), (5, 2)]
    @test string_search("日本語", r"本") == [(3, 2)]

    @test string_search("é éé ééé", r"é+") == [(1, 1), (3, 2), (6, 3)]

    decorated = "\e[31méé\e[0m 😅\e[1m😅\e[0m"
    @test string_search(decorated, r"é|😅") == [(1, 1), (2, 1), (4, 2), (6, 2)]

    parent = "xxéé😅😅yy"
    substring = SubString(parent, 3, prevind(parent, lastindex(parent), 2))
    @test string_search(substring, r"😅") == [(3, 2), (5, 2)]
end

@testset "String Search With Empty Matches" begin
    # A regex that can match an empty string yields an offset one past the last byte at the
    # end of the string, which must not be treated as a valid index.
    @test string_search("abc", r"x*") == [(1, 0), (2, 0), (3, 0), (4, 0)]
    @test string_search("", r"x*") == [(1, 0)]
    @test string_search("aé", r"") == [(1, 0), (2, 0), (3, 0)]
end

@testset "String Search by Line" begin
    str = """
        Test 1 😅 \e[38;5;231;48;5;243mTest 2 😅 \e[38;5;201;48;5;243mTest\e[0m
        Test 1 😅 \e[38;5;231;48;5;243mTest 2 😅 \e[38;5;201;48;5;243mTest\e[0m
        Test 1 😅 \e[38;5;231;48;5;243mTest 2 😅 \e[38;5;201;48;5;243mTest\e[0m
        Test 1 😅 \e[38;5;231;48;5;243mTest 2 😅 \e[38;5;201;48;5;243mTest\e[0m
        Test 1 😅 \e[38;5;231;48;5;243mTest 2 😅 \e[38;5;201;48;5;243mTest\e[0m
        """

    search_result = string_search_per_line(str, r"Test 2 😅")

    @test search_result[1] == [(11, 9)]
    @test search_result[2] == [(11, 9)]
    @test search_result[3] == [(11, 9)]
    @test search_result[4] == [(11, 9)]
    @test search_result[5] == [(11, 9)]
    @test length(search_result) == 5
end
