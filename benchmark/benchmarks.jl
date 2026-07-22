using BenchmarkTools
using StringManipulation

const QUICK = "--quick" in ARGS
const BENCHMARK_SAMPLES = QUICK ? 3 : 20
const BENCHMARK_SECONDS = QUICK ? 0.2 : 2.0

"""
    reset_buffer!(buffer::IOBuffer) -> IOBuffer

Reset `buffer` for another benchmark evaluation.

# Arguments

- `buffer::IOBuffer`: Output buffer to truncate and rewind.

# Returns

- `IOBuffer`: Reset output buffer.
"""
function reset_buffer!(buffer::IOBuffer)
    truncate(buffer, 0)
    seekstart(buffer)
    return buffer
end

"""
    render!(
        buffer::IOBuffer,
        source::Union{Vector{<:AbstractString}, TextViewLayout},
        view::NTuple{4, Int};
        kwargs...
    ) -> Nothing

Render `source` into `buffer` for one benchmark evaluation.

# Arguments

- `buffer::IOBuffer`: Output buffer receiving the rendered view.
- `source::Union{Vector{<:AbstractString}, TextViewLayout}`: Source to render.
- `view::NTuple{4, Int}`: Viewport configuration.

# Keywords

- `kwargs...`: Forward all rendering options to [`textview`](@ref).

# Returns

- `Nothing`: This function returns no value.
"""
function render!(
    buffer::IOBuffer,
    source::Union{Vector{<:AbstractString}, TextViewLayout},
    view::NTuple{4, Int};
    kwargs...,
)
    textview(buffer, source, view; kwargs...)
    return nothing
end

"""
    report(
        name::AbstractString,
        trial::BenchmarkTools.Trial
    ) -> BenchmarkTools.TrialEstimate

Print the median timing and allocation estimate for `trial`.

# Arguments

- `name::AbstractString`: Label for the benchmark result.
- `trial::BenchmarkTools.Trial`: Completed benchmark trial.

# Returns

- `BenchmarkTools.TrialEstimate`: Median estimate for `trial`.
"""
function report(name::AbstractString, trial::BenchmarkTools.Trial)
    estimate = median(trial)
    println(
        rpad(name, 48),
        lpad(round(estimate.time / 1e6; digits = 3), 10),
        " ms, ",
        lpad(estimate.memory, 12),
        " warmed bytes",
    )
    return estimate
end

"""
    construction_trial(lines::Vector{String}) -> BenchmarkTools.Trial

Benchmark construction of a [`TextViewLayout`](@ref) for `lines`.

# Arguments

- `lines::Vector{String}`: Source lines to prepare during each evaluation.

# Returns

- `BenchmarkTools.Trial`: Completed construction benchmark.
"""
function construction_trial(lines::Vector{String})
    benchmark = @benchmarkable TextViewLayout($lines)
    return run(
        benchmark; samples = BENCHMARK_SAMPLES, seconds = BENCHMARK_SECONDS, evals = 1
    )
end

"""
    render_trial(
        buffer::IOBuffer,
        source::Union{Vector{<:AbstractString}, TextViewLayout},
        view::NTuple{4, Int};
        kwargs...
    ) -> BenchmarkTools.Trial

Benchmark warmed rendering of `source` into `buffer`.

# Arguments

- `buffer::IOBuffer`: Reusable output buffer.
- `source::Union{Vector{<:AbstractString}, TextViewLayout}`: Source to render.
- `view::NTuple{4, Int}`: Viewport configuration.

# Keywords

- `kwargs...`: Forward all rendering options to [`textview`](@ref).

# Returns

- `BenchmarkTools.Trial`: Completed warmed-rendering benchmark.
"""
function render_trial(
    buffer::IOBuffer,
    source::Union{Vector{<:AbstractString}, TextViewLayout},
    view::NTuple{4, Int};
    kwargs...,
)
    options = (; kwargs...)
    # Compile this exact rendering path before BenchmarkTools records warmed evaluations.
    reset_buffer!(buffer)
    render!(buffer, source, view; options...)
    benchmark = @benchmarkable render!($buffer, $source, $view; $options...) setup = (reset_buffer!(
        $buffer
    ))
    return run(
        benchmark; samples = BENCHMARK_SAMPLES, seconds = BENCHMARK_SECONDS, evals = 1
    )
