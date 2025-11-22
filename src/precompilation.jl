## Description #############################################################################
#
# Precompilation.
#
############################################################################################

import PrecompileTools

PrecompileTools.@compile_workload begin
    # == Alignment =========================================================================

    align_string("Test", 40, :r)
    align_string_per_line("Test\nTest", 40, :r)

    # == ANSI Parsing ======================================================================

    parse_ansi_string("Test \e[38;5;231;48;5;243mTest 😅 \e[38;5;201;48;5;243mTest\e[0m End")

    # == Crop ==============================================================================

    left_crop("Test", 2)
    fit_string_in_field("Test Test Test Test Test", 10; crop_side = :left)
    fit_string_in_field("Test Test Test Test Test", 10; crop_side = :right)
    right_crop("Test", 2)

    # == Decorations =======================================================================

    drop_inactive_properties(Decoration())
    get_decorations("This is a \\e[1mbold string\\e[45mwith a different background\\e[0m.")
    get_and_remove_decorations("This is a \\e[1mbold string\\e[45mwith a different background\\e[0m.")
    parse_decoration("\\e[1;45m")
    remove_decorations("This is a \\e[1mbold string\\e[45mwith a different background\\e[0m.")
    replace_default_background(
        "\e[35mThis is a \e[45;1mtest string to \e[0mverify if \e[45mthe background \e[49;1mwas replaced correctly.",
        "43"
    )
    update_decoration(Decoration(), "\\e[1;45m")
    convert(String, Decoration(bold = StringManipulation.active))

    # == Highlight =========================================================================

    highlight_search("Test high\e[1mlight\e[0m in a string with no underlines.", r"highlight")
    highlight_search([
        "Test \e[7mhighlight\e[0m\e[0m in a string with no underlines.",
        "Test \e[7mhighlight\e[0m\e[4m in a string with underlines\e[0m.",
        "Test another \e[7mhighlight\e[0m\e[33m with colors.",
        "This is the last line."
    ], r"highlight")

    # == String Search =====================================================================

    string_search(
        """
        Test 1 😅 \e[38;5;231;48;5;243mTest 2 😅 \e[38;5;201;48;5;243mTest\e[0m
        Test 1 😅 \e[38;5;231;48;5;243mTest 2 😅 \e[38;5;201;48;5;243mTest\e[0m
        """,
        r"Test 2 😅"
    )

    string_search_per_line(
        """
        Test 1 😅 \e[38;5;231;48;5;243mTest 2 😅 \e[38;5;201;48;5;243mTest\e[0m
        Test 1 😅 \e[38;5;231;48;5;243mTest 2 😅 \e[38;5;201;48;5;243mTest\e[0m
        """,
        r"Test 2 😅"
    )

    # == Split =============================================================================

    split_string("Test 😅 \e[38;5;231;48;5;243mTest 😅 \e[38;5;201;48;5;243mTest\e[0m", 8)

    # == Text View =========================================================================

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

    textview(str, (0, 6, 10, 19))

    # == Text Width ========================================================================

    printable_textwidth("\e[1m😃\e[0m\e[4m😅\e[0m\e[7m🥳\e[0m")

    printable_textwidth_per_line("""
        \e[38;5;231;48;5;243mTes\e[3mt Test\e[1m Test\e[0m
        \e[38;5;231;48;5;243m😃\e[3m😄\e[1m😊\e[0m
        \e[1m😃\e[0m\e[4m😅\e[0m\e[7m🥳\e[0m
        \u001b[30;1m A \u001b[31;1m B \u001b[32;1m C \u001b[33;1m D \u001b[0m
        \u001b[44;1m A \u001b[45;1m B \u001b[46;1m C \u001b[47;1m D \u001b[0m
        \u001b[1m BOLD \u001b[0m\u001b[4m Underline \u001b[0m\u001b[7m Reversed \u001b[0m
        \u001b[1m\u001b[4m\u001b[7m BOLD Underline Reversed \u001b[0m"""
    )
end
