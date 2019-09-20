
"""
Representation of Restrain JIT objects
"""
# struct Res{T}
#     __contents::T
# end

# Base.show(io::IO, r::Res) = Base.show(io, r.__contents)

as_constant_expr(a) = a

function as_constant_expr(a::PyObject)
    hasattr = pybuiltin("hasattr")
    if hasattr(a, "__jit__")
        return a.__jit__
    end
    as_constant_expr(a, a."__class__".__name__ |> Symbol |> Val)
end


# cannot get treated as Julia objects
function as_constant_expr(a::PyObject, ::Val)
    a
end

function as_constant_expr(a::PyObject, ::Union{Val{:int}, Val{:str}, Val{:complex}, Val{:float}, Val{:NoneType}})
    PyAny(n)
end

function as_constant_expr(a::PyObject, ::Union{Val{:bytes}})
    error("Not implemented yet")
end


function as_constant_expr(a::PyObject, ::Val{:list})
    Expr(:vect, map(as_constant_expr, a)...)
end

function as_constant_expr(a::PyObject, ::Val{:tuple})
    Expr(:tuple, map(as_constant_expr, a)...)
end

function as_constant_expr(a::PyObject, ::Val{:dict})
    mk_pair(kv) = begin
        k, v = Tuple(kv)
        k = as_constant_expr(k)
        v = as_constant_expr(v)
        :($k => $v)
    end
    Expr(:call, Dict, map(mk_pair, pycall(a."items", PyObject))...)
end

function as_constant_expr(a::PyObject, ::Val{:set})
    Expr(
        :call,
        Set,
        Expr(:vect, map(as_constant_expr, a)...)
    )
end


as_constant(a) = a

function as_constant(a::PyObject)
    hasattr = pybuiltin("hasattr")
    if hasattr(a, "__jit__")
        return a.__jit__
    end
    as_constant(a, a."__class__".__name__ |> Symbol |> Val)
end


# cannot get treated as Julia objects
function as_constant(a::PyObject, ::Val)
    a
end

function as_constant(a::PyObject, ::Union{Val{:int}, Val{:str}, Val{:complex}, Val{:float}, Val{:NoneType}})
    PyAny(n)
end

function as_constant(a::PyObject, ::Union{Val{:bytes}})
    error("Not implemented yet")
end


function as_constant(a::PyObject, ::Val{:list})
    map(as_constant, a)
end

function as_constant(a::PyObject, ::Val{:tuple})
    Tuple(map(as_constant, a))
end

function as_constant(a::PyObject, ::Val{:dict})
    mk_pair(kv) = begin
        k, v = Tuple(kv)
        k = as_constant(k)
        v = as_constant(v)
        k => v
    end
    Dict(map(mk_pair, pycall(a."items", PyObject)))
end

function as_constant(a::PyObject, ::Val{:set})
    Set(map(as_constant, a))
end
