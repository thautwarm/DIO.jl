@inline function py_fast_foreach(xs)
    @inline function (f)
        foreach(f, xs)
    end
end

@inline function py_fast_map(xs)
    @inline function (f)
        map(f, xs)
    end
end

@inline function simd_foreach(xs::V) where {T, V <: AbstractArray{T, 1}}
    @inline function (f)
        n = length(xs)
        @inbounds @simd for i = 1:n
            f(xs[i])
        end
    end
end

struct Out{A}
    __contents :: A
end

function out(a::A) where A
    Out(a)
end

@inline function simd_map(xs::V1, out_::Out{V2}) where {T, G, V1 <: AbstractArray{T, 1}, V2 <: AbstractArray{G, 1}}
    out = out_.__contents
    @inline function (f)
        n = length(xs)
        @inbounds @simd for i = 1:n
            out[i] = f(xs[i])
        end
    end
end

function init_functional!()
    fp = pyimport("restrain_jit.bejulia.functional")

    fp.select.__jit__ = py_fast_map
    fp.foreach.__jit__ = py_fast_foreach
    fp.J.__jit__ = as_constant
    fp.simd_select.__jit__ = simd_map
    fp.simd_foreach.__jit__ = simd_foreach
    fp.out.__jit__ = out
end