function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    Base.precompile(Tuple{typeof(highlight_search),Vector{SubString{String}},Regex})   # time: 0.054268923
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :search_regex), Tuple{Int64, Regex}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.036844067
    Base.precompile(Tuple{typeof(align_string_per_line),String,Int64,Symbol})   # time: 0.026609149
    Base.precompile(Tuple{typeof(parse_decoration),String})   # time: 0.02009782
    Base.precompile(Tuple{typeof(highlight_search),String,Regex})   # time: 0.012090348
    Base.precompile(Tuple{typeof(textview),String,NTuple{4, Int64}})   # time: 0.010196379
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :frozen_lines_at_beginning, :parse_decorations_before_view, :search_regex), Tuple{Int64, Int64, Bool, Regex}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.01008306
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :frozen_lines_at_beginning, :search_regex), Tuple{Int64, Int64, Regex}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.009861015
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :frozen_lines_at_beginning, :frozen_columns_at_beginning, :search_regex), Tuple{Int64, Int64, Int64, Regex}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.008096033
    Base.precompile(Tuple{typeof(get_and_remove_decorations),String})   # time: 0.008067413
    Base.precompile(Tuple{typeof(get_decorations),String})   # time: 0.007018877
    Base.precompile(Tuple{Core.kwftype(typeof(highlight_search)),NamedTuple{(:active_match,), Tuple{Int64}},typeof(highlight_search),String,Regex})   # time: 0.004273897
    Base.precompile(Tuple{Core.kwftype(typeof(highlight_search)),NamedTuple{(:active_match, :start_line, :end_line), Tuple{Int64, Int64, Int64}},typeof(highlight_search),Vector{SubString{String}},Regex})   # time: 0.003879215
    Base.precompile(Tuple{typeof(align_string),String,Int64,Symbol})   # time: 0.003496749
    Base.precompile(Tuple{Core.kwftype(typeof(highlight_search)),NamedTuple{(:active_match,), Tuple{Int64}},typeof(highlight_search),Vector{SubString{String}},Regex})   # time: 0.003483683
    Base.precompile(Tuple{Core.kwftype(typeof(Type)),NamedTuple{(:foreground, :background, :reversed), Tuple{String, String, DecorationState}},Type{Decoration}})   # time: 0.002897219
    Base.precompile(Tuple{Core.kwftype(typeof(Type)),NamedTuple{(:foreground, :background, :underline), Tuple{String, String, DecorationState}},Type{Decoration}})   # time: 0.002839241
    Base.precompile(Tuple{Core.kwftype(typeof(Type)),NamedTuple{(:foreground, :background, :bold), Tuple{String, String, DecorationState}},Type{Decoration}})   # time: 0.00279138
    Base.precompile(Tuple{typeof(right_crop),String,Int64})   # time: 0.002321144
    Base.precompile(Tuple{typeof(printable_textwidth_per_line),String})   # time: 0.002131857
    Base.precompile(Tuple{typeof(convert),Type{String},Decoration})   # time: 0.001940608
    Base.precompile(Tuple{typeof(left_crop),String,Int64})   # time: 0.00141604
    Base.precompile(Tuple{Core.kwftype(typeof(align_string)),NamedTuple{(:fill,), Tuple{Bool}},typeof(align_string),String,Int64,Symbol})   # time: 0.001299658
end
