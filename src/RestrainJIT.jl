__precompile__(true)
module RestrainJIT
using PyCall
using MLStyle
import GeneralizedGenerated: Typeable, to_type, from_type, to_typelist, RuntimeFn, Argument, Unset, TNil
import DataStructures: list
using CanonicalTraits: @trait, @implement


@implement Typeable{Ptr{T}} where T

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
    Pop();
    PyGlob(qual::Ptr{PyCall.PyObject_struct}, name::String)
    JlGlob(qual::Union{Nothing, Symbol}, name::Symbol)
    UnwindBlock(instrs::Vec{<:AbsA})
    PopException(must::Bool)
end

struct A <: AbsA
    lhs::Union{Nothing, Symbol}
    rhs::Instr
end

@as_record A

mutable struct Cell
    contents :: Any
    Cell() = new()
end

Base.getindex(a::Cell) = a.contents
Base.setindex!(a::Cell, v::T) where T = a.contents = v

struct Closure{C, f}
    closure :: C
end

(cf::Closure{C, f})(args...) where {C, f} = begin
    f(cf.closure..., args...)
end

"""
TODO
"""


function callpy(f::PyObject, args...)
    pycall(f, PyObject, args...)
end


str_yield_sym(::Nothing) = nothing
str_yield_sym(s::String) = Symbol(s)


