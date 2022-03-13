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

@testset "Fit field" begin
    str = "Test 😅 \e[38;5;231;48;5;243mTest 😅 \e[38;5;201;48;5;243mTest\e[0m"
    printable_string_width = printable_textwidth(str)

    # Cropping from the right
    # ==========================================================================

    cropped_str = fit_string_in_field(str, 8)
    expected = "Test 😅…\e[38;5;231;48;5;243m\e[38;5;201;48;5;243m\e[0m"
    @test cropped_str == expected

    cropped_str = fit_string_in_field(
        str,
        8;
        printable_string_width
    )
    expected = "Test 😅…\e[38;5;231;48;5;243m\e[38;5;201;48;5;243m\e[0m"
    @test cropped_str == expected

    cropped_str = fit_string_in_field(str, 8; add_space_in_continuation_char = true)
    expected = "Test   …\e[38;5;231;48;5;243m\e[38;5;201;48;5;243m\e[0m"
    @test cropped_str == expected

    cropped_str = fit_string_in_field(
        str,
        8;
        add_space_in_continuation_char = true,
        keep_ansi = false
    )
    expected = "Test   …"
    @test cropped_str == expected

    # Cropping from the left
    # ==========================================================================

    cropped_str = fit_string_in_field(str, 8; crop_side = :left)
    expected = "\e[38;5;231;48;5;243m…😅 \e[38;5;201;48;5;243mTest\e[0m"
    @test cropped_str == expected

    cropped_str = fit_string_in_field(
        str,
        8;
        crop_side = :left,
        printable_string_width
    )
    expected = "\e[38;5;231;48;5;243m…😅 \e[38;5;201;48;5;243mTest\e[0m"
    @test cropped_str == expected

    cropped_str = fit_string_in_field(
        str,
        8;
        add_space_in_continuation_char = true,
        crop_side = :left
    )
    expected = "\e[38;5;231;48;5;243m…   \e[38;5;201;48;5;243mTest\e[0m"
    @test cropped_str == expected
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

    # Test passing the string printable width.
    printable_string_width = printable_textwidth(str)
    expected = "Test 😅 \e[38;5;231;48;5;243mTest 😅\e[38;5;201;48;5;243m\e[0m"
    cropped_str = *(right_crop(str, 5; printable_string_width)...)
    @test cropped_str == expected
end

@testset "Corner cases" begin
    str = "Test 😅 \e[38;5;231;48;5;243mTest 😅 \e[38;5;201;48;5;243mTest\e[0m"
    cropped_str = fit_string_in_field(str, 25)
    @test cropped_str == str

    expected = "…\e[38;5;231;48;5;243m\e[38;5;201;48;5;243m\e[0m"
    cropped_str = fit_string_in_field(str, 0)
    @test cropped_str == expected

    expected = "…"
    cropped_str = fit_string_in_field(str, 0; keep_ansi = false)
    @test cropped_str == expected
end
