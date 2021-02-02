function q(ex, module′)
    @switch ex begin
    @case Expr(:macrocall, a, b, args...)  && let new_args = Any[a, b] end ||
          Expr(head, args...) && let new_args = [] end
        for i in eachindex(args)
            @switch args[i] begin
            @case ::LineNumberNode
            @case _
                push!(new_args, q(args[i], module′))
            end
        end
        if length(ex.args) !== length(new_args)
            ex.args = new_args
        end
        nothing
    @case _
    end
    ex
end

macro q(ex)
    esc(Expr(:quote, q(ex, __module__)))
end

@inline function index(xs, x)
    @inbounds for i = eachindex(xs)
        if xs[i] === x
            return i
        end
    end
    nothing
end

@generated function fieldptr(::Type{A}, a::Ptr{T}, ::Val{s}) where {A, T, s}
    off = fieldoffset(T, index(fieldnames(T), s))
    :(reinterpret(Ptr{$A}, reinterpret($Addr, a) +  $off))
end

function _pacc(@nospecialize(ex::Expr))
    @match ex begin
        :($a.$(s::Symbol) :: $A) =>
            :($fieldptr($A, $(_pacc(a)),  $(Val(s))  ))
        :($a.$(s::Symbol)) =>
            :($fieldptr(Nothing, $(_pacc(a)),  $(Val(s)) ))
        ex =>
            begin
                for i in eachindex(ex.args) 
                    ex.args[i] = _pacc(ex.args[i])
                end
                ex
            end
    end
end

_pacc(a) = a

macro pacc(ex)
    esc(_pacc(ex))
end
