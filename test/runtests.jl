using RestrainJIT
using Test
using PyCall


function run()
    jit = pyimport(:restrain_jit)
    println(jit)
end

@testset "RestrainJIT.jl" begin
    # Write your own tests here.
end
