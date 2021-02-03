export PyPtr, PyObject, Py_NULL, METH_O, METH_NOARGS, METH_FASTCALL
export Py_ssize_t, Addr
export PyMethodDef

const Py_ssize_t = Cssize_t
const Addr = UInt64

struct PyObject
    ob_refcnt::Py_ssize_t
    ob_type::Ptr{PyObject}
end

const PyPtr = Ptr{PyObject}
const Py_NULL = reinterpret(PyPtr, C_NULL)

const METH_VARARGS = 0x0001
const METH_KEYWORDS = 0x0002
const METH_NOARGS = 0x0004
const METH_O = 0x0008
const METH_FASTCALL = 0x0080

mutable struct PyMethodDef
    ml_name::Cstring
    ml_meth::Ptr{Nothing}
    ml_flags::Cint
    ml_doc::Cstring # may be NULL
end

struct PyGetSetDef
    name::Ptr{UInt8}
    get::Ptr{Cvoid}
    set::Ptr{Cvoid} # may be NULL for read-only members
    doc::Ptr{UInt8} # may be NULL
    closure::Ptr{Cvoid} # pass-through thunk, may be NULL
end

# (o, o) -> p
struct binaryfunc
    unbox::Ptr{Nothing}
end
function (f::binaryfunc)(o1::PyPtr, o2::PyPtr)
    ccall(f.unbox, PyPtr, (PyPtr, PyPtr), o1, o2)
end
DIO_ExceptCode(::binaryfunc) = Py_NULL

# (o) -> p
struct unaryfunc
    unbox::Ptr{Nothing}
end
function (f::unaryfunc)(o)
    ccall(f.unbox, PyPtr, (PyPtr,), o)
end
DIO_ExceptCode(::unaryfunc) = Py_NULL

# (o, o, o) -> p
struct ternaryfunc
    unbox::Ptr{Nothing}
end
function (f::ternaryfunc)(o1::PyPtr, o2::PyPtr, o3::PyPtr)
    ccall(f.unbox, PyPtr, (PyPtr, PyPtr, PyPtr), o1, o2, o3)
end

struct PyNumberMethods
    nb_add::binaryfunc
    nb_subtract::binaryfunc
    nb_multiply::binaryfunc
    nb_remainder::binaryfunc
    nb_divmod::binaryfunc
    nb_power::ternaryfunc
    nb_negative::unaryfunc
    nb_positive::unaryfunc
    nb_absolute::unaryfunc
    nb_bool::Ptr{Nothing}
    nb_invert::unaryfunc
    nb_lshift::binaryfunc
    nb_rshift::binaryfunc
    nb_and::binaryfunc
    nb_xor::binaryfunc
    nb_or::binaryfunc
    nb_int::unaryfunc
    nb_reserved::Ptr{Nothing}
    nb_float::unaryfunc
    nb_inplace_add::binaryfunc
    nb_inplace_subtract::binaryfunc
    nb_inplace_multiply::binaryfunc
    nb_inplace_remainder::binaryfunc
    nb_inplace_power::ternaryfunc
    nb_inplace_lshift::binaryfunc
    nb_inplace_rshift::binaryfunc
    nb_inplace_and::binaryfunc
    nb_inplace_xor::binaryfunc
    nb_inplace_or::binaryfunc
    nb_floor_divide::binaryfunc
    nb_true_divide::binaryfunc
    nb_inplace_floor_divide::binaryfunc
    nb_inplace_true_divide::binaryfunc
    nb_index::unaryfunc
    nb_matrix_multiply::binaryfunc
    nb_inplace_matrix_multiply::binaryfunc
end

struct PyMemberDef
    name::Ptr{UInt8}
    typ::Cint
    offset::Int # warning: was Cint for Python <= 2.4
    flags::Cint
    doc::Ptr{UInt8}
end

mutable struct PyTypeObject
    # PyObject_HEAD (for non-Py_TRACE_REFS build):
    ob_refcnt::Int
    ob_type::PyPtr
    ob_size::Int # PyObject_VAR_HEAD

    # PyTypeObject fields:
    tp_name::Ptr{UInt8} # required, should be in format "<module>.<name>"

    # warning: these two were Cint for Python <= 2.4
    tp_basicsize::Int # required, = sizeof(instance)
    tp_itemsize::Int

    tp_dealloc::Ptr{Cvoid}
    tp_print::Ptr{Cvoid}
    tp_getattr::Ptr{Cvoid}
    tp_setattr::Ptr{Cvoid}
    tp_compare::Ptr{Cvoid}
    tp_repr::Ptr{Cvoid}

    tp_as_number::Ptr{PyNumberMethods}
    tp_as_sequence::Ptr{Cvoid}
    tp_as_mapping::Ptr{Cvoid}

    tp_hash::Ptr{Cvoid}
    tp_call::Ptr{Cvoid}
    tp_str::Ptr{Cvoid}
    tp_getattro::Ptr{Cvoid}
    tp_setattro::Ptr{Cvoid}

    tp_as_buffer::Ptr{Cvoid}

    tp_flags::Clong # Required, should default to Py_TPFLAGS_DEFAULT

    tp_doc::Ptr{UInt8} # normally set in example code, but may be NULL

    tp_traverse::Ptr{Cvoid}

    tp_clear::Ptr{Cvoid}

    tp_richcompare::Ptr{Cvoid}

    tp_weaklistoffset::Int

    # added in Python 2.2:
    tp_iter::Ptr{Cvoid}
    tp_iternext::Ptr{Cvoid}

    tp_methods::Ptr{PyMethodDef}
    tp_members::Ptr{PyMemberDef}
    tp_getset::Ptr{PyGetSetDef}
    tp_base::Ptr{Cvoid}

    tp_dict::PyPtr
    tp_descr_get::Ptr{Cvoid}
    tp_descr_set::Ptr{Cvoid}
    tp_dictoffset::Int

    tp_init::Ptr{Cvoid}
    tp_alloc::Ptr{Cvoid}
    tp_new::Ptr{Cvoid}
    tp_free::Ptr{Cvoid}
    tp_is_gc::Ptr{Cvoid}

    tp_bases::PyPtr
    tp_mro::PyPtr
    tp_cache::PyPtr
    tp_subclasses::PyPtr
    tp_weaklist::PyPtr
    tp_del::Ptr{Cvoid}

    # added in Python 2.6:
    tp_version_tag::Cuint

    # only used for COUNT_ALLOCS builds of Python
    tp_allocs::Int
    tp_frees::Int
    tp_maxalloc::Int
    tp_prev::Ptr{Cvoid}
    tp_next::Ptr{Cvoid}
end

