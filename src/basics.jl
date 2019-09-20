#= we can implement py_load_method_ for lists, dicts and sets here =#
# list

py_load_method_(v::Vector, ::Val{:append}) = (v, push!)
py_load_method_(v::Vector, ::Val{:pop}) = (v, pop!)

function init_jl_basics!()
    py_mod = pyimport("restrain_jit.bejulia.basics")
    JList = py_mod.JList
    JList.__getitem__ = py_subscr
    JList.__setitem__ = py_setitem
    JList.append = push!
    JList.pop = pop!
    # TODO
end