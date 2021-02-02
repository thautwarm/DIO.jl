quote
function J_hypot_0(x0, x1)
    x2 = DIO_Undef
    x3 = DIO_Undef
    x4 = DIO_Undef
    @label _1
    @goto _2
    @label _2
    @goto _3
    @label _3
    DIO_DecRef(x2)
    x2 = @DIO_ChkExcAndDecRefSubCall(Py_IntPowInt(x0, @DIO_Obj(0x0000028444ab6950)))
    DIO_DecRef(x3)
    x3 = @DIO_ChkExcAndDecRefSubCall(Py_IntPowInt(x1, @DIO_Obj(0x0000028444ab6950)))
    DIO_DecRef(x2)
    x2 = @DIO_ChkExcAndDecRefSubCall(Py_IntAddInt(x2, x3))
    DIO_DecRef(x4)
    x4 = @DIO_ChkExcAndDecRefSubCall(Py_CallFunction(@DIO_Obj(0x000002844577e810), x2))
    @DIO_Return DIO_IncRef(x4)

    @label err_handle
    DIO_Return = Py_NULL
    @label return
    DIO_DecRef(x2)
    DIO_DecRef(x3)
    DIO_DecRef(x4)
    return DIO_Return
end
DIO_ExceptCode(::typeof(J_hypot_0)) = Py_NULL
const DOC_J_hypot_0 = Base.unsafe_convert(Cstring, "Top J_hypot_0( D0 : int, D1 : int ) {\nlabel _1:\n  goto _2\nlabel _2:\n  goto _3\nlabel _3:\n  D2 : int = Py_IntPowInt(D0 : int, 2)\n  D3 : int = Py_IntPowInt(D1 : int, 2)\n  D2 : int = Py_IntAddInt(D2 : int, D3 : int)\n  D4 = Py_CallFunction(math.sqrt, D2 : int)\n  return D4\n}\n")
CFunc_J_hypot_0(self :: PyPtr, args::Ptr{PyPtr}, n::Py_ssize_t) = @DIO_MakePyFastCFunc(J_hypot_0, args, n, 2)
const CFuncPtr_J_hypot_0 = @cfunction(CFunc_J_hypot_0, PyPtr, (PyPtr, Ptr{PyPtr}, Py_ssize_t))
const PyMeth_J_hypot_0 = PyMethodDef(
    Base.unsafe_convert(Cstring, :hypot),
    CFuncPtr_J_hypot_0,
    METH_FASTCALL,
    DOC_J_hypot_0
)
const PyFunc_J_hypot_0 = PyCFunction_New(PyMeth_J_hypot_0, Py_NULL)
end