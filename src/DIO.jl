module DIO
using MLStyle
import Libdl
import Parameters
DEBUG = false
export @RequiredPyAPI, @PyAPISetup, PyOType

include("juliainfo.jl")
include("python.jl")
include("utils.jl")
include("static.jl")

const Setup_AutoBound_Symbols = Symbol[]
const PyAPI_FieldSymbols = Symbol[]
const PyAPI_FieldTypes = Symbol[]
const PyAPI_Fields = Any[]
const PyAPI_Construct = Expr[]

"""
Automatically bound the loaded Python APIs(`PyAPI_Struct`) to the first argument,
and enter a function `MyFunc(...) = <callee module>.MyFunc(PyAPI_Struct, ...)` 
to the caller module:
    ```
    @PyAPISetup begin
        PyObject_Call = PySym(:PyObject_Call)
    end
    @RequiredPyAPI MyFunc
    function MyFunc(apis, ...)
        ccall(apis.PyObject_Call, ...)
    end
    ```
"""
macro RequiredPyAPI(sym::Symbol)
    _RequiredPyAPI(sym)
end
function _RequiredPyAPI(sym::Symbol)
    push!(Setup_AutoBound_Symbols, sym)
end

macro PyAPISetup(define::Expr)
    _PyAPISetup(define)
end

function _PyAPISetup(define::Expr)
    Meta.isexpr(define, :block) ||
        error("malformed use of @PyAPISetup require a block of assignments but got $(define).")

    for each in define.args
        @switch each begin
        @case ::LineNumberNode
            nothing
        @case :($(a :: Symbol) = $expr)
            if a in PyAPI_FieldSymbols
                error("duplicate symbol reference from Python DLL: $a")
            end
            t = Symbol("_Type_Of_$a")
            push!(PyAPI_FieldTypes, t)
            push!(PyAPI_FieldSymbols, a)    
            push!(PyAPI_Fields, :($a :: $t))
            push!(PyAPI_Construct, :($a = $expr))
            nothing
        @case _
            # TODO
            error("malformed use of @PyAPISetup: expect assignments but got: $each")
        end
    end
end

Parameters.@with_kw struct PyOType
    bool::PyPtr
    int :: PyPtr
    float :: PyPtr
    str :: PyPtr
    type :: PyPtr
    None :: PyPtr
    complex :: PyPtr
    tuple :: PyPtr
    list :: PyPtr
    set :: PyPtr
    dict :: PyPtr
    import_module :: PyPtr
end

const IsInitialized = Ref(false)
_initialize() = IsInitialized[] = true
macro setup(path::String)
    if IsInitialized[]
        Base.@warn "Re-setup is not allowed. Restart your runtime and import this package again."
    else
        py_dll_struct_cons_expr =
            @q let $(PyAPI_Construct...)
                ($(PyAPI_FieldSymbols...), )
            end
        
        unhygienic_part1 = @q begin
            $__source__
            const PyDLL = $Libdl.dlopen($path)
            PySym(t, sym::Symbol) = reinterpret(t, $Libdl.dlsym(PyDLL, sym))
            PySym(sym::Symbol) = $Libdl.dlsym(PyDLL, sym)
        end

        # compute all required symbols from libpython.so/dll, and other related values
        hygienic_part = :($(esc(:PyAPI_Args)) = $py_dll_struct_cons_expr)

        unhygienic_part2 = @q begin
            # compute types of all required symbols and related values
            $(Expr(:tuple, PyAPI_FieldTypes...)) =  map(typeof, PyAPI_Args)

            # declare the type of 'PyAPI_Struct'
            struct PyAPI_Type
                PyO :: PyOType
                $(PyAPI_Fields...)
            end

            # construct 'PyAPI_Struct'
            const PyAPI_Struct = PyAPI_Type(PyO, PyAPI_Args...)
            PyAPI_Args = nothing

            $( [:($each(args...) = $(@__MODULE__).$each(PyAPI_Struct, args...))
                for each in Setup_AutoBound_Symbols]...)
            # set up exception code for API functions
            $( [:($(@__MODULE__).DIO_ExceptCode(::typeof($each)) = DIO_ExceptCode($(@__MODULE__).$each))
                for each in Setup_AutoBound_Symbols]...)
            $_initialize()
        end
        
        @q begin
            # 'PyO' is computed when starting Julia from Python
            PyO = $(esc(:PyO))
            $(esc(unhygienic_part1))
            PySym = $(esc(:PySym))
            $hygienic_part
            $(esc(unhygienic_part2))
        end
    end
end

include("support.jl")
include("dynamic.jl")

end
