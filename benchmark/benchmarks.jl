using BenchmarkTools
using StringManipulation

function reset_buffer!(buffer)
    truncate(buffer, 0)
    seekstart(buffer)
    return buffer
end

function render!(buffer, source, view; kwargs...)
    textview(buffer, source, view; kwargs...)
    return nothing
end

function report(name, trial)
    estimate = median(trial)
    println(rpad(name, 32), estimate.time / 1e6, " ms, ", estimate.memory, " bytes")
    return estimate
end

wide_lines = fill("x"^100_000, 24)
short_lines = fill("x"^100, 24)
unicode_lines = fill(repeat("α你😃e\u0301", 20_000), 24)
ansi_lines = fill(repeat("\e[31mred\e[0m plain ", 10_000), 24)
search_lines = fill("prefix needle suffix "^5000, 24)
dense_events = repeat("\e[31m", 100_000)
dense_small_events = repeat("\e[31m", 1_000)
dense_leading_lines = [dense_events * "X"]
dense_after_text_lines = ["X" * dense_events * "Y"]
dense_only_lines = [dense_events]
many_short_lines = ["line $i" for i in 1:100_000]

wide_layout = TextViewLayout(wide_lines)
short_layout = TextViewLayout(short_lines)
unicode_layout = TextViewLayout(unicode_lines)
ansi_layout = TextViewLayout(ansi_lines)
search_layout = TextViewLayout(search_lines)
matches = string_search_per_line(search_layout, r"needle")
dense_leading_layout = TextViewLayout(dense_leading_lines)
dense_after_text_layout = TextViewLayout(dense_after_text_lines)
dense_only_layout = TextViewLayout(dense_only_lines)
dense_small_layout = TextViewLayout([dense_small_events * "X"])
many_short_layout = TextViewLayout(many_short_lines)
buffer = IOBuffer()

report("layout / ASCII width 100k", @benchmark TextViewLayout($wide_lines))
report("prepared first render", @benchmark render!($buffer, $wide_layout, (1, 24, 1, 100)) setup=(reset_buffer!($buffer)) evals=1 samples=1)
prepared_column_1 = report("prepared repeated / column 1", @benchmark render!($buffer, $wide_layout, (1, 24, 1, 100)) setup=(reset_buffer!($buffer)))
prepared_midpoint = report("prepared repeated / midpoint", @benchmark render!($buffer, $wide_layout, (1, 24, 50_000, 100)) setup=(reset_buffer!($buffer)))
raw_midpoint = report("raw / midpoint", @benchmark render!($buffer, $wide_lines, (1, 24, 50_000, 100)) setup=(reset_buffer!($buffer)) samples=20)
prepared_short = report("prepared / width 100", @benchmark render!($buffer, $short_layout, (1, 24, 1, 100)) setup=(reset_buffer!($buffer)))
report("prepared Unicode / midpoint", @benchmark render!($buffer, $unicode_layout, (1, 24, 50_000, 100)) setup=(reset_buffer!($buffer)))
report("prepared ANSI / midpoint", @benchmark render!($buffer, $ansi_layout, (1, 24, 50_000, 100)) setup=(reset_buffer!($buffer)))
report("prepared search", @benchmark render!($buffer, $search_layout, (1, 24, 20_000, 100); search_matches=$matches, active_match_location=(1, 1000)) setup=(reset_buffer!($buffer)))
report("layout / 100k leading ANSI", @benchmark TextViewLayout($dense_leading_lines))
dense_small = report("dense ANSI / 1k leading", @benchmark render!($buffer, $dense_small_layout, (1, 1, 2, 1)) setup=(reset_buffer!($buffer)))
dense_leading = report("dense ANSI / 100k leading", @benchmark render!($buffer, $dense_leading_layout, (1, 1, 2, 1)) setup=(reset_buffer!($buffer)))
dense_raw = report("raw dense ANSI / 100k", @benchmark render!($buffer, $dense_leading_lines, (1, 1, 2, 1)) setup=(reset_buffer!($buffer)) samples=20)
report("dense ANSI / after text", @benchmark render!($buffer, $dense_after_text_layout, (1, 1, 2, 1)) setup=(reset_buffer!($buffer)))
report("dense ANSI / no text", @benchmark render!($buffer, $dense_only_layout, (1, 1, 2, 1)) setup=(reset_buffer!($buffer)))

println("raw/prepared midpoint ratio: ", raw_midpoint.time / prepared_midpoint.time)
println("wide/short prepared ratio: ", prepared_midpoint.time / prepared_short.time)
println("dense 100k/1k prepared ratio: ", dense_leading.time / dense_small.time)
println("dense raw/prepared ratio: ", dense_raw.time / dense_leading.time)
println("ASCII metadata: ", (
    seek_checkpoints = sum(length, wide_layout.seek_checkpoints),
    ansi_events = sum(length, wide_layout.ansi_events)
))
many_short_size = Base.summarysize(many_short_layout)
println("100k short-line layout: ", (
    bytes = many_short_size,
    bytes_per_line = many_short_size / length(many_short_lines)
))
