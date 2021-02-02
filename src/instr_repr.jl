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

abstract type AbsA end

@data Instr begin
    Value(v::Any)
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
    Pop()
    PyGlob(sym::Symbol)
    JlGlob(qual::Union{Nothing, Symbol}, name::Symbol)
    UnwindBlock(instrs::Vec{<:AbsA})
    PopException(must::Bool)
end

struct A <: AbsA
    lhs::Union{Nothing, Symbol}
    rhs::Instr
end

@as_record A
