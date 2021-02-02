import Base: sigatomic_begin, sigatomic_end
const PY_VECTORCALL_ARGUMENTS_OFFSET = Csize_t(1) << Csize_t(8 * sizeof(Csize_t) - 1)
@PyDLL_API Py_CallFunction begin
    PyObject_VectorcallDict = PySym(:PyObject_VectorcallDict)
    PyExc_TypeError = PySym(PyPtr, :PyExc_TypeError)
    
end

function Py_CallFunction(apis, f::PyPtr, args::Vararg{PyPtr, N}) where N
    buf = reinterpret(Ptr{PyPtr}, Base.Libc.malloc(N * sizeof(PyPtr)))
    for i=1:N
        unsafe_store!(buf, args[i], i)
    end
    sigatomic_begin()
    r = @ccall $(apis.PyObject_VectorcallDict)(
        f::PyPtr,
        buf::Ptr{PyPtr},
        (N | PY_VECTORCALL_ARGUMENTS_OFFSET) :: Csize_t,
        Py_NULL :: PyPtr
    )::PyPtr
    sigatomic_end()
    r
end

