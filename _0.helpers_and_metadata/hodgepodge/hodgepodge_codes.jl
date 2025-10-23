# Codes that do not have a proper construction algorithm available, rather are provided in "hardcoded" fashion, because a friend thought they are of use.

module Hodgepodge

using QuantumClifford
using QuantumClifford.ECC
import QuantumClifford.ECC: parity_checks, iscss
import QECCore: AbstractECC, parity_matrix_x, parity_matrix_z

abstract type HodgepodgeCode <: QuantumClifford.ECC.AbstractECC end

function load_nithin(filename)
    fid = open(filename)
    col, row = parse.(Int, split(readline(fid)))
    H = zeros(Bool, row, col)
    for c in 1:col
        idx = parse.(Int, split(readline(fid)))
        H[idx[2:end],c] .= true
    end
    close(fid)
    H
end


struct NithinCode <: HodgepodgeCode
end

_nithincode() = CSS(load_nithin(joinpath((@__DIR__), "nithin/QC_dv4dc8_psto_29_12_2_4_hx")), load_nithin((@__DIR__)*"/nithin/QC_dv4dc8_psto_29_12_2_4_hz"))
parity_checks(::NithinCode) = parity_checks(_nithincode())
parity_matrix_x(::NithinCode) = parity_matrix_x(_nithincode())
parity_matrix_z(::NithinCode) = parity_matrix_z(_nithincode())
iscss(::NithinCode) = true

end