end

"""
    search_trial(
        source::Union{Vector{<:AbstractString}, TextViewLayout},
        regex::Regex
    ) -> BenchmarkTools.Trial

Benchmark per-line searching of `source` with `regex`.

# Arguments

- `source::Union{Vector{<:AbstractString}, TextViewLayout}`: Source to search.
- `regex::Regex`: Regular expression to match.

# Returns

- `BenchmarkTools.Trial`: Completed search benchmark.
"""
function search_trial(source::Union{Vector{<:AbstractString}, TextViewLayout}, regex::Regex)
    string_search_per_line(source, regex)
    benchmark = @benchmarkable string_search_per_line($source, $regex)
    return run(
        benchmark; samples = BENCHMARK_SAMPLES, seconds = BENCHMARK_SECONDS, evals = 1
    )
end

"""
    break_even(
        name::AbstractString,
        construction::BenchmarkTools.TrialEstimate,
        raw_render::BenchmarkTools.TrialEstimate,
        prepared_render::BenchmarkTools.TrialEstimate
    ) -> Nothing

Print the estimated render count required to amortize preparation.

# Arguments

- `name::AbstractString`: Label for the compared workload.
- `construction::BenchmarkTools.TrialEstimate`: Median construction estimate.
- `raw_render::BenchmarkTools.TrialEstimate`: Median raw-render estimate.
- `prepared_render::BenchmarkTools.TrialEstimate`: Median prepared-render estimate.

# Returns

- `Nothing`: This function returns no value.
"""
function break_even(
    name::AbstractString,
    construction::BenchmarkTools.TrialEstimate,
    raw_render::BenchmarkTools.TrialEstimate,
    prepared_render::BenchmarkTools.TrialEstimate,
)
    saved_time = raw_render.time - prepared_render.time
    if saved_time > 0
        renders = construction.time / saved_time
        println(name, ": ", round(renders; digits = 2), " renders (median estimate)")
    else
        println(
            name,
            ": not available; prepared rendering was not faster in this run (median delta ",
            round(saved_time / 1e6; digits = 3),
            " ms)",
        )
    end
end

"""
    report_retained(
        name::AbstractString,
        source::Vector{String},
        layout::TextViewLayout
    ) -> Nothing

Print retained source and prepared-layout sizes.

# Arguments

- `name::AbstractString`: Label for the retained-size result.
- `source::Vector{String}`: Original source lines.
- `layout::TextViewLayout`: Prepared layout for `source`.

# Returns

- `Nothing`: This function returns no value.
"""
function report_retained(
    name::AbstractString, source::Vector{String}, layout::TextViewLayout
)
    source_size = Base.summarysize(source)
    layout_size = Base.summarysize(layout)
    return println(
        name,
        ": source = ",
        source_size,
        " bytes, layout = ",
        layout_size,
        " bytes, layout/source = ",
        round(layout_size / max(source_size, 1); digits = 3),
    )
end

println("StringManipulation benchmarks (", QUICK ? "quick smoke" : "full", " mode)")
println(
    "BenchmarkTools settings: samples = ",
    BENCHMARK_SAMPLES,
    ", seconds = ",
    BENCHMARK_SECONDS,
    ", evals = 1",
)

# Representative viewport workloads. Each pair uses the same source, view, and output
# buffer.
ascii_lines = fill(repeat("0123456789", 4_000), 12)
unicode_lines = fill(repeat("α你😃e\u0301", 5_000), 12)
ansi_lines = fill(repeat("\e[31mred\e[0m plain ", 4_000), 12)
representative = [
    ("ASCII", ascii_lines, (1, 12, 20_000, 100)),
    ("Unicode wide/combining", unicode_lines, (1, 12, 15_000, 100)),
    ("ANSI", ansi_lines, (1, 12, 15_000, 100)),
]

buffer = IOBuffer()
break_even_inputs = []

