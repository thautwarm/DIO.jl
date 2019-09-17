function py_mk_tuple
end

function py_mk_func
end

function py_mk_closure
end

function py_add(a::Int, b::Int)
    a + b
end

@generated function py_add(a::PyObject, b::Int)
    f = pyimport("operator").add
    :(pycall(f, PyObject, a, b))
end


@generated function py_add(a::Int, b::PyObject)
    f = pyimport("operator").add
    :(pycall(f, PyObject, a, b))
end

@generated function py_get_attr(p::PyObject, ::Val{Attr}) where Attr
    attr = String(Attr)
    :(p.$attr)
end

struct IterHelper{I, V}
    i::I
    v::V
end

function (iter::IterHelper{I, V})() where {I, V}
    v = iterate(iter.v, iter.i)
    v === nothing && return nothing
    elt, i2 = v
    (elt, IterHelper{I, V}(i2, iter.v))
end


struct PyIterHelper
    next::PyPtr
end

@generated function (iter::PyIterHelper)()
    stop_exc = PyCall.@pyglobalobjptr :PyExc_StopIteration
    ok = Cint(1)
    quote
        v = ccall((@pysym :PyObject_CallObject), PyPtr, (PyPtr, PyPtr), iter.next, PyPtr_NULL)
        exc = ccall((@pysym :PyErr_Occurred), PyPtr, ())
        exc != C_NULL &&
            if ccall((@pysym :PyErr_ExceptionMatches), Cint, (PyPtr, ), $stop_exc) === $ok
                pyerr_clear()
                return nothing
            else
                error("Python has thrown unexpected exception when iterating.")
            end
        (PyObject(v), iter)
    end
end

struct NextHelper{Iter}
    i::Iter
end


(a::NextHelper)() = a

function py_get_attr(p::PyObject, ::Val{:__next__}) where T
    PyIterHelper(getfield(p."__next__", :o))
end

function py_get_attr(p::Vector{T}, ::Val{:__iter__}) where T
    NextHelper(IterHelper{Int, Vector{T}}(1, p))
end

function py_get_attr(p::Tp, ::Val{:__iter__}) where Tp <: Tuple
    NextHelper(IterHelper{Int, Tp}(1, p))
end

function py_get_attr(p::Set{T}, ::Val{:__iter__}) where T
    NextHelper(IterHelper{Int, Set{T}}(1, p))
end

function py_get_attr(p::Range, ::Val{:__iter__}) where Range <: AbstractUnitRange
    NextHelper(IterHelper{Int, Range}(1, p))
end

py_get_attr(p::NextHelper{Iter}, ::Val{:__next__}) where Iter = p.i

@generated function py_is_none(p::PyObject)
    py_none = pybuiltin("None")
    :($py_none == p)
end

function py_is_none(p)
    p === nothing
end

function py_subscr(subj::PyObject, item)
    get(subj, PyObject, item)
end

function py_subscr(subj::Vector{T}, item) where T
    subj[item + 1]
end

function py_subscr(subj::Tuple, item) where T
    subj[item + 1]
end

@generated function py_load_global(py_mod::PyPtr, sym::Val{Name}) where Name
    py_none = pybuiltin("None")
    s = String(Name)
    builtin = nothing
    try
        builtin = pybuiltin(s)
    catch e
        !(e isa KeyError) && rethrow()
    end
    py_str = PyObject(s)
    if builtin === nothing
        quote
            py_mod = PyObject(py_mod)
            get(py_mod, PyObject, $py_str)
        end
    else
        quote
            py_mod = PyObject(py_mod)
            v = get(py_mod, PyObject, $py_str, $py_none)
            v === $py_none && return $builtin
            v
        end
    end
end

function py_call_func(f::PyObject, args...)
    pycall(f, PyObject, args...)
end

function py_call_func(f, args...)
    f(args...)
end