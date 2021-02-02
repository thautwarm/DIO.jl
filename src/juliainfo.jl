# moderate modification and adaption to
# https://github.com/JuliaPy/pyjulia/blob/87c669e2729f9743fe2ab39320ec9b91c9300a96/src/julia/juliainfo.jl
export PyJulia_INFO
import Libdl
import Pkg

function PyJulia_INFO()
    println(VERSION)
    println(VERSION.major)
    println(VERSION.minor)
    println(VERSION.patch)
    # binddir
    println(Base.Sys.BINDIR)
    # libjulia_path
    println(Libdl.dlpath(string("lib", splitext(Base.julia_exename())[1])))
    # sysimage
    println(unsafe_string(Base.JLOptions().image_file))
end
