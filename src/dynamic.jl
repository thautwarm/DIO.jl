import Base: sigatomic_begin, sigatomic_end

const PY_VECTORCALL_ARGUMENTS_OFFSET = Csize_t(1) << Csize_t(8 * sizeof(Csize_t) - 1)

@PyAPISetup begin
    PyObject_VectorcallDict = PySym(:PyObject_VectorcallDict)
    PyExc_TypeError = PySym(PyPtr, :PyExc_TypeError)
end
@RequiredPyAPI Py_CallFunction
@generated function Py_CallFunction(apis, f::PyPtr, args::Vararg{PyPtr, N}) where N
    # this is chosen for fitting LLVM optimisations
    STACK_LENGTH = 4 * ceil(Int, N / 4)
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
    Py_IntAsNumberPtr = unsafe_load(reinterpret(Ptr{PyTypeObject}, PyO.int)).tp_as_number
    Py_IntAddIntFnPtr = unsafe_load(Py_IntAsNumberPtr).nb_add
end
