## Description #############################################################################
#
# Functions related to ANSI escape sequences.
#
############################################################################################

export parse_ansi_string

"""
    parse_ansi_string(str::AbstractString) -> Vector{Pair{String, Decoration}}

Parse the ANSI escape sequences in `str` and return a vector of pairs where each pair
contains a substring and its corresponding `Decoration`.
"""
function parse_ansi_string(str::AbstractString)
    # Buffers to store the tokens and the ANSI escape sequences. Notice that we must use
    # `sizeof`, which is the number of bytes, instead of `length`, which is the number of
    # characters. The latter requires a full scan of the string and underestimates the
    # required size if the string is not ASCII. The buffer with the escape sequences only
    # holds a run of them, which is much shorter than the string itself.
    buf_text = IOBuffer(; sizehint = max(sizeof(str), 1))
    buf_ansi = IOBuffer(; sizehint = 64)

    # Output vector with the string parts and their decoration.
    voutput = Pair{String, Decoration}[]

    # Store the current state of the string parsing.
    state = :text

    # Indicate if we are currently capturing an ANSI escape sequence.
    capturing_ansi = false

    # Store the current decoration of the string.
    decoration = Decoration()

    @inbounds for i in eachindex(str)
        c = str[i]

        state = _next_string_state(c, state)

        if state == :text
            capturing_ansi = false
            write(buf_text, c)
            continue
        end

        # We are starting a run of escape sequences. Hence, we must close the current
        # token, which is decorated by the previous run. Notice that we test the buffers
        # instead of the index because nothing must be pushed if the string begins with an
        # escape sequence.
        if !capturing_ansi && ((position(buf_text) > 0) || (position(buf_ansi) > 0))
            token = String(take!(buf_text))

            if position(buf_ansi) > 0
                decoration = update_decoration(decoration, String(take!(buf_ansi)))
            end

            push!(voutput, token => decoration)
        end

        write(buf_ansi, c)
        capturing_ansi = true
    end

    token = String(take!(buf_text))

    if position(buf_ansi) > 0
        decoration = update_decoration(decoration, String(take!(buf_ansi)))
    end

    push!(voutput, token => decoration)

    return voutput
end

############################################################################################
#                                    Private Functions                                     #
############################################################################################

"""
    _next_sgr_parameter(
        code::AbstractString,
        i::Int,
        require_value::Bool = false
    ) -> Int, Int, Bool

Read the SGR parameter of `code` that begins at the byte index `i`.

# Arguments

- `code::AbstractString`: Parameters of an SGR sequence.
- `i::Int`: Byte index where the parameter begins.
- `require_value::Bool`: If `true`, an omitted parameter is reported as not found instead of
    taking its default value. This is required by the arguments of the extended color
    modes, which are not defined by ECMA-48 and have no default.
    (**Default** = `false`)

# Returns

- `Int`: Value of the parameter, or 0 if it was omitted.
- `Int`: Byte index where the next parameter begins. It is past the end of `code` if this
    was the last parameter.
- `Bool`: `true` if a parameter was read. It is `false` if `i` is past the end of `code` or
    if the parameter is not a valid number, in which case the caller must skip it.
"""
function _next_sgr_parameter(code::AbstractString, i::Int, require_value::Bool = false)
    last_index = ncodeunits(code)

    (i > last_index + 1) && return 0, i, false

    value      = 0
    num_digits = 0
    valid      = true

    j = i
    while j ≤ last_index
        b = codeunit(code, j)
        (b == UInt8(';')) && break

        if UInt8('0') ≤ b ≤ UInt8('9')
            value = 10 * value + (b - UInt8('0'))
            num_digits += 1
        else
            valid = false
        end

        j += 1
    end

    # If the delimiter was not found, this was the last parameter and the next one begins
    # past the end of the string, ending the loop in the caller.
    next_index = j > last_index ? last_index + 2 : j + 1

    # ECMA-48 states that an omitted parameter takes its default value, which is 0 for SGR.
    # Hence, `\e[m` is equivalent to `\e[0m`, and so is any empty parameter. A parameter
    # with more digits than we can hold is reported as invalid.
    valid &= num_digits ≤ 9
    require_value && (valid &= num_digits > 0)

    return value, next_index, valid
end

"""
    _parse_ansi_decoration_code(decoration::Decoration, code::AbstractString) -> Decoration

Parse the ANSI decoration `code`, which contains only the parameters of an SGR sequence, and
return the updated decoration given the initial `decoration`.
"""
function _parse_ansi_decoration_code(decoration::Decoration, code::AbstractString)
    # Unpack fields.
    foreground = decoration.foreground
    background = decoration.background
    bold       = decoration.bold
    italic     = decoration.italic
    underline  = decoration.underline
    reversed   = decoration.reversed

    # `reset` must not be copied to other decorations. Hence, we need to reset it here.
    reset = false

    # We walk the parameters instead of splitting the code because the latter allocates a
    # vector for every escape sequence, which is the hottest path of this package.
    pos        = firstindex(code)
    last_index = ncodeunits(code)

    while pos ≤ last_index + 1
        code_i, pos, found = _next_sgr_parameter(code, pos)
        found || continue

        if code_i == 0
            # If we have a reset, neglect all the configurations we have parsed so far,
            # except the hyperlinks. Notice that we must not stop here because the same
            # sequence can contain other codes after the reset, like in `\e[0;31m`.
            foreground = ""
            background = ""
            bold       = unchanged
            italic     = unchanged
            underline  = unchanged
            reversed   = unchanged
            reset      = true

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

        elseif (30 ≤ code_i ≤ 37) || (code_i == 39) || (90 ≤ code_i ≤ 97)
            foreground = string(code_i)

        elseif (40 ≤ code_i ≤ 47) || (code_i == 49) || (100 ≤ code_i ≤ 107)
            background = string(code_i)

            # 256-color and true-color (24-bit) support. Both the foreground (38) and the
            # background (48) use the same syntax, which takes additional parameters.
        elseif (code_i == 38) || (code_i == 48)
            is_foreground = code_i == 38

            color_type, pos, found_type = _next_sgr_parameter(code, pos, true)

            if found_type && (color_type == 5)
                # 256-color mode. In this case, we must have another parameter with the
                # color.
                color_code, pos, found_color = _next_sgr_parameter(code, pos, true)

                if found_color
                    color = string(code_i, ";5;", color_code)
                    is_foreground ? (foreground = color) : (background = color)
                end

            elseif found_type && (color_type == 2)
                # True-color (24-bit) mode. In this case, we must have another three
                # parameters with the RGB color.
                color_r, pos, found_r = _next_sgr_parameter(code, pos, true)
                color_g, pos, found_g = _next_sgr_parameter(code, pos, true)
                color_b, pos, found_b = _next_sgr_parameter(code, pos, true)

                if found_r && found_g && found_b
                    color = string(code_i, ";2;", color_r, ";", color_g, ";", color_b)
                    is_foreground ? (foreground = color) : (background = color)
                end
            end
        end
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
        decoration.hyperlink_url_changed,
    )
end
