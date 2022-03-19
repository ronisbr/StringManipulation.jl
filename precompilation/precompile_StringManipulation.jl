function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    Base.precompile(Tuple{typeof(highlight_search),Vector{SubString{String}},Regex})   # time: 0.059157036
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :search_regex), Tuple{Int64, Regex}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.058709044
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :frozen_lines_at_beginning, :search_regex), Tuple{Int64, Int64, Regex}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.025712194
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :frozen_lines_at_beginning, :frozen_columns_at_beginning, :search_regex), Tuple{Int64, Int64, Int64, Regex}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.01779813
    Base.precompile(Tuple{typeof(textview),String,NTuple{4, Int64}})   # time: 0.015094872
    Base.precompile(Tuple{typeof(parse_decoration),String})   # time: 0.014008783
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :frozen_lines_at_beginning, :parse_decorations_before_view, :search_regex), Tuple{Int64, Int64, Bool, Regex}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.013855798
    Base.precompile(Tuple{typeof(align_string_per_line),String,Int64,Symbol})   # time: 0.012167775
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :frozen_lines_at_beginning, :frozen_columns_at_beginning, :search_regex, :show_ruler), Tuple{Int64, Int64, Int64, Regex, Bool}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.011858754
    Base.precompile(Tuple{typeof(highlight_search),String,Regex})   # time: 0.011790905
    Base.precompile(Tuple{typeof(fit_string_in_field),String,Int64})   # time: 0.010749603
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:frozen_columns_at_beginning, :frozen_lines_at_beginning, :maximum_number_of_columns, :maximum_number_of_lines), NTuple{4, Int64}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.010748933
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:maximum_number_of_lines, :maximum_number_of_columns), Tuple{Int64, Int64}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.009999969
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:frozen_columns_at_beginning, :maximum_number_of_columns), Tuple{Int64, Int64}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.009609414
    Base.precompile(Tuple{typeof(align_string),String,Int64,Symbol})   # time: 0.006738714
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:frozen_columns_at_beginning, :frozen_lines_at_beginning, :title_lines), Tuple{Int64, Int64, Int64}},typeof(textview),Vector{SubString{String}},NTuple{4, Int64}})   # time: 0.00565889
    Base.precompile(Tuple{typeof(get_and_remove_decorations),String})   # time: 0.004928707
    Base.precompile(Tuple{Core.kwftype(typeof(highlight_search)),NamedTuple{(:active_match,), Tuple{Int64}},typeof(highlight_search),String,Regex})   # time: 0.004911768
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :search_matches), Tuple{Int64, Dict{Int64, Vector{Tuple{Int64, Int64}}}}},typeof(textview),Vector{SubString{String}},NTuple{4, Int64}})   # time: 0.004447444
    Base.precompile(Tuple{Core.kwftype(typeof(highlight_search)),NamedTuple{(:active_match, :start_line, :end_line), Tuple{Int64, Int64, Int64}},typeof(highlight_search),Vector{SubString{String}},Regex})   # time: 0.004381782
    Base.precompile(Tuple{typeof(get_decorations),String})   # time: 0.00303308
    Base.precompile(Tuple{Core.kwftype(typeof(Type)),NamedTuple{(:foreground, :background, :underline), Tuple{String, String, DecorationState}},Type{Decoration}})   # time: 0.002692545
    Base.precompile(Tuple{Core.kwftype(typeof(fit_string_in_field)),NamedTuple{(:crop_side, :printable_string_width), Tuple{Symbol, Int64}},typeof(fit_string_in_field),String,Int64})   # time: 0.002690417
    Base.precompile(Tuple{Core.kwftype(typeof(highlight_search)),NamedTuple{(:active_match,), Tuple{Int64}},typeof(highlight_search),Vector{SubString{String}},Regex})   # time: 0.002600482
    Base.precompile(Tuple{Core.kwftype(typeof(fit_string_in_field)),NamedTuple{(:add_space_in_continuation_char,), Tuple{Bool}},typeof(fit_string_in_field),String,Int64})   # time: 0.002591723
    Base.precompile(Tuple{Core.kwftype(typeof(fit_string_in_field)),NamedTuple{(:printable_string_width,), Tuple{Int64}},typeof(fit_string_in_field),String,Int64})   # time: 0.00258039
    Base.precompile(Tuple{typeof(left_crop),String,Int64})   # time: 0.00254965
    Base.precompile(Tuple{Core.kwftype(typeof(fit_string_in_field)),NamedTuple{(:crop_side,), Tuple{Symbol}},typeof(fit_string_in_field),String,Int64})   # time: 0.002482469
    Base.precompile(Tuple{Core.kwftype(typeof(fit_string_in_field)),NamedTuple{(:add_space_in_continuation_char, :keep_ansi), Tuple{Bool, Bool}},typeof(fit_string_in_field),String,Int64})   # time: 0.002358202
    Base.precompile(Tuple{typeof(printable_textwidth_per_line),String})   # time: 0.002345092
    Base.precompile(Tuple{Core.kwftype(typeof(align_string)),NamedTuple{(:fill,), Tuple{Bool}},typeof(align_string),String,Int64,Symbol})   # time: 0.00233521
    Base.precompile(Tuple{Core.kwftype(typeof(Type)),NamedTuple{(:foreground, :background, :reversed), Tuple{String, String, DecorationState}},Type{Decoration}})   # time: 0.002195955
    Base.precompile(Tuple{Core.kwftype(typeof(fit_string_in_field)),NamedTuple{(:keep_ansi,), Tuple{Bool}},typeof(fit_string_in_field),String,Int64})   # time: 0.002191823
    Base.precompile(Tuple{Core.kwftype(typeof(Type)),NamedTuple{(:foreground, :background, :bold), Tuple{String, String, DecorationState}},Type{Decoration}})   # time: 0.002106865
    Base.precompile(Tuple{Core.kwftype(typeof(Type)),NamedTuple{(:foreground, :background, :bold, :underline, :reversed), Tuple{String, String, DecorationState, DecorationState, DecorationState}},Type{Decoration}})   # time: 0.002102631
    Base.precompile(Tuple{Core.kwftype(typeof(fit_string_in_field)),NamedTuple{(:add_space_in_continuation_char, :crop_side), Tuple{Bool, Symbol}},typeof(fit_string_in_field),String,Int64})   # time: 0.002086886
    Base.precompile(Tuple{Core.kwftype(typeof(Type)),NamedTuple{(:background,), Tuple{String}},Type{Decoration}})   # time: 0.001959384
    Base.precompile(Tuple{typeof(convert),Type{String},Decoration})   # time: 0.001886508
    Base.precompile(Tuple{Core.kwftype(typeof(right_crop)),NamedTuple{(:printable_string_width,), Tuple{Int64}},typeof(right_crop),String,Int64})   # time: 0.001595281
    Base.precompile(Tuple{typeof(drop_inactive_properties),Decoration})   # time: 0.001566229
end
