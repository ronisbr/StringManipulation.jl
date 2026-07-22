## Description #############################################################################
#
# Tests for prepared text layouts.
#
############################################################################################

@testset "Prepared text layout" begin
    lines = [
        "",
        "plain ASCII text",
        "αβγδé",
        "你a好b😃c",
        "a\u0301b\u0301c",
        "\e[31mred\e[39m default \e[1mbold\e[22m",
        "\e[38;5;201mindexed\e[48;2;1;2;3m true color\e[0m",
        "\e]8;;https://example.com\e\\link\e]8;;\e\\ tail",
        "",
    ]
    layout = TextViewLayout(lines; checkpoint_stride = 2, ansi_checkpoint_stride = 2)

    @test layout.lines == lines
    @test string_search_per_line(layout, r"a|red") ==
        string_search_per_line(lines, r"a|red")
    @test TextViewLayout("a\n").lines == ["a", ""]

    views = (
        (1, -1, 1, -1),
        (1, 9, 1, 0),
        (1, 9, 1, 1),
        (2, 6, 2, 4),
        (3, 5, 4, 5),
        (8, 20, 20, 4),
    )
    options = (
        (;),
        (; frozen_columns_at_beginning = 2),
        (; frozen_lines_at_beginning = 2, title_lines = 1),
        (; frozen_lines_at_beginning = 2, title_lines = 1, hide_title_lines = true),
        (; show_ruler = true),
        (; maximum_number_of_lines = 4, maximum_number_of_columns = 5),
        (; visual_lines = [2, 4], visual_line_backgrounds = ["44", "45"]),
        (; parse_decorations_before_view = true),
    )

    for view in views, kwargs in options
        @test textview(layout, view; kwargs...) == textview(lines, view; kwargs...)

        prepared_buffer = IOBuffer()
        raw_buffer = IOBuffer()
        prepared_result = textview(prepared_buffer, layout, view; kwargs...)
        raw_result = textview(raw_buffer, lines, view; kwargs...)
        @test prepared_result == raw_result
        @test String(take!(prepared_buffer)) == String(take!(raw_buffer))
    end

    matches = string_search_per_line(layout, r"a|red|link")
    for view in views
        @test textview(layout, view; search_matches = matches, active_match = 3) ==
            textview(lines, view; search_matches = matches, active_match = 3)
    end

    global_active = textview(
        layout, (1, -1, 1, -1); search_matches = matches, active_match = 1
    )
    located_active = textview(
        layout,
        (1, -1, 1, -1);
        search_matches = matches,
        active_match = 1,
        active_match_location = (6, 1),
    )
    expected_location = textview(
        lines, (1, -1, 1, -1); search_matches = matches, active_match = 4
    )
    @test located_active == expected_location
    @test located_active != global_active

    @test textview(
        layout, (9, 1, 1, 5); frozen_lines_at_beginning = 9, maximum_number_of_lines = 3
    ) == textview(
        lines, (9, 1, 1, 5); frozen_lines_at_beginning = 9, maximum_number_of_lines = 3
    )

    hidden_ansi_lines = [
        "\e[31mred",
        "\e[0m\e[38;2;1;2;3m\e]8;;https://example.com\e\\hidden",
        "visible\e]8;;\e\\",
    ]
    hidden_ansi_layout = TextViewLayout(hidden_ansi_lines; ansi_checkpoint_stride = 1)
    @test textview(
        hidden_ansi_layout, (3, 1, 1, 7); parse_decorations_before_view = true
    ) == textview(hidden_ansi_lines, (3, 1, 1, 7); parse_decorations_before_view = true)

    deep_lines = [i == 900 ? "\e[34mneedle" : "line $i" for i in 1:1000]
    deep_layout = TextViewLayout(deep_lines)
    deep_matches = string_search_per_line(deep_layout, r"needle")
    @test textview(
        deep_layout,
        (900, 1, 1, 6);
        search_matches = deep_matches,
        active_match_location = (900, 1),
        parse_decorations_before_view = true,
    ) == textview(
        deep_lines,
        (900, 1, 1, 6);
        search_matches = deep_matches,
        active_match = 1,
        parse_decorations_before_view = true,
    )

    malformed = ["before\e[31unterminated after"]
    malformed_layout = TextViewLayout(malformed)
    @test malformed_layout.ansi_fallback == BitVector([true])
    @test textview(malformed_layout, (1, 1, 2, 8)) == textview(malformed, (1, 1, 2, 8))
end

