# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
# ==============================================================================
#
#   Tests related to the string cropping.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

@testset "Left cropping" begin
    str = "Test 😅 \e[38;5;231;48;5;243mTest 😅 \e[38;5;201;48;5;243mTest\e[0m"

    expected = "😅 \e[38;5;231;48;5;243mTest 😅 \e[38;5;201;48;5;243mTest\e[0m"
    cropped_str = *(left_crop(str, 5)...)
    @test cropped_str == expected

    expected = "  \e[38;5;231;48;5;243mTest 😅 \e[38;5;201;48;5;243mTest\e[0m"
    cropped_str = *(left_crop(str, 6)...)
    @test cropped_str == expected

    expected = "\e[38;5;231;48;5;243mst 😅 \e[38;5;201;48;5;243mTest\e[0m"
    cropped_str = *(left_crop(str, 10)...)
    @test cropped_str == expected

    expected = "\e[38;5;231;48;5;243m\e[38;5;201;48;5;243mest\e[0m"
    cropped_str = *(left_crop(str, 17)...)
    @test cropped_str == expected

    ansi_escape_seq, ~ = left_crop(str, 17)
    @test ansi_escape_seq == "\e[38;5;231;48;5;243m\e[38;5;201;48;5;243m"
end

@testset "Right cropping" begin
    str = "Test 😅 \e[38;5;231;48;5;243mTest 😅 \e[38;5;201;48;5;243mTest\e[0m"

    expected = "Test 😅 \e[38;5;231;48;5;243mTest 😅\e[38;5;201;48;5;243m\e[0m"
    cropped_str = *(right_crop(str, 5)...)
    @test cropped_str == expected

    expected = "Test 😅 \e[38;5;231;48;5;243mTest  \e[38;5;201;48;5;243m\e[0m"
    cropped_str = *(right_crop(str, 6)...)
    @test cropped_str == expected

    expected = "Test 😅\e[38;5;231;48;5;243m\e[38;5;201;48;5;243m\e[0m"
    cropped_str = *(right_crop(str, 13)...)
    @test cropped_str == expected

    expected = "Test  \e[38;5;231;48;5;243m\e[38;5;201;48;5;243m\e[0m"
    cropped_str = *(right_crop(str, 14)...)
    @test cropped_str == expected

    ~, ansi_escape_seq = right_crop(str, 14)
    @test ansi_escape_seq == "\e[38;5;231;48;5;243m\e[38;5;201;48;5;243m\e[0m"
end
