"""
corresponding to the restrain_jit.bejulia.functional
"""

module Functional

@inline function py_fast_foreach(xs)
    function (f)
        foreach(f, xs)
    end
end

@inline function py_fast_map(xs)
    function (f)
        map(f, xs)
    end
end

end