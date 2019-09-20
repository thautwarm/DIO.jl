function py_mk_tuple
end

py_mk_func(::String, f::T) where T <: Function = f

function py_mk_closure
end


@generated function py_add(a, b)
    val = Val((a <: PyObject) || (b <: PyObject))
    :(py_add(a, b, $val))
end


@generated function py_add(a, b, is_py::Val{true})
    f = pyimport("operator").add
    :(pycall($f, PyObject, a, b))
end

function py_add(a, b, is_py::Val{false})
    a + b
end

@generated function py_not(a)
    val = Val(a <: PyObject)
    :(py_not(a, $val))
end

function py_not(a, is_py::Val{true})
    PyCall.sigatomic_begin()
    try
        err = ccall(@pysym(:PyObject_IsTrue), Cint, (PyPtr,), a)
        if err === 0
            @pysym(:Py_True)
        else
            @pysym(:Py_False)
        end
    finally
        PyCall.sigatomic_end()
    end
end


function py_not(a, is_py::Val{false})
    !a
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
    next::PyObject
end

@generated function (iter::PyIterHelper)()
    stop_exc = PyCall.@pyglobalobjptr :PyExc_StopIteration
    ok = Cint(1)
    quote
        PyCall.sigatomic_begin()
        try
            v = ccall((@pysym :PyObject_CallObject), PyPtr, (PyPtr, PyPtr), getfield(iter.next, :o), PyPtr_NULL)
            exc = ccall((@pysym :PyErr_Occurred), PyPtr, ())
            exc != C_NULL &&
                begin
                    if ccall((@pysym :PyErr_ExceptionMatches), Cint, (PyPtr, ), $stop_exc) === $ok
                        pyerr_clear()
                        return nothing
                    else
                        msg = "Python has thrown unexpected exception when iterating."
                        pyerr = PyCall.PyError(msg)
                        error("$msg\n$pyerr")
                    end
                end
            (PyObject(v), iter)
        finally
        end
    end
end

struct NextHelper{Iter}
    i::Iter
end


(a::NextHelper)() = a

function py_get_attr(p::PyObject, ::Val{:__next__}) where T
    PyIterHelper(p."__next__")
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
    :($py_is($py_none, p))
end

function py_is_none(p)
    p === nothing
end


struct JlSlice{A, B, C}
    start::A
    end_::B
    sep::C
end

function py_subscr(subj::PyObject, item)
    get(subj, PyObject, item)
end

function py_subscr(subj::Vector{T}, item::Integer) where T
    subj[item + 1]
end

function py_subscr(subj::Tuple, item::Integer) where T
    subj[item + 1]
end

function py_subscr(subj::Union{Tuple, Vector}, item::JlSlice{Nothing, A, B}) where {A, B}
    py_subscr(subj, JlSlice(1, item.end_, item.sep))
end

function py_subscr(subj::Union{Tuple, Vector}, item::JlSlice{A, B, Nothing}) where {A, B}
    py_subscr(subj, JlSlice(item.start, item.end_, 1))
end

function py_subscr(subj::Union{Tuple, Vector}, item::JlSlice{A, Nothing, B}) where {A, B}
    py_subscr(subj, JlSlice(item.start, length(subj), item.sep))
end

# TODO: optimizing slice using UnitRange
function py_subscr(subj::Union{Tuple, Vector}, item::JlSlice{I, I, I}) where I <: Integer
    subj[item.start:item.sep:item.end_]
end

@generated function py_load_global(py_mod::PyObject, sym::Val{Name}) where Name
    py_none = pybuiltin("None")
    s = String(Name)
    builtin = nothing
    try
        builtin = pybuiltin(s)
    catch e
        !(e isa KeyError) && rethrow()
    end
    if builtin === nothing
        quote
            get(py_mod, PyObject, $s)
        end
    else
        quote
            v = get(py_mod, PyObject, $s, $py_none)
            py_is(v, $py_none) && return $builtin
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

# TODO: to support creating python slices
@generated function py_build_slice(a, b)
    :(JlSlice(a, b, nothing))
end

@generated function py_build_slice(a, b, c)
    :(JlSlice(a, b, c))
end

# TODO: for python objects
function py_setitem(subj::Vector{T}, key::Integer, value::G) where {T, G <: T}
    subj[key + 1] = value
end

function py_call_method(self::PyObject, f::F, args...) where F
    pycall(f, PyObject, self, args...)
end

function py_call_method(self, f::F, args...) where F
    f(self, args...)
end

function py_mk_list()
    []
end

function py_mk_list(xs...)
    collect(xs)
end

function py_mk_tuple(xs...)
    xs
end
