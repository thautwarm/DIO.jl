export Py_TYPE, Py_TYPENAME
export Py_INCREF, Py_DECREF
export Py_XDECREF, Py_XINCREF

function Py_INCREF(o::PyPtr)
    p = @pointer_access o.ob_refcnt
    i = unsafe_load(p) :: Py_ssize_t
    unsafe_store!(p, i + 1)
    nothing
end

@inline function Py_XINCREF(o::PyPtr)
    if o !== Py_NULL
        Py_INCREF(o)
    end
end

function Py_DECREF(o::PyPtr, os::PyPtr...)
    Py_DECREF(o)
    Py_DECREF(os...)
end

function Py_DECREF(o::PyPtr)
    p = @pointer_access o.ob_refcnt
    i = unsafe_load(p) :: Py_ssize_t
    if i == 1
        unsafe_store!(p, 0)
        t = unsafe_load(@pointer_access (o.ob_type :: Ptr{PyTypeObject}))
        @static if DEBUG
            tname = Py_TYPENAME(o)
            println("deallocating a $(tname)...")
        end
        dealloc_func_ptr = @pointer_access t.tp_dealloc
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

@inline function Py_XDECREF(o::PyPtr)
    if o !== Py_NULL
        Py_DECREF(o)
    end
end

function Py_TYPE(o::PyPtr)::PyPtr
    p = @pointer_access o.ob_type
    unsafe_load(p)
end

function Py_TYPENAME(o::PyPtr)::String
    p = @pointer_access o.ob_type :: Ptr{PyTypeObject}
    p = unsafe_load(p)
    p = @pointer_access p.tp_name
    unsafe_string(unsafe_load(p))
end

function Py_NAME_OF_TYPE(p::Ptr{PyTypeObject})::String
    p = @pointer_access p.tp_name
    unsafe_string(unsafe_load(p))
end

function Py_NAME_OF_TYPE(p::PyPtr)::String
    Py_NAME_OF_TYPE(reinterpret(Ptr{PyTypeObject}, p))
end

function Py_REFCNT(o::PyPtr)::Py_ssize_t
    unsafe_load(@pointer_access o.ob_refcnt)
end
