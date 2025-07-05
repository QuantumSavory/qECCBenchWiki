module Helpers

struct CircBuffer
    buffer
end

Base.getindex(cb::CircBuffer,i) = cb.buffer[rem(i-1,length(cb.buffer))+1]

logrange(eᵐⁱⁿ, eᵐᵃˣ, steps) = exp.(range(log(eᵐⁱⁿ), log(eᵐᵃˣ), length=steps))

function choppad(s, n)
    chopn = max(0,length(s)-n+1)
    chopped = chop(s, tail=chopn)
    withellipsis = chopn>0 ? chopped*"…" : chopped
    rpad(withellipsis,n)
end

typenameof(t) = nameof(t)

function instancenameof(x)
    t = typeof(x)
    str = string(nameof(t))*"("
    nf = nfields(x)
    nb = sizeof(x)
    if nf != 0 || nb == 0
        for i in 1:nf
            f = fieldname(t, i)
            str *= string(getfield(x, i))
            if i < nf
                str *= ", "
            end
        end
    end
    str *= ")"
    return str
end

function skipredundantprefix(x)
    x = string(x)
    return chopprefix(chopprefix(x, "QuantumClifford.ECC."), "Main.")
end

function skipredundantsuffix(x)
    x = string(x)
    xs = split(x, "(")
    xs = [
        chopsuffix(chopsuffix(x, "Decoder"), "ECCSetup")
        for x in xs
    ]
    return join(xs, "(")
end

function skipredundantfix(x)
    x = string(x)
    return skipredundantsuffix(skipredundantprefix(x))
end


"""Provides nice name-printing for functions that need to be called with extra keyword arguments (see the examples of use in code_metadata)"""
struct KWFun
    f
    kwargs
end

function (f::KWFun)(c)
    f.f(c; f.kwargs...)
end

typenameof(t::KWFun) = nameof(t.f)

function skipredundantfix(x::KWFun)
    f = skipredundantfix(x.f)
    return "$f($(join(["$k=$v" for (k,v) in pairs(x.kwargs)], ", ")))"
end

function Base.string(x::KWFun)
    f = string(x.f)
    return "$f(_;$(join(["$k=$v" for (k,v) in pairs(x.kwargs)], ", ")))"
end


struct PrettyCodeFamilyWrapper
    code_name::Symbol
    code_generator # a function
    local_variables_dict # a dictionary of symbols to variables
end

function (wrapper::PrettyCodeFamilyWrapper)(args...)
    return PrettyCodeWrapper(wrapper, args)
end

"A wrapper for code constructors mean only to provide neater printing, so that we can more easily show everything in the wiki"
struct PrettyCodeWrapper
    code_family::PrettyCodeFamilyWrapper
    code_args
    code_cache
end
function PrettyCodeWrapper(code_family, code_args)
    symargs = code_args
    args = [code_family.local_variables_dict[a] for a in symargs]
    code = code_family.code_generator(args...)
    PrettyCodeWrapper(code_family, code_args, code)
end

typenameof(c::PrettyCodeFamilyWrapper) = c.code_name
instancenameof(c::PrettyCodeWrapper) = "$(c.code_family.code_name)($(c.code_args...))"

import QuantumClifford
import QuantumClifford.ECC
import QECCore
function QuantumClifford.ECC.parity_checks(c::PrettyCodeWrapper)
    QuantumClifford.ECC.parity_checks(c.code_cache)
end
function QuantumClifford.ECC.parity_matrix_x(c::PrettyCodeWrapper)
    QuantumClifford.ECC.parity_matrix_x(c.code_cache)
end
function QuantumClifford.ECC.parity_matrix_z(c::PrettyCodeWrapper)
    QuantumClifford.ECC.parity_matrix_z(c.code_cache)
end
function QuantumClifford.ECC.faults_matrix(c::PrettyCodeWrapper)
    QuantumClifford.ECC.faults_matrix(c.code_cache)
end
function QuantumClifford.ECC.iscss(c::PrettyCodeWrapper)
    QuantumClifford.ECC.iscss(c.code_cache)
end
function QuantumClifford.ECC.iscss(c::PrettyCodeWrapper)
    QuantumClifford.ECC.iscss(c.code_cache)
end
function QuantumClifford.ECC.code_n(c::PrettyCodeWrapper)
    QuantumClifford.ECC.code_n(c.code_cache)
end

codelink(code_name::Symbol, text=code_name) = "[$text](/codes/$code_name)"
codelink(code_type, text=typenameof(code_type)) = codelink(typenameof(code_type), text)

end
