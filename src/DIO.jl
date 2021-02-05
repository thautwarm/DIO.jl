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
Automatically bound the loaded Python APIs(`PyAPI_Struct`) to the first argument,
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
    bool::PyPtr
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
            function PySymMaybe(sym::Symbol)
                p = $Libdl.dlsym_e(PyDLL, sym)
                p == C_NULL ? nothing : p
            end
            function PySymMaybe(t, sym::Symbol)
                p = $Libdl.dlsym_e(PyDLL, sym)
                p == C_NULL ? nothing : reinterpret(t, p)
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
        
        @q begin
            # 'PyO' is computed when starting Julia from Python
            PyO = $(esc(:PyO))
            $(esc(unhygienic_part1))
            PySym = $(esc(:PySym))
            PySymMaybe = $(esc(:PySymMaybe))
            $hygienic_part
            $(esc(unhygienic_part2))
        end
    end
end

macro pycall(f, args...)
    tmp = gensym("pycall")
    r = @q begin
        $__source__
        $tmp = $f($(args...))
        if $tmp === DIO_ExceptCode($f)
            return Py_NULL
        else
            $tmp
        end
    end
    esc(r)
end


function _autoapi(var::Union{Symbol, Nothing}, ex::Expr, __source__)
    sym, anns, returntype, argtypes, args, except =
        @switch ex begin
        @case :($sym($(argtypes...))::$returntype != $except) ||
              :($sym($(argtypes...))::$returntype) && let except = undef end 

            narg = length(argtypes)
            args = [Symbol("_arg$(i)") for i = 1:narg]
            anns = [:($(args[i]) :: $(argtypes[i])) for i = 1:narg]
            sym, anns, returntype, Expr(:tuple, argtypes...), args, except
        end
    var === nothing && (var = sym;)
    r = @q begin
        $__source__
        function $var(apis, $(anns...))
            $__source__
            r = ccall(apis.$sym, $returntype, $argtypes, $(args...))
            return r
        end
    end
    if except !== undef    
        push!(r.args, :($DIO.DIO_ExceptCode(::typeof($var)) = $except))
    end
    return r
end

"""
create an API from a C symbol
    ```
        @autoapi PyObject_Call(PyPtr, PyPtr)::PyPtr != Py_NULL
    ```
    expands to
    ```
    function PyObject_Call(apis, x, y)
        ccall(apis.PyObject_Call, PyPtr, (PyPtr, PyPtr), x, y)
    end
    DIO.DIO_ExceptCode(::typeof(PyObject_Call)) = Py_NULL
    ```
"""
macro autoapi(ex::Expr)
    esc(_autoapi(nothing, ex, __source__))
end

macro autoapi(rename::Symbol, ex::Expr)
    esc(_autoapi(rename, ex, __source__))
end

include("support.jl")
include("dynamic.jl")

end
