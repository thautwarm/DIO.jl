#= we can implement py_load_method_ for lists, dicts and sets here =#
# list
py_load_method_(v::Vector{T}, Val{:append}) = (v, push!)

py_load_method_(v::Vector{T}, Val{:pop}) = (v, pop!)
