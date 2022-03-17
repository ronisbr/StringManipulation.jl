function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :search_regex), Tuple{Int64, Regex}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.04918231
    Base.precompile(Tuple{typeof(highlight_search),Vector{SubString{String}},Regex})   # time: 0.043962017
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :frozen_lines_at_beginning, :parse_decorations_before_view, :search_regex), Tuple{Int64, Int64, Bool, Regex}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.021716774
    Base.precompile(Tuple{typeof(parse_decoration),String})   # time: 0.014083841
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :frozen_lines_at_beginning, :frozen_columns_at_beginning, :search_regex), Tuple{Int64, Int64, Int64, Regex}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.013436885
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :frozen_lines_at_beginning, :search_regex), Tuple{Int64, Int64, Regex}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.01324201
    Base.precompile(Tuple{typeof(textview),String,NTuple{4, Int64}})   # time: 0.011541274
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:frozen_columns_at_beginning, :frozen_lines_at_beginning, :maximum_number_of_columns, :maximum_number_of_lines), NTuple{4, Int64}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.011185564
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :frozen_lines_at_beginning, :frozen_columns_at_beginning, :search_regex, :show_ruler), Tuple{Int64, Int64, Int64, Regex, Bool}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.009926089
    Base.precompile(Tuple{typeof(highlight_search),String,Regex})   # time: 0.009554724
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:maximum_number_of_lines, :maximum_number_of_columns), Tuple{Int64, Int64}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.008710459
    Base.precompile(Tuple{typeof(fit_string_in_field),String,Int64})   # time: 0.008467676
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:frozen_columns_at_beginning, :maximum_number_of_columns), Tuple{Int64, Int64}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.008265863
    Base.precompile(Tuple{typeof(align_string_per_line),String,Int64,Symbol})   # time: 0.006892874
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :search_matches), Tuple{Int64, Dict{Int64, Vector{Tuple{Int64, Int64}}}}},typeof(textview),Vector{SubString{String}},NTuple{4, Int64}})   # time: 0.004589216
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:frozen_columns_at_beginning, :frozen_lines_at_beginning, :title_lines), Tuple{Int64, Int64, Int64}},typeof(textview),Vector{SubString{String}},NTuple{4, Int64}})   # time: 0.004467939
    Base.precompile(Tuple{Core.kwftype(typeof(highlight_search)),NamedTuple{(:active_match, :start_line, :end_line), Tuple{Int64, Int64, Int64}},typeof(highlight_search),Vector{SubString{String}},Regex})   # time: 0.004391966
    Base.precompile(Tuple{typeof(get_and_remove_decorations),String})   # time: 0.003964237
    Base.precompile(Tuple{Core.kwftype(typeof(highlight_search)),NamedTuple{(:active_match,), Tuple{Int64}},typeof(highlight_search),String,Regex})   # time: 0.003635703
    Base.precompile(Tuple{typeof(left_crop),String,Int64})   # time: 0.003146
    Base.precompile(Tuple{Core.kwftype(typeof(highlight_search)),NamedTuple{(:active_match,), Tuple{Int64}},typeof(highlight_search),Vector{SubString{String}},Regex})   # time: 0.002687778
    Base.precompile(Tuple{typeof(printable_textwidth_per_line),String})   # time: 0.002556589
    Base.precompile(Tuple{Core.kwftype(typeof(Type)),NamedTuple{(:foreground, :background, :underline), Tuple{String, String, DecorationState}},Type{Decoration}})   # time: 0.002518836
    Base.precompile(Tuple{typeof(convert),Type{String},Decoration})   # time: 0.002254738
    Base.precompile(Tuple{Core.kwftype(typeof(Type)),NamedTuple{(:foreground, :background, :bold), Tuple{String, String, DecorationState}},Type{Decoration}})   # time: 0.002101617
    Base.precompile(Tuple{Core.kwftype(typeof(Type)),NamedTuple{(:foreground, :background, :reversed), Tuple{String, String, DecorationState}},Type{Decoration}})   # time: 0.001999934
    Base.precompile(Tuple{Core.kwftype(typeof(fit_string_in_field)),NamedTuple{(:add_space_in_continuation_char,), Tuple{Bool}},typeof(fit_string_in_field),String,Int64})   # time: 0.001981247
    Base.precompile(Tuple{Core.kwftype(typeof(fit_string_in_field)),NamedTuple{(:printable_string_width,), Tuple{Int64}},typeof(fit_string_in_field),String,Int64})   # time: 0.001946069
    Base.precompile(Tuple{Core.kwftype(typeof(fit_string_in_field)),NamedTuple{(:add_space_in_continuation_char, :keep_ansi), Tuple{Bool, Bool}},typeof(fit_string_in_field),String,Int64})   # time: 0.001924444
    Base.precompile(Tuple{Core.kwftype(typeof(fit_string_in_field)),NamedTuple{(:crop_side, :printable_string_width), Tuple{Symbol, Int64}},typeof(fit_string_in_field),String,Int64})   # time: 0.001869227
    Base.precompile(Tuple{Core.kwftype(typeof(fit_string_in_field)),NamedTuple{(:add_space_in_continuation_char, :crop_side), Tuple{Bool, Symbol}},typeof(fit_string_in_field),String,Int64})   # time: 0.00185098
    Base.precompile(Tuple{Core.kwftype(typeof(fit_string_in_field)),NamedTuple{(:crop_side,), Tuple{Symbol}},typeof(fit_string_in_field),String,Int64})   # time: 0.001800185
    Base.precompile(Tuple{Core.kwftype(typeof(fit_string_in_field)),NamedTuple{(:keep_ansi,), Tuple{Bool}},typeof(fit_string_in_field),String,Int64})   # time: 0.001752358
    Base.precompile(Tuple{typeof(align_string),String,Int64,Symbol})   # time: 0.001655074
    Base.precompile(Tuple{Core.kwftype(typeof(right_crop)),NamedTuple{(:printable_string_width,), Tuple{Int64}},typeof(right_crop),String,Int64})   # time: 0.001467168
    Base.precompile(Tuple{Core.kwftype(typeof(align_string)),NamedTuple{(:fill,), Tuple{Bool}},typeof(align_string),String,Int64,Symbol})   # time: 0.001331419
end
