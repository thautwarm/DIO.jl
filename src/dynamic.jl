import Base: sigatomic_begin, sigatomic_end

const PY_VECTORCALL_ARGUMENTS_OFFSET = Csize_t(1) << Csize_t(8 * sizeof(Csize_t) - 1)

@exportapi Py_CallMethod
@generated function Py_CallMethod(apis::S, self::PyPtr, name::PyPtr, args::Vararg{PyPtr, N}) where {S, N}
    argtypes = Expr(:tuple, [:PyPtr for i=1:N+3]...)
    # N + 3 = object . name (arg1 ... argN) NULL
    argvals = [:(args[$i]) for i=1:N]
    @q begin
        ccall(
            apis.PyObject_CallMethodObjArgs,
            PyPtr,
            $argtypes,
            self, name, $(argvals...), Py_NULL)
    end
end
DIO_ExceptCode(::typeof(Py_CallMethod)) = Py_NULL

@exportapi Py_CallFunction
@generated function Py_CallFunction(apis::S, f::PyPtr, args::Vararg{PyPtr, N}) where {S, N}
    argtypes = Expr(:tuple, [:PyPtr for i=1:N+2]...)
    argvals = [:(args[$i]) for i=1:N]
    @q begin
        ccall(
            # PyObject_CallFunctionObjArgs
            apis.PyObject_CallFunctionObjArgs,
            PyPtr,
            $argtypes,
            f, $(argvals...), Py_NULL)
    end
end
DIO_ExceptCode(::typeof(Py_CallFunction)) = Py_NULL

@exportapi _PyBytes_Join
@autoapi _PyBytes_Join(PyPtr, PyPtr)::PyPtr != Py_NULL

@exportapi PySequence_GetItem
@autoapi PySequence_GetItem(PyPtr, Py_ssize_t)::PyPtr mangle(_PySequence_GetItem) borrow2new
function PySequence_GetItem(apis, seq::PyPtr, item::PyPtr)::PyPtr
    i = _PyLong_AsSsize_t(apis, item)
    if i == -1 && PyErr_Occurred(apis) != Py_NULL
        return Py_NULL
    end
    _PySequence_GetItem(apis, seq, i)
end
DIO_ExceptCode(::typeof(PySequence_GetItem)) = Py_NULL

@exportapi PySequence_Length
@autoapi PySequence_Length(PyPtr)::Py_ssize_t mangle(_PySequence_Length)
@autoapi PyLong_FromSsize_t(Py_ssize_t)::PyPtr
function PySequence_Length(apis, o::PyPtr)::PyPtr
    size = _PySequence_Length(apis, o)
    if size == -1
        Py_NULL
    else
        PyLong_FromSsize_t(apis, size)
    end
end
DIO_ExceptCode(::typeof(PySequence_Length)) = Py_NULL

@exportapi Py_AddressCompare
function Py_AddressCompare(apis, l::PyPtr, r::PyPtr)::PyPtr
    o = l === r ? apis.PyO.True : apis.PyO.False
    Py_INCREF(o)
    o
end
DIO_ExceptCode(::typeof(Py_AddressCompare)) = nothing

@exportapi PyList_Construct
@autoapi PyList_SetItem(PyPtr, Py_ssize_t, PyPtr)::Cint mangle(_PyList_SetItem)
@autoapi PyList_New(Py_ssize_t)::PyPtr mangle(_PyList_New)
function PyList_Construct(apis, args::Vararg{PyPtr,N}) where N
    lst = _PyList_New(apis, N)
    if lst === Py_NULL
        return lst
    end
    for i = 1:N
        o = args[i]
        Py_INCREF(o)
        # inbounds, no need to check the errocode
        _PyList_SetItem(apis, lst, Py_ssize_t(i - 1), o) 
    end
    return lst
end
DIO_ExceptCode(::typeof(PyList_Construct)) = Py_NULL

@exportapi PyObject_RichCompare
@autoapi PyObject_RichCompare(PyPtr, PyPtr, Cint)::PyPtr != Py_NULL
@exportapi PyInt_Compare
@autoapi PyInt_Compare(PyPtr, PyPtr, Cint)::PyPtr != Py_NULL

@exportapi PyList_GetItem
@autoapi PyLong_AsSsize_t(PyPtr)::Py_ssize_t mangle(_PyLong_AsSsize_t)
@autoapi PyList_GetItem(PyPtr, Py_ssize_t)::PyPtr borrow2new mangle(_PyList_GetItem)
function PyList_GetItem(apis, o_subject::PyPtr, o_item::PyPtr)
    i = _PyLong_AsSsize_t(apis, o_item)
    if i == -1 && PyErr_Occurred(apis) != Py_NULL
        return Py_NULL
    end
    _PyList_GetItem(apis, o_subject, i)