@noinline function mk_restrain_infr!()
    f <| args = callpy(f, args...)

    jl_protocol_m = pyimport("restrain_jit.bejulia.jl_protocol")
    bridge = jl_protocol_m."bridge"
    bridge_pop! = bridge."pop"
    bridge_push! = bridge."append"

    julia_vm_m = pyimport("restrain_jit.bejulia.julia_vm")
    JuVM = julia_vm_m."JuVM"

    jit_info = pyimport("restrain_jit.jit_info")
    PyFuncInfo = jit_info."PyFuncInfo"
    PyCodeInfo = jit_info."PyCodeInfo"
    pyisa = pybuiltin("isinstance")
    py_none = pybuiltin("None")
    py_true = pybuiltin("True")
    py_getitem = pyimport("operator")."getitem"
    py_hasattr = pybuiltin("hasattr")


    instr_m = pyimport("restrain_jit.bejulia.instructions")
    i_App = instr_m."App"
    i_Ass = instr_m."Ass"
    i_Load = instr_m."Load"
    i_Store = instr_m."Store"
    i_JmpIf = instr_m."JmpIf"
    i_Jmp = instr_m."Jmp"
    i_JmpIfPush = instr_m."JmpIfPush"
    i_Label = instr_m."Label"
    i_Peek = instr_m."Peek"
    i_Return = instr_m."Return"
    i_Push = instr_m."Push"
    i_Pop = instr_m."Pop"
    i_PyGlob = instr_m."PyGlob"
    i_JlGlob = instr_m."JlGlob"
    i_UnwindBlock = instr_m."UnwindBlock"
    i_PopException = instr_m."PopException"

    repr_m = pyimport("restrain_jit.bejulia.representations")
    i_Const = repr_m."Const"
    i_Reg = repr_m."Reg"

    function jit_impl(func_info:: PyObject)

        if !pyisa(func_info, PyFuncInfo)
            error("FATAL: not a PyFuncInfo!")
        end

        to_jl_reg(py::PyObject) :: Reg = Reg(Symbol(py.n))


        function to_jl_const(py::PyObject) :: Const
            if (pyisa <| [py, PyCodeInfo]) == py_true
                return Const(to_jl_fptr(py))
            end
            Const(PyAny(py."val"))
        end

        to_jl_repr(repr::PyObject)::Repr =
            let n = Symbol(repr."__class__".__name__)
                n === :Reg ? to_jl_reg(repr) : to_jl_const(repr)
            end

        function to_jl_instr(::Val{:App}, instr::PyObject)
            App(to_jl_repr(instr."f"), Repr[to_jl_repr(e) for e in instr."args"])
        end

        function to_jl_instr(::Val{:Ass}, instr::PyObject)
            Ass(to_jl_reg(instr."reg"), to_jl_repr(instr."val"))
        end

        function to_jl_instr(::Val{:Store}, instr::PyObject)
            Store(to_jl_reg(instr."reg"), to_jl_repr(instr."val"))
        end

        function to_jl_instr(::Val{:JmpIf}, instr::PyObject)
            JmpIf(Symbol(instr.label), to_jl_repr(instr."cond"))
        end

        function to_jl_instr(::Val{:JmpIfPush}, instr::PyObject)
            JmpIfPush(Symbol(instr.label), to_jl_repr(instr."cond"), to_jl_repr(instr."leave"))
        end

        function to_jl_instr(::Val{:Jmp}, instr::PyObject)
            Jmp(Symbol(instr.label))
        end

        function to_jl_instr(::Val{:Label}, instr::PyObject)
            Label(Symbol(instr.label))
        end

        function to_jl_instr(::Val{:Peek}, instr::PyObject)
            Peek(instr.offset)
        end

        function to_jl_instr(::Val{:Return}, instr::PyObject)
            Return(to_jl_repr(instr."val"))
        end

        function to_jl_instr(::Val{:Push}, instr::PyObject)
            Push(to_jl_repr(instr."val"))
        end

        function to_jl_instr(::Val{:Pop}, ::PyObject)
            Pop()
        end

        function to_jl_instr(::Val{:JlGlob}, instr::PyObject)
            JlGlob(str_yield_sym(instr.qual), Symbol(instr.name))
        end

        function to_jl_instr(::Val{:PyGlob}, instr::PyObject)
            name = instr.name
            is_aggresive && return Value(glob_vals[Symbol(name)])
            ptr = getfield(r_globals, :o)
            PyGlob(ptr, instr.name)
        end

        function to_jl_instr(::Val{:UnwindBlock}, instr::PyObject)
            UnwindBlock(to_jl_instrs(instr."instrs"))
        end

        function to_jl_instr(::Val{:PopException}, instr::PyObject)
            PopException(instr.must)
        end

        function to_jl_instr(::Val{a}, _) where a
            error("Unknown RestrainJIT instruction $a")
        end

        to_jl_instr(instr::PyObject)::Instr =
            let n = Symbol(instr."__class__".__name__)
                to_jl_instr(Val(n), instr)
            end

        to_jl_a(py_ass::PyObject) =
                let
                    lhs = str_yield_sym(py_ass.lhs)
                    A(lhs, to_jl_instr(py_ass."rhs"))
                end
        to_jl_instrs(py_instrs::PyObject) =
            A[to_jl_a(each) for each in py_instrs]


        function to_jl_fptr(py::PyObject)
            if !pyisa(py, PyCodeInfo)
                error("FATAL: not a PyCodeInfo!")
            end
            jl_instrs = to_jl_instrs(py."instrs")
            lineno = py.lineno
            filename = py.filename
            line = LineNumberNode(lineno, filename)
            # TODO: need more position information from Instrs

            argnames = Symbol[Symbol(a) for a in py."argnames"]
            cellvars = Symbol[Symbol(a) for a in py."cellvars"]
            freevars = Symbol[Symbol(a) for a in py."freevars"]
            suite = map(code_gen, jl_instrs)
            type_stable_shared_bounds = get(r_options, "type_stable_shared_bounds") do
                true
            end
            MKBoundCell = type_stable_shared_bounds ? Ref : Cell
            function mk_cell_var(n::Symbol)
                n in argnames && return :($n = $MKBoundCell($n))
                :($n = $Cell())
            end
            predef = Expr[mk_cell_var(e) for e in cellvars]
            push!(predef, :(__object_stack__ = ()))
            if any(x -> x isa UnwindBlock, jl_instrs)
                push!(predef, :(__exception_stack__ = ()))
            end
            body = Expr(:block, line, predef..., suite...)
            Body = to_type(body)

            FreeTy = type_stable_shared_bounds ? Union{Ref, Cell} : Cell

            # free vars
            allargs = Argument[Argument(arg, FreeTy, Unset()) for arg in freevars]
            # args
            append!(allargs, Argument[Argument(arg, nothing, Unset()) for arg in argnames])

            Args = to_type(list(allargs...))
            RuntimeFn{Args, TNil{Argument}, Body}()
        end

        @info :rest
        r_options = func_info.r_options
        r_globals = func_info."r_globals"
        r_codeinfo = func_info."r_codeinfo"
        glob_deps = r_codeinfo."glob_deps"
        r_module = func_info.r_module

        @info :more
        glob_vals = nothing

        is_aggresive = get(r_options, "aggresive") do
            true
        end

        @info :ok
        if is_aggresive
            glob_vals = Dict{Symbol, Any}()
            for k in glob_deps

                o = r_globals."get" <| [k]

                o == py_none && error("Undefined global variable $k at module $r_module.")

                k = Symbol(k)

                glob_vals[k] = if PyAny(py_hasattr <| (o, "__jit__"))
                    PyAny(o."__jit__")
                else
                    PyAny(o)
                end
            end
        else
            glob_vals = r_globals
            # error("not impl") # TODO
        end

        @info :redy glob_vals
        fp = to_jl_fptr(func_info."r_codeinfo")
        @info :done
        pycall(bridge_push!, PyObject, fp)
    end

    function restrain_jl_side_aware!()
        py = pycall(bridge_pop!, PyObject)
        try
            jit_impl(py)
        catch e
            pyraise(e)
        end
        0
    end
    restrain_jl_side_aware!
