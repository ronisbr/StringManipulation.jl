## Description #############################################################################
#
# Tests related to the conversion of the faces of StyledStrings.jl.
#
############################################################################################

const _SS   = StringManipulation.StyledStrings
const _Face = StringManipulation.Face

@testset "Convert Face to Decoration" begin
    sgr(face; kwargs...) = String(Decoration(face; kwargs...))

    # == Reset =============================================================================

    @test sgr(_Face()) == "\e[0m"
    @test sgr(_Face(; inverse = true)) == "\e[0m\e[7m"
    @test sgr(_Face(; weight = :bold, foreground = :bright_white, background = :blue)) ==
        "\e[0m\e[97m\e[44m\e[1m"
    @test sgr(_Face(; weight = :light, slant = :italic, underline = true)) ==
        "\e[0m\e[2m\e[3m\e[4m"
    @test sgr(_Face(; strikethrough = true, underline = (:red, :curly))) ==
        "\e[0m\e[4m\e[9m"
    @test sgr(_Face(; underline = :red)) == "\e[0m\e[4m"

    # The attributes turned off and the default colors are already selected by the reset.
    # Notice that the name of the default color depends on the version of StyledStrings.jl,
    # which the package selects at load time. Hence, it must match the default face.
    default_foreground = StringManipulation._DEFAULT_FOREGROUND
    default_background = StringManipulation._DEFAULT_BACKGROUND
    @test default_foreground == _SS.getface().foreground
    @test default_background == _SS.getface().background
    @test sgr(_Face(; weight = :normal, slant = :normal)) == "\e[0m"
    @test sgr(_Face(; underline = false, strikethrough = false, inverse = false)) == "\e[0m"
    @test sgr(_Face(; foreground = default_foreground, background = default_background)) ==
        "\e[0m"

    # A merged face carries the default of every attribute, which must not be written.
    @test sgr(_SS.getface(_Face(; weight = :bold))) == "\e[0m\e[1m"

    # == Without Reset =====================================================================

    @test sgr(_Face(); reset = false) == ""
    @test sgr(_Face(; weight = :bold); reset = false) == "\e[22m\e[1m"
    @test sgr(_Face(; weight = :normal, slant = :normal); reset = false) == "\e[22m\e[23m"
    @test sgr(
        _Face(; underline = false, strikethrough = false, inverse = false); reset = false
    ) == "\e[24m\e[29m\e[27m"
    @test sgr(
        _Face(; foreground = default_foreground, background = default_background);
        reset = false,
    ) == "\e[39m\e[49m"

    # == Colors ============================================================================

    @test Decoration(_Face(; background = :blue)).background == "44"
    @test Decoration(_Face(; background = :bright_black)).background == "100"
    @test Decoration(_Face(; foreground = :red)).foreground == "31"
    @test Decoration(_Face(; foreground = :red)).background == ""

    # A 24-bit color is written as such or approximated, depending on the terminal.
    decoration = Decoration(_Face(; foreground = "#ff8800", background = 0x005f87))
    @test startswith(decoration.foreground, "38;")
    @test startswith(decoration.background, "48;")
    @test !endswith(decoration.background, "m")

    # A color that names another face selects the foreground of that face.
    error_foreground = _SS.getface(:error).foreground
    @test Decoration(_Face(; foreground = :error)).foreground ==
        Decoration(_Face(; foreground = error_foreground)).foreground
end
