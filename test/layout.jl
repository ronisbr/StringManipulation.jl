## Description #############################################################################
#
# Tests for prepared text layouts.
#
############################################################################################

"""
    _ansi_character_trace(str::String) -> Vector{Pair{Char, Decoration}}

Convert `str` into visible characters paired with their effective decorations.

# Arguments

- `str::String`: Decorated string to trace.

# Returns

- `Vector{Pair{Char, Decoration}}`: Visible-character decoration trace.
"""
function _ansi_character_trace(str::String)
    trace = Pair{Char, Decoration}[]
    for (token, decoration) in parse_ansi_string(str), character in token
        push!(trace, character => decoration)
    end
    return trace
end

"""
    _terminal_decoration_state(str::String) -> Decoration

Return the final terminal decoration state produced by `str`.

# Arguments

- `str::String`: Decorated string to summarize.

# Returns

- `Decoration`: Final decoration state.
"""
function _terminal_decoration_state(str::String)
    return parse_decoration(get_decorations(str))
end

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

    @test string_search_per_line(layout, r"a|red") ==
        string_search_per_line(lines, r"a|red")
    @test textview(TextViewLayout("a\n"), (1, -1, 1, -1)) ==
        textview(["a", ""], (1, -1, 1, -1))

    owned_lines = ["before", "snapshot"]
    owned_layout = TextViewLayout(owned_lines)
    expected_snapshot = textview(owned_layout, (1, -1, 1, -1))
    owned_lines[1] = "after"
    push!(owned_lines, "new")
    @test textview(owned_layout, (1, -1, 1, -1)) == expected_snapshot
    @test !applicable(
        TextViewLayout,
        owned_layout._lines,
        owned_layout._printable_widths,
        owned_layout._plain_ascii,
        owned_layout._ansi_fallback,
        owned_layout._metadata,
        owned_layout._document_ansi_checkpoints,
        owned_layout._checkpoint_stride,
        owned_layout._ansi_checkpoint_stride,
    )
    @test length(methods(TextViewLayout)) == 2
    @test !isdefined(StringManipulation, :TextViewLayoutConstructionToken)

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

    sparse_lines = [i in (1, 2, 500, 900) ? "match $i" : "line $i" for i in 1:1000]
    sparse_layout = TextViewLayout(sparse_lines)
    sparse_matches = string_search_per_line(sparse_lines, r"match")
    sparse_options = (
        (; active_match = 4),
        (; active_match = 4, frozen_lines_at_beginning = 3),
        (;
            active_match = 4,
            frozen_lines_at_beginning = 3,
            title_lines = 2,
            hide_title_lines = true,
        ),
    )
    for kwargs in sparse_options
        @test textview(
            sparse_layout, (900, 1, 1, -1); search_matches = sparse_matches, kwargs...
        ) == textview(
            sparse_lines, (900, 1, 1, -1); search_matches = sparse_matches, kwargs...
        )
    end

    malformed = ["before\e[31unterminated after"]
    malformed_layout = TextViewLayout(malformed)
    @test textview(malformed_layout, (1, 1, 2, 8)) == textview(malformed, (1, 1, 2, 8))
end

@testset "Prepared constructor validation" begin
    for stride in (0, -1)
        @test_throws ArgumentError TextViewLayout(["text"]; checkpoint_stride = stride)
        @test_throws ArgumentError TextViewLayout(["text"]; ansi_checkpoint_stride = stride)
    end

    @test textview(TextViewLayout(""), (1, -1, 1, -1)) == ("", 0, 0)
    @test textview(TextViewLayout(String[]), (1, -1, 1, -1)) == ("", 0, 0)
end

