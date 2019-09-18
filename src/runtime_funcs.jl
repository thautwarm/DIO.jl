struct YARuntimeFn{Args, Body} <: Function end

@implement Typeable{YARuntimeFn{Args, Body}} where {Args, Body}


"""
functions that depend on julia level global variables
"""
struct GYARuntimeFn{GlobTuple, Args, Body} <: Function
    globals :: GlobTuple
end

@implement Typeable{GYARuntimeFn{GlobTuple, Args, Body}} where {GlobTuple, Args, Body}

function _ass_positional_args!(assign_block::Vector{Expr}, args, ninput::Int, pargs :: Symbol)
    length(args) > ninput && error("Input arguments too few.")
    i = 1
    for arg in args
        ass = :($arg = $pargs[$i])
        push!(assign_block, ass)
        i += 1
    end
end

@generated function (::YARuntimeFn{Args, Body})(pargs...) where {Args, Body}
    ninput = length(pargs)
    assign_block = Expr[]
    body = from_type(Body)
    _ass_positional_args!(assign_block, Args, ninput, :pargs)
    quote
        let $(assign_block...)
            $body
        end
    end
end

@generated function (g::GYARuntimeFn{GlobTuple, Args, Body})(pargs...) where {
    GlobTuple, Args, Body
}
    ninput = length(pargs)
    assign_block = Expr[]
    body = from_type(Body)
    _ass_positional_args!(assign_block, Args, ninput, :pargs)
    quote
        __persistent_globals__ = g.globals
        let $(assign_block...)
            $body
        end
    end
end
