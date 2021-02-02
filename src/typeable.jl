

using Base.Threads: lock, unlock, SpinLock
import CanonicalTraits: @trait, @implement
import GeneralizedGenerated: TVal, TNil, Typeable, interpret, to_typelist, to_type, from_type

@implement Typeable{Ptr{T}} where T

@implement Typeable{Vector{T}} where T begin
    to_type(xs) = TVal{Vector{T}, to_typelist(xs)}
    from_type(::Type{TVal{Vector{T}, V}}) where V = T[interpret(V)...]
end

@implement Typeable{Set{T}} where T begin
    to_type(xs) = TVal{Set{T}, to_typelist(collect(xs))}
    from_type(::Type{TVal{Set{T}, V}}) where V = Set(T[interpret(V)...])
end

@implement Typeable{Dict{K, V}} where {K, V} begin
    to_type(xs) = TVal{Dict{K, V}, to_typelist(collect(xs))}
    from_type(::Type{TVal{Dict{K, V}, Ps}}) where Ps = Dict{K, V}(interpret(Ps)...)
end

@implement Typeable{Pair{K, V}} where {K, V} begin
    to_type(xs) = TVal{Pair{K, V}, to_typelist(xs)}
    from_type(::Type{TVal{Pair{K, V}, Ps}}) where Ps = Pair{K, V}(interpret(Ps)...)
end

@implement Typeable{Val{T}} where T
