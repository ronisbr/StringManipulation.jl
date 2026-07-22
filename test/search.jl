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
    @test string_search("😅😅😅", r"😅") == [(2, 2), (4, 2), (6, 2)]

    @test string_search("é éé ééé", r"é+") == [(1, 1), (3, 2), (6, 3)]

    decorated = "\e[31méé\e[0m 😅\e[1m😅\e[0m"
    @test string_search(decorated, r"é|😅") == [(1, 1), (2, 1), (5, 2), (7, 2)]

    parent = "xxéé😅😅yy"
    substring = SubString(parent, 3, prevind(parent, lastindex(parent), 2))
    @test string_search(substring, r"😅") == [(4, 2), (6, 2)]
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
