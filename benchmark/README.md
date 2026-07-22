# Benchmarks

From the package root, instantiate the isolated benchmark environment with the local checkout and
run the full suite:

```sh
julia --project=benchmark -e 'using Pkg; Pkg.develop(path=pwd()); Pkg.instantiate()'
julia --project=benchmark benchmark/benchmarks.jl
```

For a bounded smoke execution using the same workloads but fewer samples and smaller ANSI-scaling
inputs, run:

```sh
julia --project=benchmark benchmark/benchmarks.jl --quick
```

The script reports BenchmarkTools median elapsed time and warmed allocations for each operation.
Rendering trials compile their exact call once before measurement, reuse one `IOBuffer`, and reset
it outside each timed evaluation. Thus, “prepared warmed” describes steady warmed execution, not a
first render.

Output includes:

- paired raw/prepared rendering for ASCII, wide/combining Unicode, and ANSI text;
- paired raw/layout searches;
- layout construction time, warmed construction allocations, and retained
  `Base.summarysize` for sources and layouts;
- a construction break-even estimate, computed as construction time divided by the median time
  saved per prepared render. If prepared rendering is not faster in that run, the script labels the
  estimate unavailable rather than dividing by a non-positive value;
- repeated versus high-cardinality ANSI construction, rendering, and retention scaling;
- construction, rendering, retained bytes, and bytes per line for 100,000 short lines; and
- global `active_match` versus `active_match_location` with a sparse match near the end of 1,000,
  10,000, and 100,000-line inputs.

Benchmark times vary with Julia version, hardware, operating system, system load, and terminal/IO
conditions. Compare results from the same environment; the script makes no cross-platform
performance assertion. Quick mode is a smoke check, not a stable performance measurement.