@testset "Prepared metadata bounds" begin
    short_ascii = TextViewLayout(fill("x"^100, 24))
    wide_ascii = TextViewLayout(fill("x"^100_000, 24))
    @test sum(length, short_ascii.seek_checkpoints) == 0
    @test sum(length, wide_ascii.seek_checkpoints) == 0
    @test sum(length, wide_ascii.ansi_events) == 0
    @test count(wide_ascii.plain_ascii) == 24

    unicode_line = repeat("α\u0301你", 1000)
    unicode_layout = TextViewLayout([unicode_line]; checkpoint_stride = 64)
    @test length(unicode_layout.seek_checkpoints[1]) ≤ cld(length(unicode_line), 64) + 1

    ansi_line = join(("\e[$(30 + i % 8)mX" for i in 1:100)) * "\e[0m"
    ansi_layout = TextViewLayout([ansi_line]; ansi_checkpoint_stride = 16)
    @test length(ansi_layout.ansi_events[1]) == 101
    @test length(ansi_layout.ansi_prefix_checkpoints[1]) == 101 ÷ 16
    @test length(ansi_layout.ansi_suffix_checkpoints[1]) == cld(101, 16)
    @test textview(ansi_layout, (1, 1, 40, 10)) == textview([ansi_line], (1, 1, 40, 10))
end

@testset "Prepared ANSI boundaries and transitions" begin
    wide_line = "你\e[31mX\e[0m"
    @test textview(TextViewLayout([wide_line]), (1, 1, 1, 1)) == (" \e[31m\e[0m", 0, 2)
    @test textview(TextViewLayout([wide_line]), (1, 1, 2, 1)) == ("\e[31m \e[0m", 0, 1)
    wide_matches = string_search_per_line([wide_line], r"X")
    wide_options = (
        (;),
        (; frozen_columns_at_beginning = 1),
        (; visual_lines = [1]),
        (; search_matches = wide_matches, active_match = 1),
        (; frozen_columns_at_beginning = 1, visual_lines = [1]),
        (;
            frozen_columns_at_beginning = 1, search_matches = wide_matches, active_match = 1
        ),
    )
    for view in ((1, 1, 1, 1), (1, 1, 2, 1), (1, 1, 3, 1)), kwargs in wide_options
        raw = textview([wide_line], view; kwargs...)
        for stride in (1, 2, 32)
            prepared = textview(
                TextViewLayout([wide_line]; ansi_checkpoint_stride = stride),
                view;
                kwargs...,
            )
            @test prepared == raw
        end
    end

    open_url = "\e]8;;url\e\\"
    close_url = "\e]8;;\e\\"
    transition_sequences = (
        "\e[0m" * open_url,
        open_url * "\e[31m",
        "\e[0m" * open_url * "\e[31m",
        open_url * "\e[0m",
        close_url * open_url,
        "\e[39m\e[49m",
        "\e[38;2;1;2;3m\e[48;5;201m",
        "\e[1m\e[3m\e[4m\e[7m\e[22m\e[23m\e[24m\e[27m",
    )
    oracle_lines = ("AB\e[0m$(open_url)C", "AB\e[0m$(open_url)\e[31mC")
    @test textview(TextViewLayout([oracle_lines[1]]), (1, 1, 1, 1)) ==
        ("A$(open_url)\e[0m", 0, 2)
    @test textview(TextViewLayout([oracle_lines[2]]), (1, 1, 1, 1)) ==
        ("A$(open_url)\e[31m", 0, 2)
    for line in
        (oracle_lines..., ("AB" * sequence * "C" for sequence in transition_sequences)...)
        raw = textview([line], (1, 1, 1, 1))
        for stride in (1, 2, 32)
            layout = TextViewLayout([line]; ansi_checkpoint_stride = stride)
            @test textview(layout, (1, 1, 1, 1)) == raw
        end
    end

    zero_width_ansi = "a\u0301" * repeat("\e[31m", 40) * "b"
    for stride in (1, 2, 32)
        @test textview(
            TextViewLayout([zero_width_ansi]; ansi_checkpoint_stride = stride), (1, 1, 2, 1)
        ) == textview([zero_width_ansi], (1, 1, 2, 1))
    end
end

@testset "Dense ANSI seek checkpoints" begin
    event_count = 100_000
    stride = 32
    dense_events = repeat("\e[31m", event_count)
    cases = (
        (dense_events * "X", (1, 1, 2, 1)),
        ("X" * dense_events * "Y", (1, 1, 2, 1)),
        (dense_events, (1, 1, 2, 1)),
    )
    for (line, view) in cases
        layout = TextViewLayout([line]; ansi_checkpoint_stride = stride)
        @test length(layout.ansi_events[1]) == event_count
        @test length(layout.seek_checkpoints[1]) ≥ event_count ÷ stride
        @test textview(layout, view) == textview([line], view)

        buffer = IOBuffer()
        textview(buffer, layout, view)
        truncate(buffer, 0)
        seekstart(buffer)
        allocated = @allocated textview(buffer, layout, view)
        @test allocated < 64_000
    end
end