println("\n== Representative construction and paired rendering ==")
for (name, lines, view) in representative
    layout = TextViewLayout(lines)
    construction = report("construct / $name", construction_trial(lines))
    raw = report("render raw / $name", render_trial(buffer, lines, view))
    prepared = report("render prepared warmed / $name", render_trial(buffer, layout, view))
    report_retained("retained / $name", lines, layout)
    push!(break_even_inputs, (name, construction, raw, prepared))
end

println("\n== Construction break-even ==")
for (name, construction, raw, prepared) in break_even_inputs
    break_even(name, construction, raw, prepared)
end

# Search remains dynamic: preparation owns text/layout metadata, not search results.
search_lines = fill("prefix needle suffix "^2_000, 24)
search_layout = TextViewLayout(search_lines)
println("\n== Paired search ==")
report("search raw lines", search_trial(search_lines, r"needle"))
report("search prepared layout", search_trial(search_layout, r"needle"))

# Compare repeated transitions with unique OSC-8 transitions. These report construction,
# warmed rendering, and retained size without inspecting the opaque layout representation.
"""
    repeated_ansi(event_count::Int) -> Vector{String}

Create one line containing `event_count` repeated SGR transitions.

# Arguments

- `event_count::Int`: Number of transitions to generate.

# Returns

- `Vector{String}`: Single-line repeated-transition source.
"""
function repeated_ansi(event_count::Int)
    return [repeat("\e[31mx", event_count)]
end

"""
    high_cardinality_ansi(event_count::Int) -> Vector{String}

Create one line containing `event_count` distinct OSC-8 transitions.

# Arguments

- `event_count::Int`: Number of distinct transitions to generate.

# Returns

- `Vector{String}`: Single-line high-cardinality source.
"""
function high_cardinality_ansi(event_count::Int)
    return [join("\e]8;;https://example.com/$i\e\\x\e]8;;\e\\" for i in 1:event_count)]
end

println("\n== ANSI event-cardinality scaling ==")
ansi_event_counts = QUICK ? (1_000, 10_000) : (1_000, 100_000)
for count in ansi_event_counts
    for (kind, make_source) in
        (("repeated", repeated_ansi), ("high-cardinality", high_cardinality_ansi))
        lines = make_source(count)
        layout = TextViewLayout(lines)
        report("construct ANSI $kind / $count", construction_trial(lines))
        report(
            "render ANSI $kind / $count",
            render_trial(buffer, layout, (1, 1, max(count - 9, 1), 10)),
        )
        report_retained("retained ANSI $kind / $count", lines, layout)
    end
end

println("\n== Many short lines ==")
many_short_lines = ["line $i" for i in 1:100_000]
many_short_layout = TextViewLayout(many_short_lines)
report("construct / 100k short lines", construction_trial(many_short_lines))
report(
    "render prepared / 100k short lines",
    render_trial(buffer, many_short_layout, (99_950, 24, 1, 20)),
)
short_source_size = Base.summarysize(many_short_lines)
short_layout_size = Base.summarysize(many_short_layout)
println(
    "retained / 100k short lines: source = ",
    short_source_size,
    " bytes, layout = ",
    short_layout_size,
    " bytes, layout bytes/line = ",
    round(short_layout_size / length(many_short_lines); digits = 2),
)

# The only match is sparse and near the end. Global active_match must resolve its ordinal;
# active_match_location supplies the prepared line and within-line match directly.
println("\n== Sparse active-match scaling ==")
for line_count in (1_000, 10_000, 100_000)
    sparse_lines = fill("ordinary line", line_count)
    sparse_lines[end - 1] = "ordinary sparse-needle line"
    sparse_layout = TextViewLayout(sparse_lines)
    sparse_matches = string_search_per_line(sparse_layout, r"sparse-needle")
    view = (line_count - 10, 10, 1, 40)
    report(
        "active_match global / $line_count lines",
        render_trial(
            buffer, sparse_layout, view; search_matches = sparse_matches, active_match = 1
        ),
    )
    report(
        "active_match_location / $line_count lines",
        render_trial(
            buffer,
            sparse_layout,
            view;
            search_matches = sparse_matches,
            active_match_location = (line_count - 1, 1),
        ),
    )
end
