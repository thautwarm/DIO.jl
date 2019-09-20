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


# for checking if global object is rewritten dirty
const py_module_world_counters = Dict{UInt64, Dict{Symbol, Int}}()

# module will never get freed, so it's safe to store its globals here.
const py_module_globals = Dict{UInt64, PyObject}()

include("instr_repr.jl")
include("as_constants.jl")

include("codegen.jl")
include("py_apis.jl")
include("collections.jl")

include("functional.jl")

function init!()
    fp = pyimport("restrain_jit.bejulia.functional")

    fp.select.__jit__ = Functional.py_fast_map
    fp.foreach.__jit__ = Functional.py_fast_foreach
    fp.J.__jit__ = as_constant_expr

    mk_restrain_infr!()
end

end # module
