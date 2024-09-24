# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
# ==========================================================================================
#
#   Tests related to the string splitting.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

@testset "String Splitting" begin
    str = "Test 😅 \e[38;5;231;48;5;243mTest 😅 \e[38;5;201;48;5;243mTest\e[0m"

    result = split_string(str, -10)
    @test result == (
        "",
        "Test 😅 \e[38;5;231;48;5;243mTest 😅 \e[38;5;201;48;5;243mTest\e[0m"
    )

    result = split_string(str, 5)
    @test result == (
        "Test ",
        "😅 \e[38;5;231;48;5;243mTest 😅 \e[38;5;201;48;5;243mTest\e[0m"
    )

    result = split_string(str, 6)
    @test result == (
        "Test  ",
        "  \e[38;5;231;48;5;243mTest 😅 \e[38;5;201;48;5;243mTest\e[0m"
    )

    result = split_string(str, 6)
    @test result == (
        "Test  ",
        "  \e[38;5;231;48;5;243mTest 😅 \e[38;5;201;48;5;243mTest\e[0m"
    )

    result = split_string(str, 7)
    @test result == (
        "Test 😅",
        " \e[38;5;231;48;5;243mTest 😅 \e[38;5;201;48;5;243mTest\e[0m"
    )

    result = split_string(str, 8)
    @test result == (
        "Test 😅 \e[38;5;231;48;5;243m",
        "Test 😅 \e[38;5;201;48;5;243mTest\e[0m"
    )

    result = split_string(str, 13)
    @test result == (
        "Test 😅 \e[38;5;231;48;5;243mTest ",
        "😅 \e[38;5;201;48;5;243mTest\e[0m"
    )

    result = split_string(str, 14)
    @test result == (
        "Test 😅 \e[38;5;231;48;5;243mTest  ",
        "  \e[38;5;201;48;5;243mTest\e[0m"
    )

    result = split_string(str, 15)
    @test result == (
        "Test 😅 \e[38;5;231;48;5;243mTest 😅",
        " \e[38;5;201;48;5;243mTest\e[0m"
    )

    result = split_string(str, 1000)
    @test result == (
        "Test 😅 \e[38;5;231;48;5;243mTest 😅 \e[38;5;201;48;5;243mTest\e[0m",
        ""
    )

    # == Hyperlinks (OSC 8) ================================================================

    result = split_string("\e]8;;https://ronanarraes.com\e\\My Website\e]8;;\e\\ Test Test", 6)

    @test result == (
        "\e]8;;https://ronanarraes.com\e\\My Web",
        "site\e]8;;\e\\ Test Test"
    )
end
