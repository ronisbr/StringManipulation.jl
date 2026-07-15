# Repository Guide

## Package structure

- This is a single Julia package requiring Julia 1.10 or newer.
- `src/StringManipulation.jl` is the module entrypoint and controls source include order. Feature files in `src/` are not independent subpackages.
- Tests mirror the feature files (each `src/<feature>.jl` has a matching `test/<feature>.jl`), with the single exception of `src/state.jl`, which has no dedicated test file. Test files are included unconditionally from `test/runtests.jl`.
- `src/precompilation.jl` contains an explicit `PrecompileTools.@compile_workload`; update it when public API changes should be precompiled.

## Commands

- Instantiate: `julia --project=. -e 'using Pkg; Pkg.instantiate()'`
- Full test suite: `julia --project=. -e 'using Pkg; Pkg.test()'`
- Focused test file: `julia --project=. -e 'using StringManipulation, Test, Markdown; include("test/alignment.jl")'` (replace `alignment.jl` with another file included by `test/runtests.jl`). `Markdown` must be loaded because some test files use it (e.g. `test/view.jl`); omit it and those focused runs error. There is no test-name selector.
- CI builds before testing (via `julia-actions/julia-buildpkg`) and covers Julia 1.10, stable (`'1'`), and nightly across Linux, macOS, and Windows. The package has no `deps/build.jl` — its only dependency is PrecompileTools — so `Pkg.build()` is effectively a no-op and `Pkg.test()` alone reproduces CI locally. Use `julia --project=. -e 'using Pkg; Pkg.build(); Pkg.test()'` only if you want to mirror the CI step order exactly.
- Format code: `julia -e 'using JuliaFormatter; format(".")'` — run from an environment where JuliaFormatter.jl is installed. It is NOT a project dependency, so do NOT pass `--project=.` (that env cannot see it). `format(".")` returns `true` when nothing needed changing; to check formatting without rewriting in place, run it and then `git diff --exit-code`.
- No linter, pre-commit, or generated-docs task is configured; do not invent one from README badges or language conventions.

## Code style

- Code follows Blue Style. The `.JuliaFormatter.toml` at the repo root (`style = "blue"`) is the source of truth — apply it with the formatter command above rather than hand-formatting against remembered rules.
- CI has no format-check step, so style is not enforced automatically; run the formatter locally before committing.

## Behavioral constraints

- ANSI escape handling, Unicode/emoji printable width, and decorated strings are core behavior. Preserve focused coverage for these when changing alignment, crop, split, view, or width logic.
- Tests depend on both `Test` and `Markdown` through the project test target.
- New tests follow the `@testset "Name" verbose = true begin ... end` pattern used throughout `test/runtests.jl`; match it when adding coverage.
