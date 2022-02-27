# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
# ==============================================================================
#
#   Functions related to ANSI escape sequences.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Parse the ANSI code in `code` and return the updated decoration given the
# initial `decoration`.
function _parse_ansi_code(decoration::Decoration, code::String)
    tokens = split(code, ';')

    # Unpack fields.
    foreground = decoration.foreground
    background = decoration.background
    bold       = decoration.bold
    underline  = decoration.underline
    reset      = decoration.reset
    reversed   = decoration.reversed

    # `reset` must not be copied to other decorations. Hence, we need to reset
    # it here.
    reset = false

    i = 1
    while i ≤ length(tokens)
        code_i = tryparse(Int, tokens[i], base = 10)

        if code_i == 0
            # If we have a reset, neglect all the other configurations.
            return Decoration(reset = true)

        elseif code_i == 1
            bold = true

        elseif code_i == 4
            underline  = true

        elseif code_i == 7
            reversed = true

        elseif code_i == 22
            bold = false

        elseif code_i == 24
            underline = false

        elseif code_i == 27
            reversed = false

        elseif 30 <= code_i <= 37
            foreground = string(code_i)

        # 256-color support for foreground.
        elseif code_i == 38
            # In this case, we can have an extended color code. To check this,
            # we must have at least two more codes.
            if i+2 ≤ length(tokens)
                code_i_1 = tryparse(Int, tokens[i+1], base = 10)
                code_i_2 = tryparse(Int, tokens[i+2], base = 10)

                if code_i_1 == 5
                    foreground = "38;5;" * string(code_i_2)
                end

                i += 2
            end

        elseif code_i == 39
            foreground = "39"

        elseif 40 <= code_i <= 47
            background = string(code_i)

        # 256-color support for background.
        elseif code_i == 48
            # In this case, we can have an extended color code. To check this,
            # we must have at least two more codes.
            if i+2 ≤ length(tokens)
                code_i_1 = tryparse(Int, tokens[i+1], base = 10)
                code_i_2 = tryparse(Int, tokens[i+2], base = 10)

                if code_i_1 == 5
                    background = "48;5;" * string(code_i_2)
                end

                i += 2
            end

        elseif code_i == 49
            background = "49"

        # Bright foreground colors defined by Aixterm.
        elseif 90 <= code_i <= 97
            foreground = string(code_i)

        # Bright background colors defined by Aixterm.
        elseif 100 <= code_i <= 107
            background = string(code_i)

        end

        i += 1
    end

    return Decoration(
        foreground,
        background,
        bold,
        underline,
        reset,
        reversed
    )
end
