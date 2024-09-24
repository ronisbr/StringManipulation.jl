# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
# ==========================================================================================
#
#   Tests related to the string cropping.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

@testset "Left Cropping" begin
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

    # == Hyperlinks (OSC 8) ================================================================

    str = "\e]8;;https://ronanarraes.com\e\\My Website\e]8;;\e\\ Test Test"

    expected_left = "\e]8;;https://ronanarraes.com\e\\"
    expected_right = "y Website\e]8;;\e\\ Test Test"
    r = left_crop(str, 1)

    @test first(r) == expected_left
    @test last(r)  == expected_right

    str = "\e]8;;https://ronanarraes.com\e\\My Website\e]8;;\e\\ Test Test"

    expected_left = "\e]8;;https://ronanarraes.com\e\\\e]8;;\e\\"
    expected_right = "est Test"
    r = left_crop(str, 12)

    @test first(r) == expected_left
    @test last(r)  == expected_right

    str = "Test \e]8;;https://ronanarraes.com\e\\My Website\e]8;;\e\\ Test Test"

    expected_left = ""
    expected_right = "t \e]8;;https://ronanarraes.com\e\\My Website\e]8;;\e\\ Test Test"
    r = left_crop(str, 3)

    @test first(r) == expected_left
    @test last(r)  == expected_right
end

@testset "Fit Field" begin
    str = "Test 😅 \e[38;5;231;48;5;243mTest 😅 \e[38;5;201;48;5;243mTest\e[0m"
    printable_string_width = printable_textwidth(str)

    # Cropping from The Right
    # ======================================================================================

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
        keep_escape_seq = false
    )
    expected = "Test   …"
    @test cropped_str == expected

    # Cropping from The Left
    # ======================================================================================

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

    # == Hyperlinks (OSC 8) ================================================================

    str = "\e]8;;https://ronanarraes.com\e\\My Website\e]8;;\e\\ Test Test"

    expected = "\e]8;;https://ronanarraes.com\e\\My W …\e]8;;\e\\"
    cropped_str = fit_string_in_field(
        str,
        6;
        add_space_in_continuation_char = true,
        crop_side = :right
    )

    @test cropped_str == expected

    expected = "\e]8;;https://ronanarraes.com\e\\My Website\e]8;;\e\\ T …"

    cropped_str = fit_string_in_field(
        str,
        14;
        add_space_in_continuation_char = true,
        crop_side = :right
    )

    @test cropped_str == expected

    expected = "\e]8;;https://ronanarraes.com\e\\\e]8;;\e\\… Test"

    cropped_str = fit_string_in_field(
        str,
        6;
        add_space_in_continuation_char = true,
        crop_side = :left
    )

    @test cropped_str == expected

    expected = "\e]8;;https://ronanarraes.com\e\\… e\e]8;;\e\\ Test Test"

    cropped_str = fit_string_in_field(
        str,
        13;
        add_space_in_continuation_char = true,
        crop_side = :left
    )

    @test cropped_str == expected
end

@testset "Right Cropping" begin
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

    # == Hyperlinks (OSC 8) ================================================================

    str = "\e]8;;https://ronanarraes.com\e\\My Website\e]8;;\e\\ Test Test"

    expected_left = "\e]8;;https://ronanarraes.com\e\\My Website\e]8;;\e\\ Test"
    expected_right = ""
    r = right_crop(str, 5)

    @test first(r) == expected_left
    @test last(r)  == expected_right

    str = "\e]8;;https://ronanarraes.com\e\\My Website\e]8;;\e\\ Test Test"

    expected_left = "\e]8;;https://ronanarraes.com\e\\My Websi"
    expected_right = "\e]8;;\e\\"
    r = right_crop(str, 12)

    @test first(r) == expected_left
    @test last(r)  == expected_right

    r = right_crop(str, 12; keep_escape_seq = false)
    @test first(r) == expected_left
    @test last(r)  == ""

    str = "Test \e]8;;https://ronanarraes.com\e\\My Website\e]8;;\e\\ Test Test"

    expected_left = "Test"
    expected_right = "\e]8;;https://ronanarraes.com\e\\\e]8;;\e\\"
    r = right_crop(str, 21)

    @test first(r) == expected_left
    @test last(r)  == expected_right
end

@testset "Corner Cases" begin
    str = "Test 😅 \e[38;5;231;48;5;243mTest 😅 \e[38;5;201;48;5;243mTest\e[0m"
    cropped_str = fit_string_in_field(str, 25)
    @test cropped_str == str

    expected = "…\e[38;5;231;48;5;243m\e[38;5;201;48;5;243m\e[0m"
    cropped_str = fit_string_in_field(str, 0)
    @test cropped_str == expected

    expected = "…"
    cropped_str = fit_string_in_field(str, 0; keep_escape_seq = false)
    @test cropped_str == expected
end
