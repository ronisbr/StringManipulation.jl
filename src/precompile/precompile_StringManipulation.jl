function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    Base.precompile(Tuple{typeof(highlight_search),Vector{SubString{String}},Regex})   # time: 0.050175916
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :search_regex), Tuple{Int64, Regex}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.03469408
    Base.precompile(Tuple{typeof(align_string_per_line),String,Int64,Symbol})   # time: 0.020051915
    Base.precompile(Tuple{typeof(highlight_search),String,Regex})   # time: 0.012764203
    Base.precompile(Tuple{typeof(parse_decoration),String})   # time: 0.011735702
    Base.precompile(Tuple{typeof(textview),String,NTuple{4, Int64}})   # time: 0.007458515
    Base.precompile(Tuple{Core.kwftype(typeof(textview)),NamedTuple{(:active_match, :frozen_lines_at_beginning, :frozen_columns_at_beginning, :search_regex), Tuple{Int64, Int64, Int64, Regex}},typeof(textview),String,NTuple{4, Int64}})   # time: 0.006870352
    Base.precompile(Tuple{typeof(get_and_remove_decorations),String})   # time: 0.004339446
    Base.precompile(Tuple{Core.kwftype(typeof(highlight_search)),NamedTuple{(:active_match,), Tuple{Int64}},typeof(highlight_search),String,Regex})   # time: 0.004196927
    Base.precompile(Tuple{Core.kwftype(typeof(highlight_search)),NamedTuple{(:active_match, :start_line, :end_line), Tuple{Int64, Int64, Int64}},typeof(highlight_search),Vector{SubString{String}},Regex})   # time: 0.003891865
    Base.precompile(Tuple{typeof(get_decorations),String})   # time: 0.003664701
    Base.precompile(Tuple{Core.kwftype(typeof(highlight_search)),NamedTuple{(:active_match,), Tuple{Int64}},typeof(highlight_search),Vector{SubString{String}},Regex})   # time: 0.003053725
    Base.precompile(Tuple{Core.kwftype(typeof(Type)),NamedTuple{(:foreground, :background, :bold), Tuple{String, String, DecorationState}},Type{Decoration}})   # time: 0.002865515
    Base.precompile(Tuple{Core.kwftype(typeof(Type)),NamedTuple{(:foreground, :background, :reversed), Tuple{String, String, DecorationState}},Type{Decoration}})   # time: 0.002561145
    Base.precompile(Tuple{typeof(align_string),String,Int64,Symbol})   # time: 0.002492407
    Base.precompile(Tuple{typeof(printable_textwidth_per_line),String})   # time: 0.002303863
    Base.precompile(Tuple{Core.kwftype(typeof(Type)),NamedTuple{(:foreground, :background, :underline), Tuple{String, String, DecorationState}},Type{Decoration}})   # time: 0.002171533
    Base.precompile(Tuple{typeof(convert),Type{String},Decoration})   # time: 0.001723879
    Base.precompile(Tuple{typeof(right_crop),String,Int64})   # time: 0.001532011
    Base.precompile(Tuple{Core.kwftype(typeof(align_string)),NamedTuple{(:fill,), Tuple{Bool}},typeof(align_string),String,Int64,Symbol})   # time: 0.001513753
    Base.precompile(Tuple{typeof(left_crop),String,Int64})   # time: 0.001037562
end
