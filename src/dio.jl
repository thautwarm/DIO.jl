module DIO
using MLStyle
import Libdl
export @PyDLL_API

include("juliainfo.jl")
include("python.jl")
include("utils.jl")
include("static.jl")

const Setup_API_Symbols = Symbol[]
const PyDLL_Struct_FieldSymbols = Symbol[]
const PyDLL_Struct_Fields = Any[]
const PyDLL_Struct_Construct = Expr[]

"""
Wrap the builtin function which required Python DLL.

Before loading Python DLL:

    ```
    function MyFunc(apis, f::PyPtr)
        o = apis.PyObject_CallNoArgs(f)
        return o
    end
    DIO_ExceptCode(::typeof(MyFunc)) = Py_NULL

    @PyDLL_API MyFunc begin
        PyObject_CallNoArgs = PySym(:PyObject_CallNoArgs)
    end 
    ```

After loading Python DLL in **another** module,
    ```
    DIO.@setup
    MyFunc(some_py_obj) # first parameter is automatically filled
    ```
"""
macro PyDLL_API(api::Symbol, define::Expr)
    Meta.isexpr(define, :block) ||
        error("malformed use of @PyDLL_API: require a block of assignments but got $(define)")
    push!(Setup_API_Symbols, api)
    for each in define.args
        @switch each begin
        @case ::LineNumberNode 
            nothing
        @case :($(a :: Symbol) = $expr)
            if a in PyDLL_Struct_FieldSymbols
                error("duplicate symbol reference from Python DLL: $a")
            end
            t = Symbol("_Type_Of_$a")
            tmp = gensym(a)
            push!(PyDLL_Struct_FieldSymbols, a)
            push!(PyDLL_Struct_Fields, :($a :: $t))
            push!(PyDLL_Struct_Construct,
                    @q begin
                        $tmp = $expr
                        $t = typeof($tmp)
                        $tmp
                    end)
            nothing
        @case _
            # TODO
            error("malformed use of @PyDLL_API: expect assignments but got:  $each")
        end
    end
end

const IsInitialized = Ref(false)
_initialize() = IsInitialized[] = true
macro setup(path::String)
    if IsInitialized[]
        Base.@warn "Re-setup is not allowed. Restart your runtime and import this package again."
    else
        r = @q begin
            $__source__
            const PyDLL = $Libdl.dlopen($path)
            const $(esc(:PyDLL)) = PyDLL

            PySym(t, sym::Symbol) = reinterpret(t, $Libdl.dlsym(PyDLL, sym))
            PySym(sym::Symbol) = $Libdl.dlsym(PyDLL, sym)
            const $(esc(:PySym)) = PySym

            PyDLL_Args = $(Expr(:tuple, PyDLL_Struct_Construct...))

            struct $(esc(:PyDLLType))
                $(PyDLL_Struct_Fields...)
            end

            const PyDLL_Struct = $(esc(:PyDLLType))(PyDLL_Args...)
            const $(esc(:PyDLL_Struct)) = PyDLL_Struct
            $(
                [:($(esc(each))(args...) = $(@__MODULE__).$each(PyDLL_Struct, args...))
                for each in Setup_API_Symbols]...
            )
            $_initialize()
        end
        println(r)
        r
    end
end

include("support.jl")
include("dynamic.jl")

end
