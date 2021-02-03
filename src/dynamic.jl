import Base: sigatomic_begin, sigatomic_end

const PY_VECTORCALL_ARGUMENTS_OFFSET = Csize_t(1) << Csize_t(8 * sizeof(Csize_t) - 1)

@PyAPISetup begin
    PyObject_VectorcallDict = PySym(:PyObject_VectorcallDict)
    PyExc_TypeError = PySym(PyPtr, :PyExc_TypeError)
end
@RequiredPyAPI Py_CallFunction
@generated function Py_CallFunction(apis, f::PyPtr, args::Vararg{PyPtr, N}) where N
    # this is chosen for fitting LLVM optimisations about stack allocation
    STACK_LENGTH =
        @match N begin
            0 => 0
            1 => 1
            2 => 2
            _ => 4 * ceil(Int, N / 4)
        end
    set_args = [:(unsafe_store!(smallstack, args[$i], $i)) for i=1:N]
    # precompute argsf
    argsf = N | PY_VECTORCALL_ARGUMENTS_OFFSET
    @q begin
        static_array = $Addr[$(zeros(Addr, STACK_LENGTH)...)]
        smallstack = reinterpret(Ptr{PyPtr}, pointer(static_array))
        $(set_args...)
        sigatomic_begin()
        GC.@preserve static_array begin
            r = ccall(
                apis.PyObject_VectorcallDict,
                PyPtr,
                (PyPtr, Ptr{PyPtr}, Csize_t, PyPtr),
                f,      smallstack, $argsf , Py_NULL)
        end
        sigatomic_end()
        r
    end
end
DIO_ExceptCode(::typeof(Py_CallFunction)) = Py_NULL

@PyAPISetup begin
    Py_IntAsNumberPtr =unsafe_load(reinterpret(Ptr{PyTypeObject}, PyO.int)).tp_as_number
    Py_IntPowIntPtr = unsafe_load(Py_IntAsNumberPtr).nb_power
    Py_IntAddIntPtr = unsafe_load(Py_IntAsNumberPtr).nb_add
    PyLong_AsDouble = PySym(:PyLong_AsDouble)
    PyFloat_FromDouble = PySym(:PyFloat_FromDouble)
    PyList_Append = PySym(:PyList_Append)
end
@RequiredPyAPI Py_IntPowInt
function Py_IntPowInt(apis, l :: PyPtr, r :: PyPtr)
    apis.Py_IntPowIntPtr(l, r, apis.PyO.None)
end
DIO_ExceptCode(::typeof(Py_IntPowInt)) = Py_NULL

@RequiredPyAPI Py_IntAddInt
function Py_IntAddInt(apis, l :: PyPtr, r :: PyPtr)
    apis.Py_IntAddIntPtr(l, r)
end
DIO_ExceptCode(::typeof(Py_IntAddInt)) = Py_NULL

@RequiredPyAPI Py_CallBoolIfNecessary
function Py_CallBoolIfNecessary(apis, o::PyPtr)
    if Py_TYPE(o) === apis.PyO.bool
        return o
    else
        return Py_CallFunction(apis, apis.PyO.bool, o)
    end
end
DIO_ExceptCode(::typeof(Py_CallBoolIfNecessary)) = Py_NULL

@RequiredPyAPI Py_IntSqrt
function Py_IntSqrt(apis, o::PyPtr)
    d =  ccall(apis.PyLong_AsDouble, Cdouble, (PyPtr, ),  o)
    ccall(apis.PyFloat_FromDouble, PyPtr, (Cdouble, ), sqrt(d))
end
DIO_ExceptCode(::typeof(Py_IntSqrt)) = Py_NULL

@RequiredPyAPI PyList_Append
function PyList_Append(apis, lst::Ptr, elt::PyPtr)
    ccall(apis.PyList_Append, Cint, (PyPtr, PyPtr), lst, elt) === Cint(-1)
end
DIO_ExceptCode(::typeof(PyList_Append)) = Cint(-1)
