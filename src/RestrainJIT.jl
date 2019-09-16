module RestrainJIT
using PyCall
using MLStyle
@use UppercaseCapturing

abstract type Repr end

struct Const{T} <: Repr
    val::T
end

@as_record Const

struct Reg <: Repr
    n::Symbol
end

@as_record Reg
Vec = Vector

@data Instr begin
    App(f:: Repr, args:: Vec{Repr})
    Ass(reg::Reg, val::Repr)
    Load(reg::Reg)
    Store(reg::Reg, val::Repr)
    JmpIf(label::Symbol, cond::Repr)
    JmpIfPush(label::Symbol, cond::Repr, leave::Repr)
    Jmp(label::Symbol)
    Label(label::Symbol)
    Peek(offset::Int)
    Return(val::Repr)
    Push(val::Repr)
    Pop();
    PyGlob(qual::Union{Nothing, Symbol}, name::Symbol)
    JlGlob(qual::Union{Nothing, Symbol}, name::Symbol)
    UnwindBlock(instrs::Vec{Instr})
    PopException(must::Bool)
end


@noinline function mk_restrain_infr!()
    py_jit = pyimport("restrain_jit.bejulia.jl_protocol")
    function jit_impl(py:: PyObject)
        println(py)
        # TODO

    end
    function restrain_jl_side_aware!()
        instrs = getproperty(py_jit, "bridge")
        jit_impl(instrs)
        0
    end
    restrain_jl_side_aware!
end





end # module
