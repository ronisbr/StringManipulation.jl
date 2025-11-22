using Test
using StringManipulation
using Markdown

@testset "Alignment" verbose = true begin
    include("./alignment.jl")
end

@testset "ANSI Parsing" verbose = true begin
    include("./ansi.jl")
end

@testset "Cropping" verbose = true begin
    include("./crop.jl")
end

@testset "Decorations" verbose = true begin
    include("./decorations.jl")
end

@testset "Highlighting" verbose = true begin
    include("./highlighting.jl")
end

@testset "Search" verbose = true begin
    include("./search.jl")
end

@testset "Splitting" verbose = true begin
    include("./split.jl")
end

@testset "View" verbose = true begin
    include("./view.jl")
end

@testset "Width" verbose = true begin
    include("./width.jl")
end
