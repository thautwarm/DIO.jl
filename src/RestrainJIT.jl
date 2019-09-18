__precompile__(true)
module RestrainJIT
using PyCall
using MLStyle
import DataStructures: list, OrderedSet
PyObject_struct = PyCall.PyObject_struct
PyPtr_NULL = PyCall.PyPtr_NULL

include("typeable.jl")
include("runtime_funcs.jl")

@use UppercaseCapturing

# TODO: being awared by Python GC
const native_ptrs = Dict{UInt64, Any}()
get_native_ptr(i::UInt64) = native_ptrs[i]
get_native_ptr(i) = get_native_ptr(UInt64(i))
include("instr_repr.jl")
include("codegen.jl")
include("py_apis.jl")
include("functional.jl")

mutable struct Aware!
    f :: Function
    Aware!() = new()
end


(aware!::Aware!)() = aware!.f()
aware! = Aware!()

function init!()
    fp = pyimport("restrain_jit.bejulia.functional")
    py_id = pybuiltin("id")

    fp.map.__jit__ = Functional.py_fast_map
    native_ptrs[py_id(fp.map)] = Functional.py_fast_map
    fp.foreach.__jit__ = Functional.py_fast_foreach

    native_ptrs[py_id(fp.foreach)] = Functional.py_fast_foreach
    aware!.f = mk_restrain_infr!()
end

end # module
