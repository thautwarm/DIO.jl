#=
test_pycall:
- Julia version: 
- Author: redbq
- Date: 2019-09-17
=#

using PyCall

const pylist = pybuiltin("list")
const pyint = pybuiltin("int")
const empty_args = Vector{PyObject}()

function test(n::Int)
   l = pycall(pylist, PyObject)
   append = getproperty(l, "append")
   e = pycall(pyint, PyObject)
   x = PyNULL()
   for i = 1:n
       pycall!(x, append, PyObject, e)
   end
   l
end

using BenchmarkTools
@btime (test(100));