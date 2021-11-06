using Test
using StringManipulation

@testset "Alignment" verbose = true begin
    include("./alignment.jl")
end

@testset "Cropping" verbose = true begin
    include("./crop.jl")
end

@testset "Splitting" verbose = true begin
    include("./split.jl")
end

@testset "Width" verbose = true begin
    include("./width.jl")
end
