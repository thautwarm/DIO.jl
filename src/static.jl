export Py_TYPE, Py_INCREF
function Py_INCREF(o::Ptr{PyObject})
    p = @pacc o.ob_refcnt :: Py_ssize_t
    i = unsafe_load(p)
    unsafe_store!(p, i + 1)
    nothing
end

function Py_XINCREF(o::Ptr{PyObject})
    if o !== Py_NULL
        Py_INCREF(o)
    end
end

function Py_DECREF(o::PyPtr)
    p = @pacc o.ob_refcnt :: Py_ssize_t
    i = unsafe_load(p)
    if i == 1
        unsafe_store!(p, 0)
        dealloc_func_ptr = @pacc (o.ob_type :: PyTypeObject).tp_dealloc :: Ptr{Nothing}
        ccall(unsafe_load(dealloc_func_ptr), Cvoid, (PyPtr, ), o)
    else
        unsafe_store!(p, i - 1)
    end
    nothing
end

function Py_XDECREF(o::Ptr{PyObject})
    if o !== Py_NULL
        Py_DECREF(o)
    end
end

function Py_TYPE(o::PyPtr)
    p = @pacc o.ob_type :: PyPtr
    unsafe_load(p)
end
