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

function init_functional!()
    fp = pyimport("restrain_jit.bejulia.functional")

    fp.select.__jit__ = py_fast_map
    fp.foreach.__jit__ = py_fast_foreach
    fp.J.__jit__ = as_constant
end