end
DIO_ExceptCode(::typeof(PyList_GetItem)) = Py_NULL

@exportapi PyObject_SetItem
@autoapi PyObject_SetItem(PyPtr, PyPtr, PyPtr)::Cint != Cint(-1)
@exportapi PyFunction_GetGlobals
@autoapi PyFunction_GetGlobals(PyPtr)::PyPtr != Py_NULL
@exportapi Py_IntAddInt
@autoapi Py_IntAddInt(PyPtr, PyPtr)::PyPtr != Py_NULL
@exportapi PyList_Append
@autoapi PyList_Append(PyPtr, PyPtr)::Cint != Cint(-1)
@exportapi _PyDict_GetItem_KnownHash
@autoapi _PyDict_GetItem_KnownHash(PyPtr, PyPtr, Py_hash_t)::PyPtr != Py_NULL
@exportapi PyDict_GetItemWithError
@autoapi PyDict_GetItemWithError(PyPtr, PyPtr)::PyPtr != Py_NULL
@exportapi PyObject_GetItem
@autoapi PyObject_GetItem(PyPtr, PyPtr)::PyPtr != Py_NULL
@autoapi PyErr_Print()::Cvoid
@autoapi PyErr_Clear()::Cvoid
@autoapi PyModule_GetDict(PyPtr)::PyPtr != Py_NULL
@autoapi PyErr_ExceptionMatches(PyPtr)::Cint
@autoapi PyErr_Occurred()::PyPtr

@exportapi Py_IntPowInt
@autoapi Py_IntPow(PyPtr, PyPtr, PyPtr)::PyPtr
function Py_IntPowInt(apis, a::PyPtr, b::PyPtr)
    Py_IntPow(apis, a, b, apis.PyO.None)
end
DIO_ExceptCode(::typeof(Py_IntPowInt)) = Py_NULL

@exportapi Py_IntSqrt
function Py_IntSqrt(apis, o::PyPtr)
    d =  ccall(apis.PyLong_AsDouble, Cdouble, (PyPtr, ),  o)
    ccall(apis.PyFloat_FromDouble, PyPtr, (Cdouble, ), sqrt(d))
end
DIO_ExceptCode(::typeof(Py_IntSqrt)) = Py_NULL

@exportapi Py_CallBoolIfNecessary
function Py_CallBoolIfNecessary(apis, o::PyPtr)
    if Py_TYPE(o) === apis.PyO.bool
        Py_INCREF(o)
        return o
    else
        Py_CallFunction(apis, apis.PyO.bool, o)
    end
end
DIO_ExceptCode(::typeof(Py_CallBoolIfNecessary)) = Py_NULL

@exportapi PyDict_LoadGlobal
function PyDict_LoadGlobal(apis, func::PyPtr, builtins::PyPtr, key::PyPtr)
    globals = @callexc(PyFunction_GetGlobals, apis, func)
    Py_INCREF(globals)
    o = PyDict_GetItemWithError(apis, globals, key)
    Py_DECREF(globals)
    if o !== Py_NULL
        Py_INCREF(o)
        return o
    end
    if PyErr_Occurred(apis) != Py_NULL
        return Py_NULL
    end
    builtins_dict = @callexc(PyModule_GetDict, apis, builtins)
    Py_INCREF(builtins_dict)
    o = PyDict_GetItemWithError(apis, builtins_dict, key)
    Py_DECREF(builtins_dict)
    if o === Py_NULL
        return Py_NULL
    end
    Py_INCREF(o)
    return o
end
DIO_ExceptCode(::typeof(PyDict_LoadGlobal)) = Py_NULL


@exportapi PyDict_LoadGlobal_KnownHash
function PyDict_LoadGlobal_KnownHash(apis, func::PyPtr, builtins::PyPtr, key::PyPtr, hash::Py_hash_t)    
    globals = @callexc(PyFunction_GetGlobals, apis, func)
    Py_INCREF(globals)
    o = _PyDict_GetItem_KnownHash(apis, globals, key, hash)
    Py_DECREF(globals)
    if o !== Py_NULL
        Py_INCREF(o)
        return o
    end
    if PyErr_Occurred(apis) != Py_NULL
        return Py_NULL
    end
    builtins_dict = @callexc(PyModule_GetDict, apis, builtins)
    Py_INCREF(builtins_dict)
    o = _PyDict_GetItem_KnownHash(apis, builtins_dict, key, hash)
    Py_DECREF(builtins_dict)
    if o === Py_NULL
        return Py_NULL
    end
    Py_INCREF(o)
    return o
end
DIO_ExceptCode(::typeof(PyDict_LoadGlobal_KnownHash)) = Py_NULL
