function _autoapi(ex::Expr, options::AbstractArray{Any}, @nospecialize(__source__))
    except = undef
    var = nothing
    rc = nothing
    cast = nothing
    castexc = true
    for opt_ex in options
        @switch opt_ex begin
        @case :(except($v))
            except = v
        @case :(mangle($v))
            var = v
        @case :borrow2new
            rc = :(Py_XINCREF(ret))
        @case :(cast($f))
            cast = f
        @case :nocastexc
            castexc = false
        @case _
            Base.@warn "@autoapi: unknown option $(opt_ex)."
        end
    end

    sym, anns, returntype, argtypes, args =
        @switch ex begin
        
        @case :($sym($(argtypes...))::$returntype) && let except′ = undef end ||
              :($sym($(argtypes...))::$returntype != $except′)
            except === undef && (except = except′;)
            narg = length(argtypes)
            args = [Symbol("_arg$(i)") for i = 1:narg]
            anns = [:($(args[i]) :: $(argtypes[i])) for i = 1:narg]
            sym, anns, returntype, Expr(:tuple, argtypes...), args
        end
    var === nothing && (var = sym;)
    r = @q begin
        $__source__
        function $var(apis, $(anns...))::$returntype
            $__source__
            ret = ccall(apis.$sym, $returntype, $argtypes, $(args...))
            $rc
            return ret
        end
    end
    val = gensym(:val)
    if except !== undef 
        push!(r.args, :($DIO.DIO_ExceptCode(::typeof($var)) = $except))
    end
    if nothing !== cast
        push!(r.args, :($DIO.DIO_HasCast(::typeof($var)) = true))
        push!(r.args, :($DIO.DIO_Cast(::typeof($var), $val::$returntype)::PyPtr = $cast($val)))
        push!(r.args, :($DIO.DIO_CastExc(::typeof($var)) = $castexc))
    end
    return r
end


"""
create an API from a C symbol
    ```
        @autoapi PyObject_Call(PyPtr, PyPtr)::PyPtr except(Py_NULL)
    ```
    expands to
    ```
    function PyObject_Call(apis, x::PyPtr, y::PyPtr)::PyPtr
        ccall(apis.PyObject_Call, PyPtr, (PyPtr, PyPtr), x, y)
    end
    
    DIO.DIO_ExceptCode(::typeof(PyObject_Call)) = Py_NULL
    ```
"""
macro autoapi(ex::Expr, @nospecialize(options...))
    esc(_autoapi(ex, Any[options...], __source__))
end

"""
Handling Python exception, the result may not be boxed.
"""
macro callexc(f, args...)
    tmp = gensym("callexc")
    r = @q begin
        $__source__
        $tmp = $f($(args...))
        if DIO_ExceptCode($f) === $tmp
            return Py_NULL
        else
            $tmp
        end
    end
    esc(r)
end
