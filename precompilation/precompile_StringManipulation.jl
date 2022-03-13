function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    Base.precompile(Tuple{typeof(highlight_search),Vector{SubString{String}},Regex})   # time: 0.035453446
    Base.precompile(Tuple{typeof(align_string_per_line),String,Int64,Symbol})   # time: 0.03425516
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :search_regex), Tuple{Int64, Regex}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.030122718
    Base.precompile(Tuple{typeof(textview),String,NTuple{4, Int64}})   # time: 0.012940137
    Base.precompile(Tuple{typeof(highlight_search),String,Regex})   # time: 0.012888444
    Base.precompile(Tuple{typeof(parse_decoration),String})   # time: 0.012787138
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :frozen_lines_at_beginning, :search_regex), Tuple{Int64, Int64, Regex}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.011319372
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:maximum_number_of_lines, :maximum_number_of_columns), Tuple{Int64, Int64}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.010735415
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:frozen_columns_at_beginning, :frozen_lines_at_beginning, :maximum_number_of_columns, :maximum_number_of_lines), NTuple{4, Int64}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.010300783
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :frozen_lines_at_beginning, :parse_decorations_before_view, :search_regex), Tuple{Int64, Int64, Bool, Regex}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.00984339
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :frozen_lines_at_beginning, :frozen_columns_at_beginning, :search_regex), Tuple{Int64, Int64, Int64, Regex}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.00864301
    Base.precompile(Tuple{typeof(fit_string_in_field),String,Int64})   # time: 0.006092141
    Base.precompile(Tuple{Core.kwftype(typeof(highlight_search)),NamedTuple{(:active_match, :start_line, :end_line), Tuple{Int64, Int64, Int64}},typeof(highlight_search),Vector{SubString{String}},Regex})   # time: 0.005478579
    Base.precompile(Tuple{typeof(get_and_remove_decorations),String})   # time: 0.004968972
    Base.precompile(Tuple{Core.kwftype(typeof(highlight_search)),NamedTuple{(:active_match,), Tuple{Int64}},typeof(highlight_search),String,Regex})   # time: 0.003862609
    Base.precompile(Tuple{Core.kwftype(typeof(highlight_search)),NamedTuple{(:active_match,), Tuple{Int64}},typeof(highlight_search),Vector{SubString{String}},Regex})   # time: 0.003450822
    Base.precompile(Tuple{typeof(get_decorations),String})   # time: 0.003336575
    Base.precompile(Tuple{typeof(left_crop),String,Int64})   # time: 0.003132419
    Base.precompile(Tuple{Core.kwftype(typeof(Type)),NamedTuple{(:foreground, :background, :underline), Tuple{String, String, DecorationState}},Type{Decoration}})   # time: 0.002871528
    Base.precompile(Tuple{Core.kwftype(typeof(fit_string_in_field)),NamedTuple{(:crop_side, :printable_string_width), Tuple{Symbol, Int64}},typeof(fit_string_in_field),String,Int64})   # time: 0.002685246
    Base.precompile(Tuple{typeof(printable_textwidth_per_line),String})   # time: 0.002575485
    Base.precompile(Tuple{typeof(align_string),String,Int64,Symbol})   # time: 0.002466596
    Base.precompile(Tuple{typeof(convert),Type{String},Decoration})   # time: 0.002363265
    Base.precompile(Tuple{Core.kwftype(typeof(fit_string_in_field)),NamedTuple{(:add_space_in_continuation_char, :crop_side), Tuple{Bool, Symbol}},typeof(fit_string_in_field),String,Int64})   # time: 0.002039394
    Base.precompile(Tuple{Core.kwftype(typeof(Type)),NamedTuple{(:foreground, :background, :reversed), Tuple{String, String, DecorationState}},Type{Decoration}})   # time: 0.001997231
    Base.precompile(Tuple{Core.kwftype(typeof(Type)),NamedTuple{(:foreground, :background, :bold), Tuple{String, String, DecorationState}},Type{Decoration}})   # time: 0.001982216
    Base.precompile(Tuple{Core.kwftype(typeof(fit_string_in_field)),NamedTuple{(:add_space_in_continuation_char, :keep_ansi), Tuple{Bool, Bool}},typeof(fit_string_in_field),String,Int64})   # time: 0.001932996
    Base.precompile(Tuple{Core.kwftype(typeof(fit_string_in_field)),NamedTuple{(:printable_string_width,), Tuple{Int64}},typeof(fit_string_in_field),String,Int64})   # time: 0.001892325
    Base.precompile(Tuple{Core.kwftype(typeof(fit_string_in_field)),NamedTuple{(:crop_side,), Tuple{Symbol}},typeof(fit_string_in_field),String,Int64})   # time: 0.0018295
    Base.precompile(Tuple{Core.kwftype(typeof(fit_string_in_field)),NamedTuple{(:add_space_in_continuation_char,), Tuple{Bool}},typeof(fit_string_in_field),String,Int64})   # time: 0.001823145
    Base.precompile(Tuple{Core.kwftype(typeof(align_string)),NamedTuple{(:fill,), Tuple{Bool}},typeof(align_string),String,Int64,Symbol})   # time: 0.001476437
    Base.precompile(Tuple{Core.kwftype(typeof(right_crop)),NamedTuple{(:printable_string_width,), Tuple{Int64}},typeof(right_crop),String,Int64})   # time: 0.001472248
end
