function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :search_regex), Tuple{Int64, Regex}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.04248239
    Base.precompile(Tuple{typeof(highlight_search),Vector{SubString{String}},Regex})   # time: 0.039755434
    Base.precompile(Tuple{Core.kwftype(typeof(highlight_search)),NamedTuple{(:active_match,), Tuple{Int64}},typeof(highlight_search),String,Regex})   # time: 0.019656224
    Base.precompile(Tuple{typeof(parse_decoration),String})   # time: 0.01600681
    Base.precompile(Tuple{typeof(textview),String,NTuple{4, Int64}})   # time: 0.015917107
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :frozen_lines_at_beginning, :frozen_columns_at_beginning, :search_regex), Tuple{Int64, Int64, Int64, Regex}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.015234063
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :frozen_lines_at_beginning, :search_regex), Tuple{Int64, Int64, Regex}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.014564813
    Base.precompile(Tuple{typeof(highlight_search),String,Regex})   # time: 0.012699837
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :frozen_lines_at_beginning, :parse_decorations_before_view, :search_regex), Tuple{Int64, Int64, Bool, Regex}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.012503749
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:maximum_number_of_lines, :maximum_number_of_columns), Tuple{Int64, Int64}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.011923233
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:frozen_columns_at_beginning, :frozen_lines_at_beginning, :maximum_number_of_columns, :maximum_number_of_lines), NTuple{4, Int64}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.010086564
    Base.precompile(Tuple{typeof(align_string_per_line),String,Int64,Symbol})   # time: 0.009913398
    Base.precompile(Tuple{typeof(fit_string_in_field),String,Int64})   # time: 0.008379773
    Base.precompile(Tuple{Core.kwftype(typeof(highlight_search)),NamedTuple{(:active_match, :start_line, :end_line), Tuple{Int64, Int64, Int64}},typeof(highlight_search),Vector{SubString{String}},Regex})   # time: 0.005215483
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :search_matches), Tuple{Int64, Dict{Int64, Vector{Tuple{Int64, Int64}}}}},typeof(textview),Vector{SubString{String}},NTuple{4, Int64}})   # time: 0.004427579
    Base.precompile(Tuple{typeof(get_and_remove_decorations),String})   # time: 0.003817019
    Base.precompile(Tuple{Core.kwftype(typeof(highlight_search)),NamedTuple{(:active_match,), Tuple{Int64}},typeof(highlight_search),Vector{SubString{String}},Regex})   # time: 0.003514607
    Base.precompile(Tuple{Core.kwftype(typeof(Type)),NamedTuple{(:foreground, :background, :reversed), Tuple{String, String, DecorationState}},Type{Decoration}})   # time: 0.003387064
    Base.precompile(Tuple{typeof(get_decorations),String})   # time: 0.003379266
    Base.precompile(Tuple{typeof(left_crop),String,Int64})   # time: 0.002645497
    Base.precompile(Tuple{Core.kwftype(typeof(fit_string_in_field)),NamedTuple{(:add_space_in_continuation_char,), Tuple{Bool}},typeof(fit_string_in_field),String,Int64})   # time: 0.002642609
    Base.precompile(Tuple{typeof(align_string),String,Int64,Symbol})   # time: 0.002464602
    Base.precompile(Tuple{Core.kwftype(typeof(Type)),NamedTuple{(:foreground, :background, :underline), Tuple{String, String, DecorationState}},Type{Decoration}})   # time: 0.002437005
    Base.precompile(Tuple{Core.kwftype(typeof(Type)),NamedTuple{(:foreground, :background, :bold), Tuple{String, String, DecorationState}},Type{Decoration}})   # time: 0.002397771
    Base.precompile(Tuple{Core.kwftype(typeof(fit_string_in_field)),NamedTuple{(:add_space_in_continuation_char, :keep_ansi), Tuple{Bool, Bool}},typeof(fit_string_in_field),String,Int64})   # time: 0.002388716
    Base.precompile(Tuple{Core.kwftype(typeof(fit_string_in_field)),NamedTuple{(:crop_side, :printable_string_width), Tuple{Symbol, Int64}},typeof(fit_string_in_field),String,Int64})   # time: 0.002368989
    Base.precompile(Tuple{Core.kwftype(typeof(fit_string_in_field)),NamedTuple{(:printable_string_width,), Tuple{Int64}},typeof(fit_string_in_field),String,Int64})   # time: 0.002258126
    Base.precompile(Tuple{typeof(printable_textwidth_per_line),String})   # time: 0.002250706
    Base.precompile(Tuple{Core.kwftype(typeof(fit_string_in_field)),NamedTuple{(:add_space_in_continuation_char, :crop_side), Tuple{Bool, Symbol}},typeof(fit_string_in_field),String,Int64})   # time: 0.002225671
    Base.precompile(Tuple{Core.kwftype(typeof(align_string)),NamedTuple{(:fill,), Tuple{Bool}},typeof(align_string),String,Int64,Symbol})   # time: 0.002045607
    Base.precompile(Tuple{typeof(convert),Type{String},Decoration})   # time: 0.002017901
    Base.precompile(Tuple{Core.kwftype(typeof(fit_string_in_field)),NamedTuple{(:crop_side,), Tuple{Symbol}},typeof(fit_string_in_field),String,Int64})   # time: 0.001928638
    Base.precompile(Tuple{Core.kwftype(typeof(right_crop)),NamedTuple{(:printable_string_width,), Tuple{Int64}},typeof(right_crop),String,Int64})   # time: 0.001473253
end
