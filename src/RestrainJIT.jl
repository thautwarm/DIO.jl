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

include("codegen.jl")
include("py_apis.jl")

end # module
