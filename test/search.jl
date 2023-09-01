# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
# ==========================================================================================
#
#   Tests related with string searching.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

@testset "String Search" begin
    str = """
        Test 1 😅 \e[38;5;231;48;5;243mTest 2 😅 \e[38;5;201;48;5;243mTest\e[0m
        Test 1 😅 \e[38;5;231;48;5;243mTest 2 😅 \e[38;5;201;48;5;243mTest\e[0m
        """

    expected = [
        (11, 9),
        (35, 9)
    ]
    search_result = string_search(str, r"Test 2 😅")
    @test search_result == expected
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
