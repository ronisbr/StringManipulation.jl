function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :search_regex), Tuple{Int64, Regex}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.05756197
    Base.precompile(Tuple{typeof(highlight_search),Vector{SubString{String}},Regex})   # time: 0.046503454
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :frozen_lines_at_beginning, :parse_decorations_before_view, :search_regex), Tuple{Int64, Int64, Bool, Regex}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.02385397
    Base.precompile(Tuple{typeof(parse_decoration),String})   # time: 0.016701551
    Base.precompile(Tuple{typeof(textview),String,NTuple{4, Int64}})   # time: 0.015251538
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :frozen_lines_at_beginning, :frozen_columns_at_beginning, :search_regex, :show_ruler), Tuple{Int64, Int64, Int64, Regex, Bool}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.012337314
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :frozen_lines_at_beginning, :frozen_columns_at_beginning, :search_regex), Tuple{Int64, Int64, Int64, Regex}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.011583624
    Base.precompile(Tuple{typeof(highlight_search),String,Regex})   # time: 0.011200102
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :frozen_lines_at_beginning, :search_regex), Tuple{Int64, Int64, Regex}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.010555814
    Base.precompile(Tuple{typeof(fit_string_in_field),String,Int64})   # time: 0.008958304
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:frozen_columns_at_beginning, :frozen_lines_at_beginning, :maximum_number_of_columns, :maximum_number_of_lines), NTuple{4, Int64}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.008937403
    Base.precompile(Tuple{typeof(align_string_per_line),String,Int64,Symbol})   # time: 0.008288037
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:frozen_columns_at_beginning, :maximum_number_of_columns), Tuple{Int64, Int64}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.008263509
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:maximum_number_of_lines, :maximum_number_of_columns), Tuple{Int64, Int64}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.008091334
    Base.precompile(Tuple{typeof(align_string),String,Int64,Symbol})   # time: 0.00577815
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:frozen_columns_at_beginning, :frozen_lines_at_beginning, :title_lines), Tuple{Int64, Int64, Int64}},typeof(textview),Vector{SubString{String}},NTuple{4, Int64}})   # time: 0.005121486
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :search_matches), Tuple{Int64, Dict{Int64, Vector{Tuple{Int64, Int64}}}}},typeof(textview),Vector{SubString{String}},NTuple{4, Int64}})   # time: 0.004682578
    Base.precompile(Tuple{Core.kwftype(typeof(highlight_search)),NamedTuple{(:active_match,), Tuple{Int64}},typeof(highlight_search),String,Regex})   # time: 0.004434722
    Base.precompile(Tuple{typeof(get_and_remove_decorations),String})   # time: 0.004345067
    Base.precompile(Tuple{Core.kwftype(typeof(highlight_search)),NamedTuple{(:active_match, :start_line, :end_line), Tuple{Int64, Int64, Int64}},typeof(highlight_search),Vector{SubString{String}},Regex})   # time: 0.004092387
    Base.precompile(Tuple{typeof(get_decorations),String})   # time: 0.003967475
    Base.precompile(Tuple{typeof(left_crop),String,Int64})   # time: 0.002836431
    Base.precompile(Tuple{Core.kwftype(typeof(Type)),NamedTuple{(:foreground, :background, :reversed), Tuple{String, String, DecorationState}},Type{Decoration}})   # time: 0.002805253
    Base.precompile(Tuple{Core.kwftype(typeof(highlight_search)),NamedTuple{(:active_match,), Tuple{Int64}},typeof(highlight_search),Vector{SubString{String}},Regex})   # time: 0.002690855
    Base.precompile(Tuple{Core.kwftype(typeof(fit_string_in_field)),NamedTuple{(:add_space_in_continuation_char, :crop_side), Tuple{Bool, Symbol}},typeof(fit_string_in_field),String,Int64})   # time: 0.002682176
    Base.precompile(Tuple{Core.kwftype(typeof(fit_string_in_field)),NamedTuple{(:crop_side, :printable_string_width), Tuple{Symbol, Int64}},typeof(fit_string_in_field),String,Int64})   # time: 0.002671034
    Base.precompile(Tuple{Core.kwftype(typeof(fit_string_in_field)),NamedTuple{(:add_space_in_continuation_char,), Tuple{Bool}},typeof(fit_string_in_field),String,Int64})   # time: 0.002624387
    Base.precompile(Tuple{typeof(printable_textwidth_per_line),String})   # time: 0.002273202
    Base.precompile(Tuple{Core.kwftype(typeof(Type)),NamedTuple{(:foreground, :background, :underline), Tuple{String, String, DecorationState}},Type{Decoration}})   # time: 0.002138512
    Base.precompile(Tuple{Core.kwftype(typeof(fit_string_in_field)),NamedTuple{(:printable_string_width,), Tuple{Int64}},typeof(fit_string_in_field),String,Int64})   # time: 0.002021772
    Base.precompile(Tuple{Core.kwftype(typeof(fit_string_in_field)),NamedTuple{(:add_space_in_continuation_char, :keep_ansi), Tuple{Bool, Bool}},typeof(fit_string_in_field),String,Int64})   # time: 0.002019176
    Base.precompile(Tuple{Core.kwftype(typeof(Type)),NamedTuple{(:foreground, :background, :bold), Tuple{String, String, DecorationState}},Type{Decoration}})   # time: 0.00201245
    Base.precompile(Tuple{Core.kwftype(typeof(fit_string_in_field)),NamedTuple{(:crop_side,), Tuple{Symbol}},typeof(fit_string_in_field),String,Int64})   # time: 0.001807848
    Base.precompile(Tuple{Core.kwftype(typeof(fit_string_in_field)),NamedTuple{(:keep_ansi,), Tuple{Bool}},typeof(fit_string_in_field),String,Int64})   # time: 0.00178136
    Base.precompile(Tuple{typeof(convert),Type{String},Decoration})   # time: 0.00177276
    Base.precompile(Tuple{Core.kwftype(typeof(align_string)),NamedTuple{(:fill,), Tuple{Bool}},typeof(align_string),String,Int64,Symbol})   # time: 0.001585808
    Base.precompile(Tuple{Core.kwftype(typeof(right_crop)),NamedTuple{(:printable_string_width,), Tuple{Int64}},typeof(right_crop),String,Int64})   # time: 0.001535922
end
