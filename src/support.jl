#=
# convention:
# a variable representing PyPtr can be
#             nothing => Py_None
#             DIO_Err => Py_NULL = PyPtr(0)
#             RC(a)   => PyPtr(a)
# unintialized variables are DIO_Err
=#
export DIO_ExceptCode, DIO_Undef
export @DIO_Obj, @DIO_SetLineno
export @DIO_MakePtrCFunc
export DIO_HasCast, DIO_Cast, DIO_CastExc

struct DIO_UndefType end
const DIO_Undef = DIO_UndefType()

const PyConstants = Set{Addr}()
function DIO_Obj(addr::Addr)::PyPtr
    o = reinterpret(PyPtr, addr)
    addr in PyConstants || begin
        push!(PyConstants, addr)
        Py_INCREF(o)
    end
    return o
end

macro DIO_Obj(addr::Addr)
    DIO_Obj(addr)
end

@exportapi PyCFunction_NewEx
@autoapi PyCFunction_NewEx(Ptr{Nothing}, PyPtr, PyPtr)::PyPtr

@exportapi PyCFunction_New
function PyCFunction_New(apis, cfuncptr::Ptr{Nothing}, UNUSED::PyPtr)
    @ccall $(apis.PyCFunction_NewEx)(cfuncptr::Ptr{Nothing}, UNUSED::PyPtr, Py_NULL::PyPtr)::PyPtr
end

macro DIO_SetLineno(line::Int, filename::String)
    LineNumberNode(line, Symbol(filename))
end

DIO_ExceptCode(f) = error("no error handling for $(f).")
DIO_HasCast(f) = false
# f -> bool
function DIO_CastExc end
# (f, val) -> PyPtr
function DIO_Cast end

macro DIO_MakePtrCFunc(narg::Int, jl_func::Symbol, funcname::Symbol)
    if narg == 0
        DIO_MakePtrCFunc0(jl_func, funcname, __module__)
    elseif narg == 1
        DIO_MakePtrCFunc1(jl_func, funcname, __module__)
    else
        DIO_MakePtrCFuncN(narg, jl_func, funcname, __module__)
    end
end

function DIO_MakePtrCFunc0(jl_func::Symbol, funcname::Symbol, __module__::Any)
    CFunc = Symbol(:CFunc_, jl_func)
    CFuncPtr = Symbol(:CFuncPtr_, jl_func)
    PyMeth = Symbol(:PyMeth_, jl_func)
    Doc = Symbol(:DOC_, jl_func)
    PyFunc = Symbol(:PyFunc_, jl_func)
    ex = @q begin
        @inline DIO.DIO_ExceptCode(::typeof($jl_func)) = Py_NULL
        function $CFunc(_ :: PyPtr, _::PyPtr)::PyPtr
            return $jl_func()
        end
        const $CFuncPtr = @cfunction($CFunc, PyPtr, (PyPtr, PyPtr))
        const $PyMeth = PyMethodDef(
            Base.unsafe_convert(Cstring, $(QuoteNode(funcname))),
            $CFuncPtr,
            METH_NOARGS,
            Base.unsafe_convert(Cstring, $Doc)
        )
        const $PyFunc = PyCFunction_NewEx(pointer_from_objref($PyMeth), Py_NULL, Py_NULL)
    end
    if DEBUG
        @info ex
    end
    foreach(__module__.eval, ex.args)
end

