function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    Base.precompile(Tuple{typeof(highlight_search),Vector{SubString{String}},Regex})   # time: 0.037570644
    Base.precompile(Tuple{typeof(parse_decoration),String})   # time: 0.035871606
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :search_regex), Tuple{Int64, Regex}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.029893892
    Base.precompile(Tuple{typeof(highlight_search),String,Regex})   # time: 0.013154938
    Base.precompile(Tuple{typeof(textview),String,NTuple{4, Int64}})   # time: 0.010764119
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :frozen_lines_at_beginning, :parse_decorations_before_view, :search_regex), Tuple{Int64, Int64, Bool, Regex}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.009536797
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :frozen_lines_at_beginning, :search_regex), Tuple{Int64, Int64, Regex}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.009152163
    Base.precompile(Tuple{typeof(align_string_per_line),String,Int64,Symbol})   # time: 0.008344889
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :frozen_lines_at_beginning, :frozen_columns_at_beginning, :search_regex), Tuple{Int64, Int64, Int64, Regex}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.007557277
    Base.precompile(Tuple{typeof(fit_string_in_field),String,Int64})   # time: 0.006806255
    Base.precompile(Tuple{Core.kwftype(typeof(highlight_search)),NamedTuple{(:active_match,), Tuple{Int64}},typeof(highlight_search),String,Regex})   # time: 0.004748069
    Base.precompile(Tuple{Core.kwftype(typeof(highlight_search)),NamedTuple{(:active_match, :start_line, :end_line), Tuple{Int64, Int64, Int64}},typeof(highlight_search),Vector{SubString{String}},Regex})   # time: 0.004564029
    Base.precompile(Tuple{typeof(get_and_remove_decorations),String})   # time: 0.004411959
    Base.precompile(Tuple{typeof(get_decorations),String})   # time: 0.00374153
    Base.precompile(Tuple{Core.kwftype(typeof(Type)),NamedTuple{(:foreground, :background, :underline), Tuple{String, String, DecorationState}},Type{Decoration}})   # time: 0.003093702
    Base.precompile(Tuple{Core.kwftype(typeof(highlight_search)),NamedTuple{(:active_match,), Tuple{Int64}},typeof(highlight_search),Vector{SubString{String}},Regex})   # time: 0.002994299
    Base.precompile(Tuple{typeof(left_crop),String,Int64})   # time: 0.002865963
    Base.precompile(Tuple{Core.kwftype(typeof(Type)),NamedTuple{(:foreground, :background, :bold), Tuple{String, String, DecorationState}},Type{Decoration}})   # time: 0.002766432
    Base.precompile(Tuple{Core.kwftype(typeof(Type)),NamedTuple{(:foreground, :background, :reversed), Tuple{String, String, DecorationState}},Type{Decoration}})   # time: 0.0024388
    Base.precompile(Tuple{Core.kwftype(typeof(fit_string_in_field)),NamedTuple{(:add_space_in_continuation_char,), Tuple{Bool}},typeof(fit_string_in_field),String,Int64})   # time: 0.002305217
    Base.precompile(Tuple{Core.kwftype(typeof(fit_string_in_field)),NamedTuple{(:printable_string_width,), Tuple{Int64}},typeof(fit_string_in_field),String,Int64})   # time: 0.002211707
    Base.precompile(Tuple{typeof(convert),Type{String},Decoration})   # time: 0.002123356
    Base.precompile(Tuple{typeof(printable_textwidth_per_line),String})   # time: 0.002121224
    Base.precompile(Tuple{Core.kwftype(typeof(fit_string_in_field)),NamedTuple{(:crop_side,), Tuple{Symbol}},typeof(fit_string_in_field),String,Int64})   # time: 0.002070006
    Base.precompile(Tuple{Core.kwftype(typeof(fit_string_in_field)),NamedTuple{(:add_space_in_continuation_char, :crop_side), Tuple{Bool, Symbol}},typeof(fit_string_in_field),String,Int64})   # time: 0.002009737
    Base.precompile(Tuple{typeof(align_string),String,Int64,Symbol})   # time: 0.001942715
    Base.precompile(Tuple{Core.kwftype(typeof(fit_string_in_field)),NamedTuple{(:add_space_in_continuation_char, :keep_ansi), Tuple{Bool, Bool}},typeof(fit_string_in_field),String,Int64})   # time: 0.001931353
    Base.precompile(Tuple{Core.kwftype(typeof(fit_string_in_field)),NamedTuple{(:crop_side, :printable_string_width), Tuple{Symbol, Int64}},typeof(fit_string_in_field),String,Int64})   # time: 0.001888628
    Base.precompile(Tuple{Core.kwftype(typeof(align_string)),NamedTuple{(:fill,), Tuple{Bool}},typeof(align_string),String,Int64,Symbol})   # time: 0.001732335
    Base.precompile(Tuple{Core.kwftype(typeof(right_crop)),NamedTuple{(:printable_string_width,), Tuple{Int64}},typeof(right_crop),String,Int64})   # time: 0.001719973
end
