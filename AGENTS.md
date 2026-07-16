# Repository Guide

## Package Structure

- Treat this repository as one Julia package compatible with Julia `^1.10`.
- Use `src/StringManipulation.jl` as the single module entrypoint. Preserve its include order: alignment, ansi, crop, decorations, highlighting, search, state, split, view, width, precompilation.
- Treat feature files in `src/` as module includes, not independent subpackages.
- Keep tests in the files unconditionally included by `test/runtests.jl`: alignment, ansi, crop, decorations, highlighting, search, split, view, and width. Do not expect dedicated test files for state or precompilation.
- Review `src/precompilation.jl` and its explicit `PrecompileTools.@compile_workload` when public API changes should be precompiled.
- Remember that PrecompileTools is the only runtime dependency; the test target supplies Test and Markdown.

## Commands

- Instantiate dependencies with `julia --project=. -e 'using Pkg; Pkg.instantiate()'`.
- Run the full suite with `julia --project=. -e 'using Pkg; Pkg.test()'`.
- Run one test file with `julia --project=. -e 'using StringManipulation, Test, Markdown; include("test/alignment.jl")'`; replace `alignment.jl` with another included test file. There is no test-name selector.
- Allow a generous timeout on the first instantiate or test run because precompilation can take time.
- Approximate CI order, when needed, with `julia --project=. -e 'using Pkg; Pkg.build(); Pkg.test()'`. There is no `deps/build.jl`, so build is effectively a no-op and `Pkg.test()` covers the meaningful local behavior.
- Format with `julia -e 'using JuliaFormatter; format(".")'`. Install JuliaFormatter in the active non-project environment and do not pass `--project=.` because it is not a package dependency.
- Check formatting changes by running the formatter and then `git diff --exit-code`; do not treat the formatter invocation as check-only.
- Expect standard CI to test Julia 1.10 and stable 1.x, with nightly handled separately. Across the workflows, supported runners are Ubuntu x64, macOS arm64, and Windows x64; matrix exclusions remove Ubuntu arm64, macOS x64, and Windows arm64.
- Expect every CI job to run buildpkg before runtest; standard CI also publishes coverage through Codecov.

## Code Style

- Follow `.JuliaFormatter.toml`, which configures Blue style plus repository-specific settings.
- Run formatting locally when appropriate; CI does not check formatting.
- Add test groups using the `@testset "Name" verbose = true begin ... end` pattern from `test/runtests.jl`.

## Behavioral Constraints

- Preserve behavior for ANSI escapes and decorations, Unicode and emoji, printable width, cropping, splitting, alignment, highlighting, and views.
- Preserve or add focused coverage when changing logic in those areas.
- Load Test, StringManipulation, and Markdown when reproducing the `test/runtests.jl` environment.

## Not Configured

- Do not invent workflows for a linter, pre-commit hooks, generated documentation, package extensions, or weak dependencies; none are configured.
- Do not expect `CLAUDE.md`, `deps/build.jl`, a docs project/build, or `test/Project.toml`.
- Do not assume `Manifest.toml` exactly matches package metadata; its local package version is stale (`0.4.4` versus `0.4.5` in `Project.toml`).
