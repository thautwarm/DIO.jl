module DIO
using MLStyle
import Libdl
import Parameters
const DEBUG = false
export @exportapi, @apisetup, PyOType

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
Automatically bind the loaded Python APIs(`PyAPI_Struct`) to the first argument,
and enter a function `MyFunc(...) = <callee module>.MyFunc(PyAPI_Struct, ...)` 
to the caller module:
    ```
    @apisetup begin
        PyObject_Call = PySym(:PyObject_Call)
    end
    @exportapi MyFunc
    function MyFunc(apis, ...)
        ccall(apis.PyObject_Call, ...)
    end
    ```
"""
macro exportapi(sym::Symbol)
    _exportapi(sym)
end
function _exportapi(sym::Symbol)
    push!(Setup_AutoBound_Symbols, sym)
end
macro apisetup(define::Expr)
    _apisetup(define)
end

function _apisetup(define::Expr)
    Meta.isexpr(define, :block) ||
        error("malformed use of @apisetup require a block of assignments but got $(define).")

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
            error("malformed use of @apisetup: expect assignments but got: $each")
        end
    end
end

Parameters.@with_kw struct PyOType
    PY_VERSION :: Tuple{Int, Int, Int, String, Int}
    builtins :: PyPtr
    print :: PyPtr
    bool :: PyPtr
    int :: PyPtr
    float :: PyPtr
    str :: PyPtr
    type :: PyPtr
    None :: PyPtr
    True :: PyPtr
    False :: PyPtr
    complex :: PyPtr
    tuple :: PyPtr
    list :: PyPtr
    set :: PyPtr
    dict :: PyPtr
    import_module :: PyPtr
end

const IsInitialized = Ref(false)
const LibdlFlags = Libdl.RTLD_GLOBAL
_initialize() = IsInitialized[] = true
macro setup(libpy_addr :: Addr)
    if IsInitialized[]
        Base.@warn "Re-setup is not allowed. Restart your runtime and import this package again."
    else
        py_dll_struct_cons_expr =
            @q let $(PyAPI_Construct...)
                ($(PyAPI_FieldSymbols...), )
            end
        
        unhygienic_part1 = @q begin
            $__source__
            const PyDLL = reinterpret(Ptr{Nothing}, $libpy_addr)
            PySym(sym::Symbol) = $Libdl.dlsym(PyDLL, sym)
            function PySymMaybe(sym::Symbol)
                p = $Libdl.dlsym_e(PyDLL, sym)
                p == C_NULL ? nothing : p
            end
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
        
        r = @q begin
            # 'PyO' is computed when starting Julia from Python
            PyO = $(esc(:PyO))
            $(esc(unhygienic_part1))
            PySym = $(esc(:PySym))
            PySymMaybe = $(esc(:PySymMaybe))
            $hygienic_part
            $(esc(unhygienic_part2))
        end
        DEBUG && @info r
        return r
    end
end
include("macros.jl")
include("symbols.jl")
include("support.jl")
include("dynamic.jl")

end
