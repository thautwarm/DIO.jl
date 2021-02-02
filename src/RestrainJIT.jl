__precompile__(true)
module RestrainJIT
using PyCall
using MLStyle
import DataStructures: list, OrderedSet
PyObject_struct = PyCall.PyObject_struct
PyPtr_NULL = PyCall.PyPtr_NULL

function callpy(f::PyObject, args...)
    pycall(f, PyObject, args...)
end

f <| args = callpy(f, args...)

struct _Token end

include("typeable.jl")
include("runtime_funcs.jl")

@use UppercaseCapturing

include("instr_repr.jl")
include("as_constants.jl")

include("codegen.jl")
include("py_apis.jl")
include("basics.jl")
include("functional.jl")

function init!()
    init_functional!()
    init_jl_basics!()
    mk_restrain_infr!()
end

end # module
