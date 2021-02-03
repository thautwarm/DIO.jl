function J_hypot_0(x0, x1)
    x2 = DIO_Undef
    x3 = DIO_Undef
    x4 = DIO_Undef

@label _1
    DIO_DecRef(x2)
    x2 = @DIO_ChkExcAndDecRefSubCall(Py_CallFunction(@DIO_Obj(0x0000011dff4f3360) #= <built-in function isinstance> =#, x0, @DIO_Obj(0x00007ffd6a132140) #= <class 'str'> =#))
    DIO_DecRef(x3)
    x3 = @DIO_ChkExcAndDecRefSubCall(Py_CallFunction(@DIO_Obj(0x00007ffd6a1239d0) #= <class 'bool'> =#, x2))
    if 0x00007ffd6a123868 === reinterpret(UInt64, x3)
        @goto _2
    else
        @goto _7
    end

@label _10
    DIO_DecRef(x2)
    x2 = @DIO_ChkExcAndDecRefSubCall(Py_CallFunction(@DIO_Obj(0x0000011dffc01770) #= <built-in function pow> =#, x0, @DIO_Obj(0x0000011dff4a6950) #= 2 =#))
    DIO_DecRef(x3)
    x3 = @DIO_ChkExcAndDecRefSubCall(Py_CallFunction(@DIO_Obj(0x0000011dffc01770) #= <built-in function pow> =#, x1, @DIO_Obj(0x0000011dff4a6950) #= 2 =#))
    DIO_DecRef(x2)
    x2 = @DIO_ChkExcAndDecRefSubCall(Py_CallFunction(@DIO_Obj(0x0000011dffbf7c20) #= <built-in function add> =#, x2, x3))
    DIO_DecRef(x4)
    x4 = @DIO_ChkExcAndDecRefSubCall(Py_CallFunction(@DIO_Obj(0x0000011d81cdb310) #= <built-in function sqrt> =#, x2))
    @DIO_Return DIO_IncRef(x4)

@label _2
    DIO_DecRef(x2)
    x2 = @DIO_ChkExcAndDecRefSubCall(Py_CallFunction(@DIO_Obj(0x00007ffd6a12efd0) #= <class 'int'> =#, x0))
    @goto _3

@label _3
    DIO_DecRef(x0)
    x0 = @DIO_ChkExcAndDecRefSubCall(Py_CallFunction(@DIO_Obj(0x0000011dff4f3360) #= <built-in function isinstance> =#, x1, @DIO_Obj(0x00007ffd6a132140) #= <class 'str'> =#))
    DIO_DecRef(x3)
    x3 = @DIO_ChkExcAndDecRefSubCall(Py_CallFunction(@DIO_Obj(0x00007ffd6a1239d0) #= <class 'bool'> =#, x0))
    if 0x00007ffd6a123868 === reinterpret(UInt64, x3)
        @goto _4
    else
        @goto _6
    end

@label _4
    DIO_DecRef(x0)
    x0 = @DIO_ChkExcAndDecRefSubCall(Py_CallFunction(@DIO_Obj(0x00007ffd6a12efd0) #= <class 'int'> =#, x1))
    @goto _5

@label _5
    DIO_DecRef(x1)
    x1 = @DIO_ChkExcAndDecRefSubCall(Py_CallFunction(@DIO_Obj(0x0000011dffc01770) #= <built-in function pow> =#, x2, @DIO_Obj(0x0000011dff4a6950) #= 2 =#))
    DIO_DecRef(x3)
    x3 = @DIO_ChkExcAndDecRefSubCall(Py_CallFunction(@DIO_Obj(0x0000011dffc01770) #= <built-in function pow> =#, x0, @DIO_Obj(0x0000011dff4a6950) #= 2 =#))
    DIO_DecRef(x1)
    x1 = @DIO_ChkExcAndDecRefSubCall(Py_CallFunction(@DIO_Obj(0x0000011dffbf7c20) #= <built-in function add> =#, x1, x3))
    DIO_DecRef(x4)
    x4 = @DIO_ChkExcAndDecRefSubCall(Py_CallFunction(@DIO_Obj(0x0000011d81cdb310) #= <built-in function sqrt> =#, x1))
    @DIO_Return DIO_IncRef(x4)

@label _6
    DIO_DecRef(x0)
    x0 = @DIO_ChkExcAndDecRefSubCall(Py_CallFunction(@DIO_Obj(0x0000011dffc01770) #= <built-in function pow> =#, x2, @DIO_Obj(0x0000011dff4a6950) #= 2 =#))
    DIO_DecRef(x3)
    x3 = @DIO_ChkExcAndDecRefSubCall(Py_CallFunction(@DIO_Obj(0x0000011dffc01770) #= <built-in function pow> =#, x1, @DIO_Obj(0x0000011dff4a6950) #= 2 =#))
    DIO_DecRef(x0)
    x0 = @DIO_ChkExcAndDecRefSubCall(Py_CallFunction(@DIO_Obj(0x0000011dffbf7c20) #= <built-in function add> =#, x0, x3))
    DIO_DecRef(x4)
    x4 = @DIO_ChkExcAndDecRefSubCall(Py_CallFunction(@DIO_Obj(0x0000011d81cdb310) #= <built-in function sqrt> =#, x0))
    @DIO_Return DIO_IncRef(x4)

@label _7
    DIO_DecRef(x2)
    x2 = @DIO_ChkExcAndDecRefSubCall(Py_CallFunction(@DIO_Obj(0x0000011dff4f3360) #= <built-in function isinstance> =#, x1, @DIO_Obj(0x00007ffd6a132140) #= <class 'str'> =#))
    DIO_DecRef(x3)
    x3 = @DIO_ChkExcAndDecRefSubCall(Py_CallFunction(@DIO_Obj(0x00007ffd6a1239d0) #= <class 'bool'> =#, x2))
    if 0x00007ffd6a123868 === reinterpret(UInt64, x3)
        @goto _8
    else
        @goto _10
    end

@label _8
    DIO_DecRef(x2)
    x2 = @DIO_ChkExcAndDecRefSubCall(Py_CallFunction(@DIO_Obj(0x00007ffd6a12efd0) #= <class 'int'> =#, x1))
    @goto _9

@label _9
    DIO_DecRef(x1)
    x1 = @DIO_ChkExcAndDecRefSubCall(Py_CallFunction(@DIO_Obj(0x0000011dffc01770) #= <built-in function pow> =#, x0, @DIO_Obj(0x0000011dff4a6950) #= 2 =#))
    DIO_DecRef(x3)
    x3 = @DIO_ChkExcAndDecRefSubCall(Py_CallFunction(@DIO_Obj(0x0000011dffc01770) #= <built-in function pow> =#, x2, @DIO_Obj(0x0000011dff4a6950) #= 2 =#))
    DIO_DecRef(x1)
    x1 = @DIO_ChkExcAndDecRefSubCall(Py_CallFunction(@DIO_Obj(0x0000011dffbf7c20) #= <built-in function add> =#, x1, x3))
    DIO_DecRef(x4)
    x4 = @DIO_ChkExcAndDecRefSubCall(Py_CallFunction(@DIO_Obj(0x0000011d81cdb310) #= <built-in function sqrt> =#, x1))
    @DIO_Return DIO_IncRef(x4)


@label except
    DIO_Return = Py_NULL

@label ret
    DIO_DecRef(x2)
    DIO_DecRef(x3)
    DIO_DecRef(x4)
    return DIO_Return
end
DIO.DIO_ExceptCode(::typeof(J_hypot_0)) = Py_NULL
const DOC_J_hypot_0 = Base.unsafe_convert(Cstring, "Top J_hypot_0( D0 : int, D1 : int ) {\nlabel _1:\n  D2 = Py_CallFunction(builtins.isinstance, D0 : int, str)\n  D3 : bool = Py_CallFunction(bool, D2)\n  if D3 : bool\n  then goto _2\n  else goto _7\nlabel _10:\n  D2 = Py_CallFunction(_operator.pow, D0 : int, 2)\n  D3 = Py_CallFunction(_operator.pow, D1 : int, 2)\n  D2 = Py_CallFunction(_operator.add, D2, D3)\n  D4 = Py_CallFunction(math.sqrt, D2)\n  return D4\nlabel _2:\n  D2 = Py_CallFunction(int, D0 : int)\n  goto _3\nlabel _3:\n  D0 = Py_CallFunction(builtins.isinstance, D1 : int, str)\n  D3 : bool = Py_CallFunction(bool, D0)\n  if D3 : bool\n  then goto _4\n  else goto _6\nlabel _4:\n  D0 = Py_CallFunction(int, D1 : int)\n  goto _5\nlabel _5:\n  D1 = Py_CallFunction(_operator.pow, D2, 2)\n  D3 = Py_CallFunction(_operator.pow, D0, 2)\n  D1 = Py_CallFunction(_operator.add, D1, D3)\n  D4 = Py_CallFunction(math.sqrt, D1)\n  return D4\nlabel _6:\n  D0 = Py_CallFunction(_operator.pow, D2, 2)\n  D3 = Py_CallFunction(_operator.pow, D1 : int, 2)\n  D0 = Py_CallFunction(_operator.add, D0, D3)\n  D4 = Py_CallFunction(math.sqrt, D0)\n  return D4\nlabel _7:\n  D2 = Py_CallFunction(builtins.isinstance, D1 : int, str)\n  D3 : bool = Py_CallFunction(bool, D2)\n  if D3 : bool\n  then goto _8\n  else goto _10\nlabel _8:\n  D2 = Py_CallFunction(int, D1 : int)\n  goto _9\nlabel _9:\n  D1 = Py_CallFunction(_operator.pow, D0 : int, 2)\n  D3 = Py_CallFunction(_operator.pow, D2, 2)\n  D1 = Py_CallFunction(_operator.add, D1, D3)\n  D4 = Py_CallFunction(math.sqrt, D1)\n  return D4\n}\n")

CFunc_J_hypot_0(self :: PyPtr, args::Ptr{PyPtr}, n::Py_ssize_t) = @DIO_MakePyFastCFunc(J_hypot_0, args, n, 2)
const CFuncPtr_J_hypot_0 = @cfunction(CFunc_J_hypot_0, PyPtr, (PyPtr, Ptr{PyPtr}, Py_ssize_t))
const PyMeth_J_hypot_0 = PyMethodDef(
    Base.unsafe_convert(Cstring, :hypot),
    CFuncPtr_J_hypot_0,
    METH_FASTCALL,
    DOC_J_hypot_0
)
const PyFunc_J_hypot_0 = PyCFunction_New(pointer_from_objref(PyMeth_J_hypot_0), Py_NULL)