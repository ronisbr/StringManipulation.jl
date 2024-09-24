## Description #############################################################################
#
# Functions related to ANSI escape sequences.
#
############################################################################################

# Parse the ANSI decoration code in `code` and return the updated decoration given the
# initial `decoration`.
function _parse_ansi_decoration_code(decoration::Decoration, code::String)
    tokens = split(code, ';')
    num_tokens = length(tokens)

    # Unpack fields.
    foreground = decoration.foreground
    background = decoration.background
    bold       = decoration.bold
    italic     = decoration.italic
    underline  = decoration.underline
    reset      = decoration.reset
    reversed   = decoration.reversed

    # `reset` must not be copied to other decorations. Hence, we need to reset it here.
    reset = false

    i = 1
    while i ≤ num_tokens
        code_i = tryparse(Int, tokens[i], base = 10)
        if isnothing(code_i)
            i += 1
            continue
        end

        if code_i == 0
            # If we have a reset, neglect all the other configurations except the
            # hyperlinks.
            return Decoration(
                reset = true,
                hyperlink_url = decoration.hyperlink_url,
                hyperlink_url_changed = decoration.hyperlink_url_changed
            )

        elseif code_i == 1
            bold = active

        elseif code_i == 3
            italic = active

        elseif code_i == 4
            underline = active

        elseif code_i == 7
            reversed = active

        elseif code_i == 22
            bold = inactive

        elseif code_i == 23
            italic = inactive

        elseif code_i == 24
            underline = inactive

        elseif code_i == 27
            reversed = inactive

        elseif 30 <= code_i <= 37
            foreground = string(code_i)

        # 256-color / true-color (24-bit) support for foreground.
        elseif code_i == 38
            # Check if we have 256-color or true-color (24-bit) definition.
            if i + 1 ≤ num_tokens
                color_type = tryparse(Int, tokens[i + 1], base = 10)
                isnothing(color_type) && continue

                # 256-color mode.
                if color_type == 5
                    # In this case, we must have another token for the color.
                    if i + 2 ≤ num_tokens
                        color_code = tryparse(Int, tokens[i + 2], base = 10)
                        isnothing(color_code) && continue

                        foreground = "38;5;" * string(color_code)
                        i += 2
                    end

                # True-color (24-bit) mode.
                elseif color_type == 2
                    # In this case, we must have another three tokens for the RGB color.
                    if i + 4 ≤ num_tokens
                        color_r = tryparse(Int, tokens[i + 2], base = 10)
                        isnothing(color_r) && continue

                        color_g = tryparse(Int, tokens[i + 3], base = 10)
                        isnothing(color_g) && continue

                        color_b = tryparse(Int, tokens[i + 4], base = 10)
                        isnothing(color_b) && continue

                        foreground =
                            "38;2;" *
                            string(color_r) * ";" *
                            string(color_g) * ";" *
                            string(color_b)

                        i += 4
                    end
                end
            end

        elseif code_i == 39
            foreground = "39"

        elseif 40 <= code_i <= 47
            background = string(code_i)

        # 256-color / truecolor support for background.
        elseif code_i == 48
            # Check if we have 256-color or truecolor definition.
            if i + 1 ≤ num_tokens
                color_type = tryparse(Int, tokens[i + 1], base = 10)
                isnothing(color_type) && continue

                # 256-color mode.
                if color_type == 5
                    # In this case, we must have another token for the color.
                    if i + 2 ≤ num_tokens
                        color_code = tryparse(Int, tokens[i + 2], base = 10)
                        isnothing(color_code) && continue

                        background = "48;5;" * string(color_code)
                        i += 2
                    end

                # Truecolor mode.
                elseif color_type == 2
                    # In this case, we must have another three tokens for the RGB color.
                    if i + 4 ≤ num_tokens
                        color_r = tryparse(Int, tokens[i + 2], base = 10)
                        isnothing(color_r) && continue

                        color_g = tryparse(Int, tokens[i + 3], base = 10)
                        isnothing(color_g) && continue

                        color_b = tryparse(Int, tokens[i + 4], base = 10)
                        isnothing(color_b) && continue

                        background =
                            "48;2;" *
                            string(color_r) * ";" *
                            string(color_g) * ";" *
                            string(color_b)

                        i += 4
                    end
                end
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
        italic,
        reversed,
        underline,
        reset,
        decoration.hyperlink_url,
        decoration.hyperlink_url_changed
    )
end
