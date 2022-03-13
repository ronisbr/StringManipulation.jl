# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
# ==============================================================================
#
#   Tests related with text views.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

@testset "Text view" begin
    md_str = md"""
        # Si distentae

        ## Carpitur devorat

        Lorem markdownum ipsi Emathion Neoptolemum et moenia **viveret spumantis**
        namque. Iam excepi ignis turbamve, *cruorem quo nubes* aevi; sensit esse
        animantis, Chironis infelix *stabantque*. Ruit et iuvenemque longo; ut at iugis,
        venit adventus molle adpropera?

        Putat quibus Phaethon manet sanguine elige, orbem palearia iuvenum age prior
        mollibat *Pallas* est fera curru naribus. Constituis priore orbae generosque
        insidiaeque umbra patulas Laurentes denique senior?

        ```julia
        # Compute recursively `sin(m*ϕ)` and `cos(m*ϕ)`.
        sin_mϕ = 2cos_ϕ * sin_m_1ϕ - sin_m_2ϕ
        cos_mϕ = 2cos_ϕ * cos_m_1ϕ - cos_m_2ϕ
        ```

        ## Et carus quo inceptaque urbem quibus loqui

        Perspicuus *bello*, rates siqua profatur tumulumque Taygetenque cauda multas ut
        enixa. Cum aenea est exhibuere procubuere terraeque virgo decimum victorem
        silvis dumque cunctatus excidit [piget](http://ea.org/pecorumquemunera) nam, tu.
        Suo quod ab funesta atque Thessalus idem trabe et **quamvis** lacrimis rerum sed
        erat per.

        > Nec male regia, et tela, videns vultibus ut faciem plangore versantem. Obscena
        > admoveam nominis pater *est confundas decimo* humus indigenae aquae absit. Nos
        > nox acta videt animae, Phineus caput nec.
        """

    # Render the markdown with decorations.
    buf = IOBuffer()
    io  = IOContext(buf, :color => true, :displaysize => (100, 80))
    show(io, MIME("text/plain"), md_str)
    str = String(take!(buf))

    # Without frozen lines or columns
    # ==========================================================================

    expected = """
        e\e[30m\e[43mqu\e[0me umbra patulas Laurentes de\e[0m

        \e[36mte recursively `sin(m*ϕ)` and `\e[39m
        \e[36m= 2cos_ϕ * sin_m_1ϕ - sin_m_2ϕ\e[39m
        \e[36m= 2cos_ϕ * cos_m_1ϕ - cos_m_2ϕ\e[39m

        \e[1ms \e[1m\e[7mqu\e[0m\e[1mo incepta\e[1m\e[7mqu\e[0m\e[1me urbem \e[1m\e[7mqu\e[0m\e[1mibus l\e[22m
        \e[1m===============================\e[22m"""

    vstr, num_cropped_lines_at_end, max_cropped_chars = textview(
        str,
        (14, 8, 10, 31);
        active_match = 7,
        search_regex = r"qu"
    )

    @test vstr == expected
    @test num_cropped_lines_at_end == 11
    @test max_cropped_chars == 13

    # With frozen lines or columns
    # ==========================================================================

    expected =
    """
      \e[1m  \e[1m\e[7m\e[0m\e[1m\e[7mentae\e[0m\e[22m
      \e[1m  \e[0m\e[1m≡≡≡≡≡≡≡\e[22m
      \e[0m
      \e[1m  \e[0m\e[1mr devorat\e[22m\e[0m
        \e[0me\e[30m\e[43mqu\e[0me umbra patulas Laurentes de\e[0m
      \e[0m
      \e[36m  \e[0m\e[36mte recursively `sin(m*ϕ)` and `\e[39m
      \e[36m  \e[0m\e[36m= 2cos_ϕ * sin_m_1ϕ - sin_m_2ϕ\e[39m
      \e[36m  \e[0m\e[36m= 2cos_ϕ * cos_m_1ϕ - cos_m_2ϕ\e[39m
      \e[0m
      \e[1m  \e[0m\e[1ms \e[1m\e[7mqu\e[0m\e[1mo incepta\e[1m\e[7mqu\e[0m\e[1me urbem \e[1m\e[7mqu\e[0m\e[1mibus l\e[22m
      \e[1m  \e[0m\e[1m===============================\e[22m"""

    vstr, num_cropped_lines, max_cropped_chars = textview(
        str,
        (14, 8, 10, 31);
        active_match = 8,
        frozen_lines_at_beginning = 4,
        frozen_columns_at_beginning = 2,
        search_regex = r"qu|Si distentae"
    )

    @test vstr == expected
    @test num_cropped_lines == 11
    @test max_cropped_chars == 13

    # View the entire text without any modification
    # ==========================================================================

    vstr, num_cropped_lines_at_end, max_cropped_chars = textview(str, (-1, -1, -1, -1))
    @test vstr == str
    @test num_cropped_lines_at_end == 0
    @test max_cropped_chars == 0

    # Maximum number of lines and columns
    # ==========================================================================

    expected = """
        eque umbra patulas Laure

        \e[36mte recursively `sin(m*ϕ)\e[39m
        \e[36m= 2cos_ϕ * sin_m_1ϕ - si\e[39m
        \e[36m= 2cos_ϕ * cos_m_1ϕ - co\e[39m
        """

    vstr, num_cropped_lines_at_end, max_cropped_chars = textview(
        str,
        (14, 8, 10, 31);
        maximum_number_of_lines = 6,
        maximum_number_of_columns = 24
    )

    @test vstr == expected
    @test num_cropped_lines_at_end == 13
    @test max_cropped_chars == 20

    expected = """
        \e[1m  Si distentae\e[22m\e[0m\e[22m
        \e[1m  ≡≡≡≡≡≡≡≡≡≡≡≡≡≡\e[22m\e[0m\e[22m
        \e[0m
        \e[1m  Carpitur devorat\e[22m\e[0m\e[22m
        \e[1m  ==================\e[22m\e[0m\e[22m
        \e[0m
          Lorem markdownum i\e[0m\e[22m
          namque. Iam excepi\e[0m\e[24m\e[0m"""

    vstr, num_cropped_lines_at_end, max_cropped_chars = textview(
        str,
        (14, 8, 10, 31);
        frozen_columns_at_beginning = 30,
        frozen_lines_at_beginning = 10,
        maximum_number_of_columns = 20,
        maximum_number_of_lines = 8
    )

    @test vstr == expected
    @test num_cropped_lines_at_end == 0
    @test max_cropped_chars == 0

    expected = """
      \e[0markdownum ipsi Ema\e[22m
      \e[0m Iam excepi ignis \e[24m
      \e[0mis, Chironis infel\e[24m
      \e[0mvenit adventus mol
    \e[0m
      \e[0muibus Phaethon man
      \e[0mt \e[4mPallas\e[24m est fera 
      \e[0meque umbra patulas"""

    vstr, num_cropped_lines_at_end, max_cropped_chars = textview(
        str,
        (7, 8, 10, -1);
        frozen_columns_at_beginning = 2,
        maximum_number_of_columns = 20,
    )

    @test vstr == expected
    @test num_cropped_lines_at_end == 18
    @test max_cropped_chars == 51

    # Test related to multiple dispatch
    # ==========================================================================

    lines = split(str, '\n')
    search_matches = string_search_per_line(lines, r"qu")

    expected = """
        e\e[30m\e[43mqu\e[0me umbra patulas Laurentes de\e[0m

        \e[36mte recursively `sin(m*ϕ)` and `\e[39m
        \e[36m= 2cos_ϕ * sin_m_1ϕ - sin_m_2ϕ\e[39m
        \e[36m= 2cos_ϕ * cos_m_1ϕ - cos_m_2ϕ\e[39m

        \e[1ms \e[1m\e[7mqu\e[0m\e[1mo incepta\e[1m\e[7mqu\e[0m\e[1me urbem \e[1m\e[7mqu\e[0m\e[1mibus l\e[22m
        \e[1m===============================\e[22m"""

    vstr, num_cropped_lines_at_end, max_cropped_chars = textview(
        lines,
        (14, 8, 10, 31);
        active_match = 7,
        search_matches = search_matches
    )

    @test vstr == expected
    @test num_cropped_lines_at_end == 11
    @test max_cropped_chars == 13

    # Ruler
    # ==========================================================================

    expected = """
        \e[90m  1 │\e[0m\e[1m  \e[1m\e[7m\e[0m\e[1m\e[7mentae\e[0m\e[22m
        \e[90m  2 │\e[0m\e[1m  \e[0m\e[1m≡≡≡≡≡≡≡\e[22m
        \e[90m  3 │\e[0m\e[0m
        \e[90m  4 │\e[0m\e[1m  \e[0m\e[1mr devorat\e[22m\e[0m
        \e[90m 14 │\e[0m  \e[0me\e[30m\e[43mqu\e[0me umbra patulas Laurentes de\e[0m
        \e[90m 15 │\e[0m\e[0m
        \e[90m 16 │\e[0m\e[36m  \e[0m\e[36mte recursively `sin(m*ϕ)` and `\e[39m
        \e[90m 17 │\e[0m\e[36m  \e[0m\e[36m= 2cos_ϕ * sin_m_1ϕ - sin_m_2ϕ\e[39m
        \e[90m 18 │\e[0m\e[36m  \e[0m\e[36m= 2cos_ϕ * cos_m_1ϕ - cos_m_2ϕ\e[39m
        \e[90m 19 │\e[0m\e[0m
        \e[90m 20 │\e[0m\e[1m  \e[0m\e[1ms \e[1m\e[7mqu\e[0m\e[1mo incepta\e[1m\e[7mqu\e[0m\e[1me urbem \e[1m\e[7mqu\e[0m\e[1mibus l\e[22m
        \e[90m 21 │\e[0m\e[1m  \e[0m\e[1m===============================\e[22m"""

    vstr, num_cropped_lines, max_cropped_chars = textview(
        str,
        (14, 8, 10, 31);
        active_match = 8,
        frozen_lines_at_beginning = 4,
        frozen_columns_at_beginning = 2,
        search_regex = r"qu|Si distentae",
        show_ruler = true
    )

    @test vstr == expected
    @test num_cropped_lines == 11
    @test max_cropped_chars == 13

    # Title lines
    # ==========================================================================

    expected = """
        \e[1m  Si distentae\e[22m\e[0m\e[1m\e[22m
        \e[1m  \e[0m\e[1m≡≡≡≡≡≡≡\e[22m\e[0m
          \e[0meque umbra patulas Laurentes de
        \e[0m
        \e[36m  \e[0m\e[36mte recursively `sin(m*ϕ)` and `\e[39m
        \e[36m  \e[0m\e[36m= 2cos_ϕ * sin_m_1ϕ - sin_m_2ϕ\e[39m
        \e[36m  \e[0m\e[36m= 2cos_ϕ * cos_m_1ϕ - cos_m_2ϕ\e[39m
        \e[0m
        \e[1m  \e[0m\e[1ms quo inceptaque urbem quibus l\e[22m
        \e[1m  \e[0m\e[1m===============================\e[22m"""

    vstr, num_cropped_lines_at_end, max_cropped_chars = textview(
        lines,
        (14, 8, 10, 31),
        frozen_columns_at_beginning = 2,
        frozen_lines_at_beginning = 2,
        title_lines = 1
    )

    @test vstr == expected
    @test num_cropped_lines_at_end == 11
    @test max_cropped_chars == 13

    # Consider decorations in hidden lines
    # ==========================================================================

    str = """
         Lorem ipsum dolor sit amet, consectetur adipiscing elit. Pellentesque tempor
         risus vel diam ultrices volutpat. Nullam id tortor ut dolor rutrum cursus
         aliquam sed \e[34;1mlorem. Donec interdum, risus eu scelerisque posuere, purus magna
         auctor purus, in faucibus nisi quam ac erat. Nulla facilisi. Aenean et augue
         augue. Donec ut sem posuere, venenatis est quis, ultrices elit. Vivamus elit
         sapien, ullamcorper quis dui ut, \e[0msuscipit varius nibh. Duis varius arcu id
         ipsum egestas aliquam. Pellentesque eget sem ornare turpis fringilla fringilla
         id ac turpis.
         """

    expected = """
        Lorem ipsum dolor sit amet, consectetur adipisc\e[7ming\e[0m elit. Pellentesque tempor\e[0m
        auctor purus, in faucibus nisi quam ac erat. Nulla facilisi. Aenean et augue
        augue. Donec ut sem posuere, venenatis est quis, ultrices elit. Vivamus elit
        sapien, ullamcorper quis dui ut, \e[0msuscipit varius nibh. Duis varius arcu id
        ipsum egestas aliquam. Pellentesque eget sem ornare turpis fr\e[7ming\e[0milla fr\e[30m\e[43ming\e[0milla
        id ac turpis.
        """

    vstr, max_cropped_char = textview(
        str,
        (4, -1, -1, -1);
        active_match = 3,
        frozen_lines_at_beginning = 1,
        search_regex = r"ing"
    )

    expected = """
        Lorem ipsum dolor sit amet, consectetur adipisc\e[7ming\e[0m elit. Pellentesque tempor\e[0m
        \e[34m\e[1mauctor purus, in faucibus nisi quam ac erat. Nulla facilisi. Aenean et augue
        augue. Donec ut sem posuere, venenatis est quis, ultrices elit. Vivamus elit
        sapien, ullamcorper quis dui ut, \e[0msuscipit varius nibh. Duis varius arcu id
        ipsum egestas aliquam. Pellentesque eget sem ornare turpis fr\e[7ming\e[0milla fr\e[30m\e[43ming\e[0milla
        id ac turpis.
        """

    vstr, max_cropped_char = textview(
        str,
        (4, -1, -1, -1);
        active_match = 3,
        frozen_lines_at_beginning = 1,
        parse_decorations_before_view = true,
        search_regex = r"ing"
    )

    @test vstr == expected
end
