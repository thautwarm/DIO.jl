mutable struct Cell
    contents :: Any
    Cell() = new()
end

Base.getindex(a::Cell) = a.contents
Base.setindex!(a::Cell, v::T) where T = a.contents = v

str_yield_sym(::Nothing) = nothing
str_yield_sym(s::String) = Symbol(s)

# TODO: more heap-allocated isimmutable types

@inline py_is(a::PyObject, b::PyObject) = getfield(a, :o) === getfield(b, :o)

@noinline function mk_restrain_infr!()

    jl_protocol_m = pyimport("restrain_jit.bejulia.jl_protocol")
    PySymbol = pyimport("restrain_jit.vm.am").Symbol
    PyValSymbol = pyimport("restrain_jit.vm.am").ValSymbol

    bridge = jl_protocol_m."bridge"
    bridge_pop! = bridge."pop"
    bridge_push! = bridge."append"
    jit_info = pyimport("restrain_jit.bejulia.pragmas")
    const_pragma = jit_info."const"
    julia_vm_m = pyimport("restrain_jit.bejulia.julia_vm")
    JuVM = julia_vm_m."JuVM"

    jit_info = pyimport("restrain_jit.jit_info")
    PyFuncInfo = jit_info."PyFuncInfo"
    PyCodeInfo = jit_info."PyCodeInfo"
    pyisa = pybuiltin("isinstance")
    py_none = pybuiltin("None")
    py_true = pybuiltin("True")
    py_getitem = pyimport("operator")."getitem"
    py_hasattr = pybuiltin("hasattr")
    py_set = pybuiltin("set")
    py_id = pybuiltin("id")


    repr_m = pyimport("restrain_jit.bejulia.representations")

    function jit_impl(func_info:: PyObject)

        if !pyisa(func_info, PyFuncInfo)
            error("FATAL: not a PyFuncInfo!")
        end

        to_jl_reg(py::PyObject) :: Reg = Reg(Symbol(py.n))

        function to_jl_const(py::PyObject) :: Const
            val = py."val"
            if (pyisa <| [val, PyCodeInfo]) == py_true
                return Const(to_jl_fptr(val))
            end
            val = PyAny(val)
            if pyisa(val, PySymbol) == py_true
                val = QuoteNode(Symbol(val.s))
            elseif pyisa(val, PyValSymbol) == py_true
                val = Val(Symbol(val.s))
            end
            Const(as_constant_expr(val))
        end

        to_jl_repr(repr::PyObject)::Repr =
            let n = Symbol(repr."__class__".__name__)
                n === :Reg ? to_jl_reg(repr) : to_jl_const(repr)
            end

        function to_jl_instr(::Val{:App}, instr::PyObject)
            App(to_jl_repr(instr."f"), Repr[to_jl_repr(e) for e in instr."args"])
        end

        function to_jl_instr(::Val{:Ass}, instr::PyObject)
            Ass(to_jl_reg(instr."reg"), to_jl_repr(instr."val"))
        end

        function to_jl_instr(::Val{:Store}, instr::PyObject)
            Store(to_jl_reg(instr."reg"), to_jl_repr(instr."val"))
        end

        function to_jl_instr(::Val{:Load}, instr::PyObject)
            Load(to_jl_reg(instr."reg"))
        end

        function to_jl_instr(::Val{:JmpIf}, instr::PyObject)
            JmpIf(Symbol(instr.label), to_jl_repr(instr."cond"))
        end

        function to_jl_instr(::Val{:JmpIfPush}, instr::PyObject)
            JmpIfPush(Symbol(instr.label), to_jl_repr(instr."cond"), to_jl_repr(instr."leave"))
        end

        function to_jl_instr(::Val{:Jmp}, instr::PyObject)
            Jmp(Symbol(instr.label))
        end

        function to_jl_instr(::Val{:Label}, instr::PyObject)
            Label(Symbol(instr.label))
        end

        function to_jl_instr(::Val{:Peek}, instr::PyObject)
            Peek(instr.offset)
        end

        function to_jl_instr(::Val{:Return}, instr::PyObject)
            Return(to_jl_repr(instr."val"))
        end

        function to_jl_instr(::Val{:Push}, instr::PyObject)
            Push(to_jl_repr(instr."val"))
        end

        function to_jl_instr(::Val{:Pop}, ::PyObject)
            Pop()
        end

        function to_jl_instr(::Val{:JlGlob}, instr::PyObject)
            JlGlob(str_yield_sym(instr.qual), Symbol(instr.name))
        end

        function to_jl_instr(::Val{:PyGlob}, instr::PyObject)
            name = instr.name
            sym = Symbol(name)
            i = findfirst(==(sym), const_glob_names)
            i !== nothing && return Value(:(__persistent_globals__[$i]))
            PyGlob(Symbol(name))
        end

        function to_jl_instr(::Val{:UnwindBlock}, instr::PyObject)
            UnwindBlock(to_jl_instrs(instr."instrs"))
        end

        function to_jl_instr(::Val{:PopException}, instr::PyObject)
            PopException(instr.must)
        end

        function to_jl_instr(::Val{a}, _) where a
            error("Unknown RestrainJIT instruction $a")
        end

        to_jl_instr(instr::PyObject)::Instr =
            let n = Symbol(instr."__class__".__name__)
                to_jl_instr(Val(n), instr)
            end

        to_jl_a(py_ass::PyObject) =
                let
                    lhs = str_yield_sym(py_ass.lhs)
                    A(lhs, to_jl_instr(py_ass."rhs"))
                end
        to_jl_instrs(py_instrs::PyObject) =
            A[to_jl_a(each) for each in py_instrs]


        function to_jl_fptr(py::PyObject)
            if !pyisa(py, PyCodeInfo)
                error("FATAL: not a PyCodeInfo!")
            end
            jl_instrs = to_jl_instrs(py."instrs")
            cur_glob_deps = Tuple(map(Symbol, py.glob_deps))

            lineno = py.lineno
            filename = py.filename
            line = LineNumberNode(lineno, filename)
            # TODO: need more position information from Instrs

            argnames = Symbol[Symbol(a) for a in py."argnames"]
            cellvars = Symbol[Symbol(a) for a in py."cellvars"]
            freevars = Symbol[Symbol(a) for a in py."freevars"]
            suite = map(code_gen, jl_instrs)

            type_stable_shared_bounds = get(r_options, "type_stable_closures") do
                true
            end
            MKBoundCell = type_stable_shared_bounds ? Ref : Cell

            function mk_cell_var(n::Symbol)
                n in argnames && return :($n = $MKBoundCell($n))
                :($n = $Cell())
            end

            predef = Expr[mk_cell_var(e) for e in cellvars if e ∉ freevars]
            push!(predef, :(__object_stack__ = ()))

            # check if any try blocks
            if any(x -> x isa UnwindBlock, jl_instrs)
                push!(predef, :(__exception_stack__ = ()))
            end

            body = Expr(:block, line, predef..., suite...)
            Body = to_type(body)
            Args = (freevars..., argnames...)