@testset "Prepared read-only vector interface" begin
    input_lines = ["first", "α你", "\e[31mred\e[0m"]
    layout = TextViewLayout(input_lines)

    @test TextViewLayout <: AbstractVector{String}
    @test eltype(TextViewLayout) === String
    @test eltype(layout) === String
    @test Base.IndexStyle(TextViewLayout) === IndexLinear()
    @test size(layout) == (3,)
    @test length(layout) == 3
    @test axes(layout) == (Base.OneTo(3),)
    @test eachindex(layout) == Base.OneTo(3)
    @test firstindex(layout) == 1
    @test lastindex(layout) == 3
    @test (@inferred layout[1]) == "first"
    @test layout[2:3] == ["α你", "\e[31mred\e[0m"]
    first_iteration = @inferred Union{
        Nothing,
        Tuple{String, Tuple{Base.OneTo{Int}, Int}},
    } iterate(layout)
    @test first_iteration[1] == "first"
    second_iteration = @inferred Union{
        Nothing,
        Tuple{String, Tuple{Base.OneTo{Int}, Int}},
    } iterate(layout, first_iteration[2])
    @test second_iteration[1] == "α你"
    @test collect(layout) == input_lines

    mutable_copy = collect(layout)
    mutable_copy[1] = "changed"
    push!(mutable_copy, "new")
    @test layout[1] == "first"
    @test length(layout) == 3

    input_lines[1] = "source changed"
    push!(input_lines, "source added")
    @test collect(layout) == ["first", "α你", "\e[31mred\e[0m"]
    @test !hasproperty(layout, :lines)
    @test_throws BoundsError layout[0]
    @test_throws BoundsError layout[4]
    @test_throws Base.CanonicalIndexError setindex!(layout, "changed", 1)
    @test_throws MethodError push!(layout, "new")
    @test which(setindex!, (TextViewLayout, String, Int)).module === Base
    @test which(push!, (TextViewLayout, String)).module === Base

    empty_layout = TextViewLayout(String[])
    @test size(empty_layout) == (0,)
    @test length(empty_layout) == 0
    @test axes(empty_layout) == (Base.OneTo(0),)
    @test eachindex(empty_layout) == Base.OneTo(0)
    @test iterate(empty_layout) === nothing
    @test collect(empty_layout) == String[]
    @test_throws BoundsError empty_layout[1]
    @test collect(TextViewLayout("")) == [""]

    @test which(textview, (TextViewLayout, NTuple{4, Int})).sig.parameters[2] ===
        TextViewLayout
    @test which(string_search_per_line, (TextViewLayout, Regex)).sig.parameters[2] ===
        TextViewLayout
    @test textview(layout, (1, -1, 1, -1)) == textview(collect(layout), (1, -1, 1, -1))
    @test string_search_per_line(layout, r"red") ==
        string_search_per_line(collect(layout), r"red")
end

@testset "Prepared differential corpus" begin
    open_url = "\e]8;;https://example.com\e\\"
    close_url = "\e]8;;\e\\"
    corpus = (
        "你a\u0301\e[31mB\e[0m",
        "X\e[31m\e[0m\e[1mY",
        "你$(open_url)e\u0301$(close_url)Z",
        "a\u0301\e[38;2;1;2;3m你\e[0m$(open_url)b$(close_url)",
    )
    boundary_views = ((1, 1, 1, 0), (1, 1, 1, 1), (1, 1, 2, 1), (1, 1, 3, 2), (1, 1, 5, 1))

    for line in corpus, stride in (1, 2, 3, 32)
        layout = TextViewLayout(
            [line]; checkpoint_stride = stride, ansi_checkpoint_stride = stride
        )
        @test textview(layout, (1, 1, 1, -1)) == textview([line], (1, 1, 1, -1))

        for view in boundary_views
            prepared = textview(layout, view)
            raw = textview([line], view)
            @test _ansi_character_trace(prepared[1]) == _ansi_character_trace(raw[1])
            @test _terminal_decoration_state(prepared[1]) ==
                _terminal_decoration_state(raw[1])
            @test prepared[2:3] == raw[2:3]
        end
    end

    linked_then_unlinked = "$(open_url)A$(close_url)B"
    red_then_default = "\e[31mA\e[0mB"
    state_cases = (linked_then_unlinked, red_then_default)
    state_views = ((1, 1, 1, -1), (1, 1, 1, 1), (1, 1, 2, 1))

    for line in state_cases, stride in (1, 2, 3, 32), view in state_views
        raw = textview([line], view)
        prepared = textview(TextViewLayout([line]; ansi_checkpoint_stride = stride), view)
        @test _ansi_character_trace(prepared[1]) == _ansi_character_trace(raw[1])
        @test _terminal_decoration_state(prepared[1]) ==
            _terminal_decoration_state(raw[1])
        @test prepared[2:3] == raw[2:3]
        view[4] < 0 && (@test prepared == raw)
    end

    linked_trace = _ansi_character_trace(
        textview([linked_then_unlinked], (1, 1, 1, -1))[1]
    )
    @test first(linked_trace).second.hyperlink_url == "https://example.com"
    @test last(linked_trace).second.hyperlink_url == ""
    red_trace = _ansi_character_trace(
        textview([red_then_default], (1, 1, 1, -1))[1]
    )
    @test first(red_trace).second.foreground == "31"
    @test last(red_trace).second.reset
end

