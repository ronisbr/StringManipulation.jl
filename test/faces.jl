## Description #############################################################################
#
# Tests related to the conversion of the faces of StyledStrings.jl.
#
############################################################################################

const _SS = StringManipulation.StyledStrings
const _Face = StringManipulation.Face
const _SimpleColor = StringManipulation.SimpleColor

@testset "Convert Face to Decoration" begin
    sgr(face; kwargs...) = String(Decoration(face; kwargs...))

    # == Reset =============================================================================

    @test sgr(_Face()) == "\e[0m"
    @test sgr(_Face(; inverse = true)) == "\e[0;7m"
    @test sgr(_Face(; weight = :bold, foreground = :bright_white, background = :blue)) ==
        "\e[0;97;44;1m"
    @test sgr(_Face(; weight = :light, slant = :italic, underline = true)) == "\e[0;2;3;4m"
    @test sgr(_Face(; strikethrough = true, underline = (:red, :curly))) == "\e[0;4;9m"
    @test sgr(_Face(; underline = :red)) == "\e[0;4m"

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
    @test sgr(_SS.getface(_Face(; weight = :bold))) == "\e[0;1m"

    # == Without Reset =====================================================================

    @test sgr(_Face(); reset = false) == ""
    @test sgr(_Face(; weight = :bold); reset = false) == "\e[22;1m"
    @test sgr(_Face(; weight = :normal, slant = :normal); reset = false) == "\e[22;23m"
    @test sgr(
        _Face(; underline = false, strikethrough = false, inverse = false); reset = false
    ) == "\e[24;29;27m"
    @test sgr(
        _Face(; foreground = default_foreground, background = default_background);
        reset = false,
    ) == "\e[39;49m"

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

@testset "Face Color to RGB" begin
    @test face_color_rgb(nothing) === nothing

    # == Terminal Colors ===================================================================

    @test face_color_rgb(_SimpleColor(:red)) == (r = 0xa5, g = 0x1c, b = 0x2c)
    @test face_color_rgb(_SimpleColor(:bright_white)) == (r = 0xf6, g = 0xf5, b = 0xf4)
    @test face_color_rgb(_SimpleColor(:grey)) == face_color_rgb(_SimpleColor(:bright_black))

    # == 24-bit Colors =====================================================================

    @test face_color_rgb(_SimpleColor(0x005f87)) == (r = 0x00, g = 0x5f, b = 0x87)
    @test face_color_rgb(_SimpleColor(0x12, 0x34, 0x56)) == (r = 0x12, g = 0x34, b = 0x56)

    # == Colors Without a Fixed Value ======================================================

    @test face_color_rgb(_SimpleColor(:default)) === nothing
    @test face_color_rgb(_SimpleColor(:foreground)) === nothing
    @test face_color_rgb(_SimpleColor(:background)) === nothing
    @test face_color_rgb(_SimpleColor(:this_face_does_not_exist)) === nothing

    # == Colors That Name Another Face =====================================================

    @test face_color_rgb(_SimpleColor(:error)) ==
        face_color_rgb(_SS.getface(:error).foreground)

    _SS.withfaces(
        :sm_test_a => _Face(; foreground = :sm_test_b),
        :sm_test_b => _Face(; foreground = :blue),
        :sm_cycle_a => _Face(; foreground = :sm_cycle_b),
        :sm_cycle_b => _Face(; foreground = :sm_cycle_a),
        :sm_self => _Face(; foreground = :sm_self),
    ) do
        @test face_color_rgb(_SimpleColor(:sm_test_a)) ==
            face_color_rgb(_SimpleColor(:blue))
        @test face_color_rgb(_SimpleColor(:sm_cycle_a)) === nothing
        @test face_color_rgb(_SimpleColor(:sm_self)) === nothing
    end
end
