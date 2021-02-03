export @DIO_Obj, DIO_IncRef, DIO_DecRef, DIO_Undef, DIO_ExceptCode
export @DIO_ChkExc, @DIO_ChkExcAndDecRefSubCall
export @DIO_MakePyFastCFunc
export @DIO_Return

struct DIO_UndefType end
const DIO_Undef = DIO_UndefType()

@inline function DIO_DecRef(::DIO_UndefType) end
@inline function DIO_DecRef(o::PyPtr)
    Py_DECREF(o)
    o
end

@inline function DIO_IncRef(::DIO_UndefType) end
@inline function DIO_IncRef(o::PyPtr)
    Py_INCREF(o)
    o    
end

const PyConstants = Set{Addr}()
function DIO_Obj(addr::Addr)
    o = reinterpret(PyPtr, addr)
    addr in PyConstants || begin
        push!(PyConstants, addr)
        Py_INCREF(o)
    end
    return o
end

macro DIO_Obj(addr::Addr)
    DIO_Obj(addr)
end

macro DIO_ChkExc(ex::Expr)
    f_sym =  @switch ex begin
    @case Expr(:call, args...)
        f_sym = if args[1] isa Symbol
            args[1]
        else
            gensym("f")
        end
        args[1] = :($f_sym = $(args[1]))
        f_sym
    @case _
        error("malformed use of @DIO_ChkExc")
    end

    call = gensym("call")
    ret = Expr(
        :block,
        :($call = $ex),
        Expr(
            :if,
            :($call === DIO_ExceptCode($f_sym)),
            :(@goto except),
            Expr(:call, :DIO_IdentityOrNone, call)))

    return esc(ret)
end

macro DIO_ChkExcAndDecRefSubCall(ex::Expr)
    tmps_to_decref = Symbol[]
    f_sym = nothing

    @switch ex begin
    @case Expr(:call, args...)
        f_sym = args[1] isa Symbol ? args[1] : gensym("f")
        for i in eachindex(ex.args)
            arg = ex.args[i]
            @switch arg begin
            @case Expr(:call, _...) || Expr(:macrocall, _, _, Expr(:call, _...))
                if i === 1
                    tmp = f_sym
                else
                    tmp = gensym("a$(i)")
                end
                push!(tmps_to_decref, tmp)
                ex.args[i] = :($tmp = $arg)
                nothing
            @case _
                nothing
            end
        end
    @case _
        error("malformed use of @DIO_ChkExcAndDecRefSubCall")
    end

    call = gensym("call")
    ret = Expr(:block,
        :($call = $ex)
    )

    # decref unused tmp
    for each in tmps_to_decref
        push!(ret.args, :(DIO_DecRef($each)))
    end

    # exception handle
    push!(
        ret.args,
        Expr(
            :if,
            :($call === DIO_ExceptCode($f_sym)),
            :(@goto except),
            Expr(:call, :DIO_IdentityOrNone, call)))

    return esc(ret)
end

DIO_ExceptCode(f::Function) = error("unknown except handling code for $(f).")

@PyAPISetup begin
    PyErr_SetString = PySym(:PyErr_SetString)
    PyExc_ValueError = PySym(PyPtr, :PyExc_ValueError)
end
@RequiredPyAPI DIO_MakePyFastCFunc
function DIO_MakePyFastCFunc(apis, @nospecialize(jl_func), @nospecialize(args_ptr), @nospecialize(n), narg::Int)
    error_string = "expect $(narg) arguments, while got "
    error_string = :("$($error_string)$(n).")

    call_jl_func = Expr(:call, jl_func)

    for i = 1:narg
        push!(call_jl_func.args, :(unsafe_load($args_ptr, $i)))
    end

    PyErr_SetString = apis.PyErr_SetString
    PyExc_ValueError = apis.PyExc_ValueError

    quote
        if $n != $narg
            $PyErr_SetString($PyExc_ValueError, Base.unsafe_convert(Cstring, $error_string))
            DIO_ExceptCode($jl_func)
        else
            $call_jl_func
        end
    end
end

macro DIO_MakePyFastCFunc(jl_func, args_ptr, n, narg::Int)
    # the first argument(`apis`) of the exported api function is omitted.    
    esc(__module__.DIO_MakePyFastCFunc(jl_func, args_ptr, n, narg))
end

macro DIO_Return(ex)
    esc(@q begin
        DIO_Return = $ex
        @goto ret
    end)
end

@PyAPISetup begin
    PyCFunction_NewEx = PySym(:PyCFunction_NewEx)
end
@RequiredPyAPI PyCFunction_New
function PyCFunction_New(apis, cfuncptr::Ptr{Nothing}, UNUSED::PyPtr)
    @ccall $(apis.PyCFunction_NewEx)(cfuncptr::Ptr{Nothing}, UNUSED::PyPtr, Py_NULL::PyPtr)::PyPtr
end
DIO_ExceptCode(::typeof(PyCFunction_New)) = Py_NULL

@RequiredPyAPI DIO_IdentityOrNone

DIO_IdentityOrNone(apis, o::PyPtr) = o
DIO_IdentityOrNone(apis, _) = begin
    none = apis.PyO.None
    Py_INCREF(none)
    none
end