@testset "Prepared inference" begin
    lines = ["title", "α你e\u0301", "\e[31mred\e[0m", "plain red"]
    layout = @inferred TextViewLayout(
        lines; checkpoint_stride = 2, ansi_checkpoint_stride = 1
    )
    matches = @inferred string_search_per_line(layout, r"red")
    @test matches == Dict(3 => [(1, 3)], 4 => [(7, 3)])

    basic_buffer = IOBuffer()
    basic_result = @inferred textview(basic_buffer, layout, (2, 2, 1, 4))
    @test basic_result isa Tuple{Int, Int}

    overlay_buffer = IOBuffer()
    overlay_result = @inferred textview(
        overlay_buffer,
        layout,
        (3, 2, 2, 5);
        frozen_columns_at_beginning = 1,
        frozen_lines_at_beginning = 1,
        maximum_number_of_columns = 10,
        maximum_number_of_lines = 3,
        search_matches = matches,
        show_ruler = true,
        title_lines = 1,
        visual_line_backgrounds = ["44"],
        visual_lines = [4],
    )
    @test overlay_result isa Tuple{Int, Int}
end

@testset "Prepared metadata bounds" begin
    short_ascii = TextViewLayout(fill("x"^100, 24))
    wide_ascii = TextViewLayout(fill("x"^100_000, 24))
    @test all(isnothing, short_ascii._metadata)
    @test all(isnothing, wide_ascii._metadata)
    @test count(wide_ascii._plain_ascii) == 24

    unicode_line = repeat("α\u0301你", 1000)
    unicode_layout = TextViewLayout([unicode_line]; checkpoint_stride = 64)
    unicode_metadata = unicode_layout._metadata[1]
    @test length(unicode_metadata.seek_checkpoints) ≤ cld(length(unicode_line), 64) + 1

    ansi_line = join(("\e[$(30 + i % 8)mX" for i in 1:100)) * "\e[0m"
    ansi_layout = TextViewLayout([ansi_line]; ansi_checkpoint_stride = 16)
    ansi_metadata = ansi_layout._metadata[1]
    @test length(ansi_metadata.ansi_events) == 101
    @test length(ansi_metadata.ansi_prefix_checkpoints) == 101 ÷ 16
    @test length(ansi_metadata.ansi_suffix_checkpoints) == cld(101, 16)
    prepared_ansi = textview(ansi_layout, (1, 1, 40, 10))
    raw_ansi = textview([ansi_line], (1, 1, 40, 10))
    @test remove_decorations(prepared_ansi[1]) == remove_decorations(raw_ansi[1])
    @test parse_decoration(get_decorations(prepared_ansi[1])) ==
        parse_decoration(get_decorations(raw_ansi[1]))
    @test prepared_ansi[2:3] == raw_ansi[2:3]
end

