#= we can implement py_load_method_ for lists, dicts and sets here =#
# list

py_load_method_(v::Vector, ::Val{:append}) = (v, push!)
py_load_method_(v::Vector, ::Val{:pop}) = (v, pop!)


pyrange(b) = 0:b-1
pyrange(a, b) = a:b-1
pyrange(a, b, c) = a:c:b-1

special_globals = Dict{String, Any}("range" => pyrange, "len" => length)

function init_jl_basics!()
    py_mod = pyimport("restrain_jit.bejulia.basics")
    JList = py_mod.JList
    JList.__getitem__ = py_subscr
    JList.__setitem__ = py_setitem
    JList.append = push!
    JList.pop = pop!
    # TODO
end