# if any globals referenced, it's a 'GYARuntimeFn',
# otherwise a 'YARuntimeFn'
            if any((x -> x in cur_glob_deps).(glob_dep_syms))
                :($GYARuntimeFn{$glob_tuple_type, $Args, $Body}(__persistent_globals__))
            else
                YARuntimeFn{Args, Body}()
            end
        end

        r_options = func_info.r_options
        r_globals = func_info."r_globals"
        r_ann = r_globals."get" <| ["__annotations__"]
        r_codeinfo = func_info."r_codeinfo"
        glob_deps = r_codeinfo.glob_deps
        r_module = func_info.r_module
        r_attrnames = func_info."r_attrnames"

        const_globs = Any[]
        const_glob_names = Symbol[]


# some special globals/builtins
        for (k, v) in special_globals
            lookup = r_globals."get" <| [k]
            expect = pybuiltin(k)
            if py_is(lookup, py_none)
                lookup = expect
            end
            !py_is(lookup, expect) && continue

            i = findfirst(==(k), glob_deps)
            i !== nothing && begin
                push!(const_glob_names, Symbol(k))
                push!(const_globs, pyrange)
            end
        end

# all existing JIT stuffs are marked as const globals
        glob_dep_syms = map(Symbol, glob_deps)
        left_indices = Int[]
        for (i, (k, sym)) in enumerate(zip(glob_deps, glob_dep_syms))
            haskey(special_globals, k) && continue
            o = r_globals."get" <| [k, py_none]
            if py_is(o, py_none) || ((py_hasattr <| [o, "__jit__"]) != py_true)
                push!(left_indices, i)
                continue
            end
            push!(const_glob_names, sym)
            push!(const_globs, o.__jit__)
        end