@testset "Prepared ANSI boundaries and transitions" begin
    terminal_equivalent = function (prepared::String, raw::String)
        return remove_decorations(prepared) == remove_decorations(raw) &&
               parse_decoration(get_decorations(prepared)) ==
               parse_decoration(get_decorations(raw))
    end

    wide_line = "你\e[31mX\e[0m"
    wide_prepared = textview(TextViewLayout([wide_line]), (1, 1, 1, 1))
    wide_raw = textview([wide_line], (1, 1, 1, 1))
    @test terminal_equivalent(wide_prepared[1], wide_raw[1])
    @test wide_prepared[2:3] == wide_raw[2:3]
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
            @test terminal_equivalent(prepared[1], raw[1])
            @test prepared[2:3] == raw[2:3]
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
    for line in
        (oracle_lines..., ("AB" * sequence * "C" for sequence in transition_sequences)...)
        raw = textview([line], (1, 1, 1, 1))
        for stride in (1, 2, 32)
            layout = TextViewLayout([line]; ansi_checkpoint_stride = stride)
            prepared = textview(layout, (1, 1, 1, 1))
            @test terminal_equivalent(prepared[1], raw[1])
            @test prepared[2:3] == raw[2:3]
        end
    end

    zero_width_ansi = "a\u0301" * repeat("\e[31m", 40) * "b"
    for stride in (1, 2, 32)
        @test textview(
            TextViewLayout([zero_width_ansi]; ansi_checkpoint_stride = stride), (1, 1, 2, 1)
        ) == textview([zero_width_ansi], (1, 1, 2, 1))
    end

    boundary_line = "X" * repeat("\e[31m", 100_000) * "Y"
    boundary_view = textview(TextViewLayout([boundary_line]), (1, 1, 1, 1))
    @test boundary_view == ("X\e[31m", 0, 1)
    @test ncodeunits(boundary_view[1]) < 32

    reset_line = "\e[31mX\e[0m\e[1mY"
    reset_and_links = (
        "\e[0m\e[1m$(open_url)",
        "$(open_url)\e[0m\e[1m",
        "\e[0m$(open_url)$(close_url)\e[1m",
        "$(open_url)\e[0m\e[1m$(close_url)",
    )
    for stride in (1, 2, 32)
        reset_output = textview(
            TextViewLayout([reset_line]; ansi_checkpoint_stride = stride), (1, 1, 1, 1)
        )[1]
        reset_state = parse_decoration(get_decorations(reset_output))
        @test remove_decorations(reset_output) == "X"
        @test reset_output == "\e[31mX\e[0m\e[1m"
        @test reset_state.bold == StringManipulation.active
        @test isempty(reset_state.foreground)

        for sequence in reset_and_links
            line = "X" * sequence * "Y"
            prepared = textview(
                TextViewLayout([line]; ansi_checkpoint_stride = stride), (1, 1, 1, 1)
            )[1]
            raw = textview([line], (1, 1, 1, 1))[1]
            @test remove_decorations(prepared) == remove_decorations(raw)
            @test parse_decoration(get_decorations(prepared)) ==
                parse_decoration(get_decorations(raw))
        end
    end

    wide_dense_cases = (
        (repeat("\e[31m", 100_000), " \e[31m"),
        (repeat(open_url, 100_000), " " * open_url),
        (repeat("\e[0m\e[1m", 50_000), " \e[0m\e[1m"),
    )
    for (events, expected) in wide_dense_cases
        output = textview(TextViewLayout(["你" * events * "X"]), (1, 1, 1, 1))[1]
        @test output == expected
        @test ncodeunits(output) < 64
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
        metadata = layout._metadata[1]
        @test length(metadata.ansi_events) == event_count
        @test length(metadata.seek_checkpoints) ≥ event_count ÷ stride
        @test textview(layout, view) == textview([line], view)

        buffer = IOBuffer()
        textview(buffer, layout, view)
        truncate(buffer, 0)
        seekstart(buffer)
        allocated = @allocated textview(buffer, layout, view)
        @test allocated < 64_000
    end

    compact_layout = TextViewLayout([dense_events * "X"]; ansi_checkpoint_stride = stride)
    compact_metadata = compact_layout._metadata[1]
    @test isbitstype(eltype(compact_metadata.ansi_events))
    @test sizeof(eltype(compact_metadata.ansi_events)) ≤ 32
    @test length(compact_metadata.ansi_transitions) == 1
    @test Base.summarysize(compact_layout) ≤ 6_120_000
end

@testset "High-cardinality ANSI metadata" begin
    event_count = 10_000
    unique_osc = "X" * join("\e]8;;url$(i)\e\\" for i in 1:event_count) * "Y"
    osc_layout = TextViewLayout([unique_osc])
    osc_metadata = osc_layout._metadata[1]
    @test length(osc_metadata.ansi_events) == event_count
    @test length(osc_metadata.ansi_transitions) == event_count
    @test isempty(osc_metadata.ansi_fallback_values)
    @test sizeof(eltype(osc_metadata.ansi_transitions)) ≤ 32
    @test Base.summarysize(osc_metadata.ansi_transitions) ≤ 48event_count + 1024
    osc_output = textview(osc_layout, (1, 1, 1, 1))[1]
    @test parse_decoration(get_decorations(osc_output)).hyperlink_url == "url10000"

    unique_colors =
        "X" *
        join(
            "\e[38;2;$(i % 256);$((i ÷ 256) % 256);$(i ÷ 65536)m" for
            i in 0:(event_count - 1)
        ) *
        "Y"
    color_layout = TextViewLayout([unique_colors])
    color_metadata = color_layout._metadata[1]
    @test length(color_metadata.ansi_events) == event_count
    @test length(color_metadata.ansi_transitions) == event_count
    @test isempty(color_metadata.ansi_fallback_values)
    @test Base.summarysize(color_metadata.ansi_transitions) ≤ 48event_count + 1024
    prepared = textview(color_layout, (1, 1, 1, 1))[1]
    raw = textview([unique_colors], (1, 1, 1, 1))[1]
    @test remove_decorations(prepared) == remove_decorations(raw)
    @test parse_decoration(get_decorations(prepared)) ==
        parse_decoration(get_decorations(raw))
end