function DIO_MakePtrCFunc1(jl_func::Symbol, funcname::Symbol, __module__::Any)
    CFunc = Symbol(:CFunc_, jl_func)
    CFuncPtr = Symbol(:CFuncPtr_, jl_func)
    PyMeth = Symbol(:PyMeth_, jl_func)
    Doc = Symbol(:DOC_, jl_func)
    PyFunc = Symbol(:PyFunc_, jl_func)
    ex = @q begin
        @inline DIO.DIO_ExceptCode(::typeof($jl_func)) = Py_NULL
        function $CFunc(_ :: PyPtr, arg::PyPtr)::PyPtr
            return $jl_func(arg)
        end
        const $CFuncPtr = @cfunction($CFunc, PyPtr, (PyPtr, PyPtr))
        const $PyMeth = PyMethodDef(
            Base.unsafe_convert(Cstring, $(QuoteNode(funcname))),
            $CFuncPtr,
            METH_O,
            Base.unsafe_convert(Cstring, $Doc)
        )
        const $PyFunc = PyCFunction_NewEx(pointer_from_objref($PyMeth), Py_NULL, Py_NULL)
    end
    if DEBUG
        @info ex
    end
    foreach(__module__.eval, ex.args)
end        

function DIO_MakePtrCFuncN(narg::Int, jl_func::Symbol, funcname::Symbol, __module__::Any)
    CFunc = Symbol(:CFunc_, jl_func)
    CFuncPtr = Symbol(:CFuncPtr_, jl_func)
    PyMeth = Symbol(:PyMeth_, jl_func)
    Doc = Symbol(:DOC_, jl_func)
    PyFunc = Symbol(:PyFunc_, jl_func)
    
    error_string = "expect $(narg) arguments, while got "
    error_string = :("$($error_string)$(n).")

    vectorargs = gensym("vectorargs")
    call_jl_func = Expr(:call, jl_func)
    for i = 1:narg
        push!(call_jl_func.args, :(unsafe_load($vectorargs, $i)))
    end

    PyAPI_Struct = __module__.PyAPI_Struct
    ex = @q begin
        @inline DIO.DIO_ExceptCode(::typeof($jl_func)) = Py_NULL
        function $CFunc(self :: PyPtr, $vectorargs::Ptr{PyPtr}, argc::Py_ssize_t)::PyPtr
            if argc != $narg
                msg = $error_string
                cmsg = Base.unsafe_convert(Cstring, msg)
                GC.@preserve msg begin
                    ccall(
                        $(PyAPI_Struct.PyErr_SetString),
                        Cvoid,
                        (PyPtr, Cstring),
                        $(PyAPI_Struct.PyExc_TypeError), cmsg)
                end
                return Py_NULL
            end
            return $call_jl_func
        end
        const $CFuncPtr = @cfunction($CFunc, PyPtr, (PyPtr, Ptr{PyPtr}, Py_ssize_t))
        const $PyMeth = PyMethodDef(
            Base.unsafe_convert(Cstring, $(QuoteNode(funcname))),
            $CFuncPtr,
            METH_FASTCALL,
            Base.unsafe_convert(Cstring, $Doc)
        )
        const $PyFunc = PyCFunction_NewEx(pointer_from_objref($PyMeth), Py_NULL, Py_NULL)
    end
    if DEBUG
        @info ex
    end
    foreach(__module__.eval, ex.args)
end


@exportapi DIO_WrapIntValue
@inline DIO_WrapIntValue(apis, i::Union{Cint, Clong})::PyPtr = begin
    i = Clong(i)
    ccall(apis.PyLong_FromLong, PyPtr, (Clong, ), i)
end

@inline DIO_WrapIntValue(apis, i::Csize_t)::PyPtr = begin
    ccall(apis.PyLong_FromSize_t, PyPtr, (Csize_t, ), i)
end

@inline DIO_WrapIntValue(apis, i)::PyPtr = begin
    msg = "Cannot wrap $i :: $(typeof(i))!"
    cmsg = Base.unsafe_convert(Cstring, msg)
    GC.@preserve msg begin
        ccall(
            apis.PyErr_SetString,
            Cvoid,
            (PyPtr, Cstring),
            apis.PyExc_TypeError, cmsg)
    end
    Py_NULL
end

@exportapi DIO_NewNone
@inline DIO_NewNone(apis) = begin
    none = apis.PyO.None
    Py_INCREF(none)
    none
end