# according to user setting, we can have more const global Python objects
        # look from python 'globals'
        py_look = (i -> glob_dep_syms[i]).(left_indices) |> Set
        pragma_const_globals = get(r_options, "const_globals", false) === true
        if !py_is(r_ann, py_none) || pragma_const_globals # no prospective pragmas
            @inbounds for i in left_indices
                k = glob_deps[i]
                haskey(special_globals, k) && continue
                sym = glob_dep_syms[i]

                if py_is(r_ann."get" <| [k], const_pragma) || pragma_const_globals
                    o = r_globals."get" <| [k, py_none]
                    if py_is(o, py_none) # TODO: maybe user wants to mark const glob var valued None?
                        o = pybuiltin(k)
                    end
                    delete!(py_look, sym)
                    push!(const_glob_names, sym)
                    push!(const_globs, o)
                end
            end
        end

# if any other non-const globals, we need to store the python's dictionary('globals()')
        if !isempty(py_look)
            pushfirst!(const_globs, r_globals)
            pushfirst!(const_glob_names, Symbol("python globals"))
        end

# make the function ptr
        const_glob_names = Tuple(const_glob_names)
        const_globs = Tuple(const_globs)
        glob_tuple_type = typeof(const_globs)

        fp = to_jl_fptr(r_codeinfo)
        @when :($_{$_, $args, $body}($_)) = fp begin
            fp = GYARuntimeFn{glob_tuple_type, args, body}(const_globs)
        end
        fp
    end

    function restrain_jl_side_aware!()
        py = pycall(bridge_pop!, PyObject)
        try
            fp = jit_impl(py)
            # native_ptrs[id] = fp
            pycall(bridge_push!, PyObject, fp)
            fp
        catch e
            pyraise(e)
            for (exc, bt) in Base.catch_stack()
                showerror(stdout, exc, bt)
                println()
            end
        end
    end
    restrain_jl_side_aware!
end

function peek(::Val{0}, tp::Tuple{A, B})::A where {A, B}
    tp[1]
end

function peek(::Val{n}, tp::Tuple{A, B})::A where {n, A, B}
    peek(Val(n-1), tp[2])
end

_repr_to_expr(r::Reg) = r.n
_repr_to_expr(r::Const{T}) where T = r.val

function code_gen(ass::A)
    lhs = ass.lhs
    rhs = code_gen(ass.rhs)
    lhs === nothing && return rhs
    :($lhs = $rhs)
end

function code_gen(instr::Instr)
    @match instr begin
        Value(v) => v
        App(f, args) =>
            let
                f = _repr_to_expr(f)
                args = map(_repr_to_expr, args)
                Expr(:call, py_call_func, f, args...)
            end
        Ass(reg, val) =>
            let
                reg = reg.n
                val = _repr_to_expr(val)
                :($reg = $val)
            end
        Load(reg) =>
            let reg = reg.n
                :($reg[])
            end
        Store(reg, val) =>
            let reg = reg.n
                val = _repr_to_expr(val)
                :($reg[] = $val)
            end
        Jmp(label) => :(@goto $label)
        JmpIf(label, cond) =>
            let cond = _repr_to_expr(cond)
                :(if $cond; @goto $label end)
            end
        JmpIfPush(label, cond, leave) =>
            let cond = _repr_to_expr(cond)
                leave = _repr_to_expr(cond)
                :(
                    if $cond
                    __object_stack__ = ($leave, __object_stack__)
                    @goto $label
                    end
                )
            end
        Label(label) => :(@label $label)
        Peek(n) => :($peek($Val($n), __object_stack__))
        Return(val) =>
            let val = _repr_to_expr(val)
                :(return $val)
            end
        Push(val) =>
            let val = _repr_to_expr(val)
                :(__object_stack__ = ($val, __object_stack__))
            end
        Pop() => quote
                let v = __object_stack__[1]
                    __object_stack__ = __object_stack__[2]
                    v
                end
            end
        PyGlob(sym) => :($py_load_global(__persistent_globals__[1], $(Val(sym))))
        JlGlob(:RestrainJIT, name) => :($RestrainJIT.$name)
        UnwindBlock(instrs) =>
            let suite = map(code_gen, instrs)
                :(
                    try
                        $(suite...)
                    catch e
                        __exception_stack__ = (e, __exception_stack__)
                    end
                )
            end
        PopException(false) =>
                :(
                    if $isempty(__exception_stack__)
                        nothing
                    else
                        let e = __exception_stack__[1]
                            __exception_stack__ = __exception_stack__[2]
                            e
                        end
                    end
                )
        PopException(true) =>
            :(
                let e = __exception_stack__[1]
                    __exception_stack__ = __exception_stack__[2]
                    e
                end
            )
        a => error("Unknown instruction: $a")
    end
end
