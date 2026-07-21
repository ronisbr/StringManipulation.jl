# Benchmarks

Instantiate this isolated environment and run the suite from the package root:

```julia
julia --project=benchmark -e 'using Pkg; Pkg.develop(path=pwd()); Pkg.instantiate()'
julia --project=benchmark benchmark/benchmarks.jl
```

Layout construction is reported separately from first and repeated rendering. The output buffer is
reused and reset outside each timed evaluation.