end


function py_mk_tuple
end

function py_mk_func
end


function py_mk_closure
end

function py_add
end

function peek(::Val{0}, tp::Tuple{A, B})::A where {A, B}
    tp[1]
end

function peek(::Val{n}, tp::Tuple{A, B})::A where {n, A, B}
    peek(Val(n-1), tp[2])
end

_repr_to_expr(r::Reg) = r.n
_repr_to_expr(r::Const{T}) where T = r.val

function code_gen(ass::A)
    lhs = ass.lhs
    rhs = code_gen(ass.rhs)
    lhs === nothing && return rhs
    :($lhs = $rhs)
end

function code_gen(instr::Instr)
    @match instr begin
        Value(v) => v
        App(f, args) =>
            let
                f = _repr_to_expr(f)
                args = map(_repr_to_expr, args)
                Expr(:call, f, args...)
            end
        Ass(reg, val) =>
            let
                reg = reg.n
                val = _repr_to_expr(val)
                :($reg = $val)
            end
        Load(reg) =>
            let reg = reg.n
                :($reg[])
            end
        Store(reg, val) =>
            let reg = reg.n
                val = _repr_to_expr(val)
                :($reg[] = $val)
            end
        JmpIf(label, cond) =>
            let cond = _repr_to_expr(cond)
                :(if $cond; @goto $label end)
            end
        JmpIfPush(label, cond, leave) =>
            let cond = _repr_to_expr(cond)
                leave = _repr_to_expr(cond)
                :(
                    if $cond
                    __object_stack__ = ($leave, __object_stack__)
                    @goto $label
                    end
                )
            end
        Label(label) => :(@label $label)
        Peek(n) => :($peek($Val($n), __object_stack__))
        Return(val) =>
            let val = _repr_to_expr(val)
                :(return $val)
            end
        Push(val) =>
            let val = _repr_to_expr(val)
                :(__object_stack__ = ($val, __object_stack__))
            end
        Pop() => quote
                let v = __object_stack__[1]
                    __object_stack__ = __object_stack__[2]
                    v
                end
            end
        PyGlob(ptr, name) => :($getproperty($PyObject($ptr), $name))
        JlGlob(:RestrainJIT, name) => :($RestrainJIT.$name)
        UnwindBlock(instrs) =>
            let suite = map(code_gen, instrs)
                :(
                    try
                        $(suite...)
                    catch e
                        __exception_stack__ = (e, __exception_stack__)
                    end
                )
            end
        PopException(false) =>
                :(
                    if $isempty(__exception_stack__)
                        nothing
                    else
                        let e = __exception_stack__[1]
                            __exception_stack__ = __exception_stack__[2]
                            e
                        end
                    end
                )
        PopException(true) =>
            :(
                let e = __exception_stack__[1]
                    __exception_stack__ = __exception_stack__[2]
                    e
                end
            )
    end
end

end # module
