export Py_TYPE, Py_INCREF, Py_TYPENAME
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
        t = unsafe_load(@pacc (o.ob_type :: Ptr{PyTypeObject}))
        @static if DEBUG
            tname = Py_TYPENAME(o)
            println("deallocating a $(tname)...")
        end
        dealloc_func_ptr = @pacc t.tp_dealloc :: Ptr{Nothing}
        dealloc_func_ptr = unsafe_load(dealloc_func_ptr)
        ccall(dealloc_func_ptr, Cvoid, (PyPtr, ), o)
        @static if DEBUG
            println("deallocated!")
        end
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

function Py_TYPENAME(o::PyPtr)
    p = @pacc o.ob_type :: PyPtr
    p = reinterpret(Ptr{PyTypeObject}, unsafe_load(p))
    p = @pacc p.tp_name :: Ptr{UInt8}
    unsafe_string(unsafe_load(p))
end

function Py_NAME_OF_TYPE(p::Ptr{PyTypeObject})
    p = @pacc p.tp_name :: Ptr{UInt8}
    unsafe_string(unsafe_load(p))
end

function Py_NAME_OF_TYPE(p::PyPtr)
    Py_NAME_OF_TYPE(reinterpret(Ptr{PyTypeObject}, p))
end



function Py_REFCNT(o::PyPtr)
    unsafe_load(@pacc o.ob_refcnt :: Py_ssize_t)
end
