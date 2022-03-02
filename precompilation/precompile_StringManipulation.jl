function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :search_regex), Tuple{Int64, Regex}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.1271568
    Base.precompile(Tuple{typeof(highlight_search),Vector{SubString{String}},Regex})   # time: 0.04527043
    Base.precompile(Tuple{Core.kwftype(typeof(highlight_search)),NamedTuple{(:active_match,), Tuple{Int64}},typeof(highlight_search),String,Regex})   # time: 0.021410862
    Base.precompile(Tuple{typeof(highlight_search),String,Regex})   # time: 0.015917128
    Base.precompile(Tuple{typeof(parse_decoration),String})   # time: 0.014905032
    Base.precompile(Tuple{typeof(textview),String,NTuple{4, Int64}})   # time: 0.010873032
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :frozen_lines_at_beginning, :frozen_columns_at_beginning, :search_regex), Tuple{Int64, Int64, Int64, Regex}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.009862223
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :frozen_lines_at_beginning, :parse_decorations_before_view, :search_regex), Tuple{Int64, Int64, Bool, Regex}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.009279411
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :frozen_lines_at_beginning, :search_regex), Tuple{Int64, Int64, Regex}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.008148287
    Base.precompile(Tuple{typeof(align_string_per_line),String,Int64,Symbol})   # time: 0.007033622
    Base.precompile(Tuple{Core.kwftype(typeof(highlight_search)),NamedTuple{(:active_match, :start_line, :end_line), Tuple{Int64, Int64, Int64}},typeof(highlight_search),Vector{SubString{String}},Regex})   # time: 0.004565959
    Base.precompile(Tuple{typeof(get_and_remove_decorations),String})   # time: 0.004545716
    Base.precompile(Tuple{typeof(get_decorations),String})   # time: 0.003893226
    Base.precompile(Tuple{typeof(align_string),String,Int64,Symbol})   # time: 0.003770027
    Base.precompile(Tuple{Core.kwftype(typeof(Type)),NamedTuple{(:foreground, :background, :underline), Tuple{String, String, DecorationState}},Type{Decoration}})   # time: 0.003676459
    Base.precompile(Tuple{Core.kwftype(typeof(highlight_search)),NamedTuple{(:active_match,), Tuple{Int64}},typeof(highlight_search),Vector{SubString{String}},Regex})   # time: 0.00334076
    Base.precompile(Tuple{typeof(printable_textwidth_per_line),String})   # time: 0.002716565
    Base.precompile(Tuple{Core.kwftype(typeof(Type)),NamedTuple{(:foreground, :background, :reversed), Tuple{String, String, DecorationState}},Type{Decoration}})   # time: 0.002633058
    Base.precompile(Tuple{typeof(convert),Type{String},Decoration})   # time: 0.00256183
    Base.precompile(Tuple{Core.kwftype(typeof(Type)),NamedTuple{(:foreground, :background, :bold), Tuple{String, String, DecorationState}},Type{Decoration}})   # time: 0.002539305
    Base.precompile(Tuple{typeof(right_crop),String,Int64})   # time: 0.001462144
    Base.precompile(Tuple{Core.kwftype(typeof(align_string)),NamedTuple{(:fill,), Tuple{Bool}},typeof(align_string),String,Int64,Symbol})   # time: 0.001403023
    Base.precompile(Tuple{typeof(left_crop),String,Int64})   # time: 0.001130497
end
