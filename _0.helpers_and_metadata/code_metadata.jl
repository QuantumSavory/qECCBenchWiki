module CodeMetadata

using QuantumClifford
using QuantumClifford.ECC
import PyQDecoders
import LDPCDecoders
import Hecke
using Hecke: group_algebra, GF, abelian_group, gens

const eᵐⁱⁿ = 0.00001
const eᵐᵃˣ = 0.3
const steps = 20

# Structures from  lin2024quantum #

C₂₇ = ([0 ,  1,  3,  7], [0 ,  1, 12, 19], 27)
C₃₀ = ([0 , 10,  6, 13], [0 , 25, 16, 12], 30)
C₃₅ = ([0 , 15, 16, 18], [0 ,  1, 24, 27], 35)
C₃₆ = ([0 ,  9, 28, 31], [0 ,  1, 21, 34], 36)
C₃₆K₁₀ = ([0 ,  9, 28, 13], [0 ,  1,  3, 22], 36)

# Constants used for the 2BGA codes #
# m = 4
GA = group_algebra(GF(2), abelian_group([4,2]))
x, s = gens(GA)
A1 = 1 + x
B1 = 1 + x + s + x^2 + s*x + s*x^3

# m = 6
GA = group_algebra(GF(2), abelian_group([6,2]))
x, s = gens(GA)
A2 = 1 + x
B2 = 1 + x^3 + s + x^4 + x^2 + s*x

# m = 8
GA = group_algebra(GF(2), abelian_group([8,2]))
x, s = gens(GA)
A3 = 1 + x^6
B3 = 1 + s*x^7 + s*x^4 + x^6 + s*x^5 + s*x^2

# m = 10
GA = group_algebra(GF(2), abelian_group([10,2]))
x, s = gens(GA)
A4 = 1 + x
B4 = 1 + x^5 + x^6 + s*x^6 + x^7 + s*x^3

# m = 12
GA = group_algebra(GF(2), abelian_group([12,2]))
x, s = gens(GA)
A5 = 1 + s*x^10
B5 = 1 + x^3 + s*x^6 + x^4 + x^7 + x^8

# m = 14
GA = group_algebra(GF(2), abelian_group([14,2]))
x, s = gens(GA)
A6 = 1 + x^8
B6 = 1 + x^7 + s + x^8 + x^9 + s*x^4

# Working variables for the bivariate_bicycle_group
# [[72, 12, 6]]
l=6; m=6
GA = group_algebra(GF(2), abelian_group([l, m]))
x, y = gens(GA)
A₇₂ = x^3 + y + y^2
B₇₂ = y^3 + x + x^2

# [[196, 12, 8]]
l=14; m=7
GA = group_algebra(GF(2), abelian_group([l, m]))
x, y = gens(GA)
A₁₉₆ = x^6 + y^5 + y^6
B₁₉₆ = 1   + x^4 + x^13

# [[108, 8, 10]]
l=9; m=6
GA = group_algebra(GF(2), abelian_group([l, m]))
x, y = gens(GA)
A₁₀₈ = x^3 + y + y^2
B₁₀₈ = y^3 + x + x^2

# [[288, 12, 12]]
l=12; m=12
GA = group_algebra(GF(2), abelian_group([l, m]))
x, y = gens(GA)
A₂₈₈ = x^3 + y^2 + y^7
B₂₈₈ = y^3 + x   + x^2

# [[360, 12, ≤ 24]]
l=30; m=6
GA = group_algebra(GF(2), abelian_group([l, m]))
x, y = gens(GA)
A₃₆₀ = x^9 + y    + y^2
B₃₆₀ = y^3 + x^25 + x^26

# [[756, 16, ≤ 34]]
l=21; m=18
GA = group_algebra(GF(2), abelian_group([l, m]))
x, y = gens(GA)
A₇₅₆ = x^3 + y^10 + y^17
B₇₅₆ = y^5 + x^3  + x^19



include("helpers.jl")
include("hodgepodge/hodgepodge_codes.jl")

using .Helpers: logrange

const code_metadata = Dict(
    Gottesman => Dict(
        :family => [(3,),(4,),(5,),(6,)],
        :decoders => [TableDecoder],
        :setups => [CommutationCheckECCSetup],
        :ecczoo => "https://errorcorrectionzoo.org/c/quantum_hamming",
        :errrange => (eᵐⁱⁿ, eᵐᵃˣ, steps),
        :description => "The `[[2ʲ, 2ʲ - j - 2, 3]]` family of codes, the quantum equivalent of the Hamming codes, capable of correcting any single-qubit error.",
    ),
    Shor9 => Dict(
        :family => [()],
        :decoders => [TableDecoder],
        :setups => [CommutationCheckECCSetup],
        :ecczoo => "https://errorcorrectionzoo.org/c/shor_nine",
        :errrange => (eᵐⁱⁿ, eᵐᵃˣ, steps),
        :description => "One of the earliest proof-of-concept error correcting codes, a concatenation of a 3-bit classical repetition code dedicated to protecting against bit-flips, and a 3-bit repetition code dedicated to protecting against phase-flips.",
    ),
    Steane7 => Dict(
        :family => [()],
        :decoders => [TableDecoder],
        :setups => [CommutationCheckECCSetup],
        :ecczoo => "https://errorcorrectionzoo.org/c/steane",
        :errrange => (eᵐⁱⁿ, eᵐᵃˣ, steps),
        :description => "One of the earliest proof-of-concept error correcting codes.",
    ),
    Perfect5 => Dict(
        :family => [()],
        :decoders => [TableDecoder],
        :setups => [CommutationCheckECCSetup],
        :ecczoo => "https://errorcorrectionzoo.org/c/stab_5_1_3",
        :errrange => (eᵐⁱⁿ, eᵐᵃˣ, steps),
        :description => "One of the earliest proof-of-concept error correcting codes. The smallest code that can protect against any single-qubit error. Not a CSS code.",
    ),
    Cleve8 => Dict(
        :family => [()],
        :decoders => [TableDecoder],
        :setups => [CommutationCheckECCSetup],
        :ecczoo => nothing,
        :errrange => (eᵐⁱⁿ, eᵐᵃˣ, steps),
        :description => "The `[[8,3,3]]` code from Cleve and Gottesman (1997), a convenient pedagogical example when studying how to construct encoding circuits, as it is one of the smallest codes with more than one logical qubit.",
    ),
    Toric => Dict(
        :family => [(3,3), (4,4), (6,6), (8,8), (10,10), (12,12)],
        :decoders => [TableDecoder, PyMatchingDecoder],
        :setups => [CommutationCheckECCSetup],
        :ecczoo => "https://errorcorrectionzoo.org/c/surface",
        :errrange => (eᵐⁱⁿ, eᵐᵃˣ, steps),
        :description => "The famous toric code, the first topological code. Terrible rate, ok-ish distance, awesome locality -- a tradeoff that will turn out to be fundamental to codes with only 2D connectivity.",
    ),
    Surface => Dict(
        :family => [(3,3), (4,4), (6,6), (8,8), (10,10), (12,12)],
        :decoders => [TableDecoder, PyMatchingDecoder],
        :setups => [CommutationCheckECCSetup],
        :ecczoo => "https://errorcorrectionzoo.org/c/surface",
        :errrange => (eᵐⁱⁿ, eᵐᵃˣ, steps),
        :description => "An open-boundary version of the famous toric code, the first topological code. Terrible rate, ok-ish distance, awesome locality -- a tradeoff that will turn out to be fundamental to codes with only 2D connectivity.",
    ),
    Hodgepodge.NithinCode => Dict(
        :family => [()],
        :decoders => [TableDecoder,
                      BeliefPropDecoder,
                      BitFlipDecoder,
                      Helpers.KWFun(PyBeliefPropOSDecoder, (;bpmethod=:productsum, osdmethod=:zeroorder)),
                      Helpers.KWFun(PyBeliefPropOSDecoder, (;bpmethod=:productsum, osdmethod=:exhaustive, osdorder=5)),
                      Helpers.KWFun(PyBeliefPropOSDecoder, (;bpmethod=:productsum, osdmethod=:combinationsweep, osdorder=10)),
        ],
        :setups => [CommutationCheckECCSetup],
        :ecczoo => "",
        :errrange => (eᵐⁱⁿ, eᵐᵃˣ, steps),
        :description => "My friend Nithin made this one. It is here as an example placeholder as we built out the page for this code family.",
        :redundantrows => true,
    ),
    # Put in the 2 block group-algebra codes and generalized_bicycle_codes #
    # Families are from the test files for the individual codes #
    generalized_bicycle_codes => Dict(
        :family => [C₂₇, C₃₀, C₃₅, C₃₆, C₃₆K₁₀],  # Subscripts correspond to the structures of the GB codes in table one [lin2024quantum](@cite) # Note K₁₀ was added because of repeated C₃₆ # 
        :decoders => [BitFlipDecoder, PyBeliefPropDecoder],
        :setups => [CommutationCheckECCSetup],
        :ecczoo => "https://errorcorrectionzoo.org/c/generalized_bicycle",
        :errrange => (eᵐⁱⁿ, eᵐᵃˣ, steps),
        :description => "The generalized bicycle codes (GBCs) extend the original bicycle codes by using two commuting square n × n binary matrices A and B, satisfying AB + BA = 0. The code is defined using the generator matrices: G_X = (A, B), G_Z = (Bᵀ, Aᵀ)"
    ),

    two_block_group_algebra_codes => Dict(
        :family => [(A1, B1), (A2, B2), (A3, B3), (A4, B4), (A5, B5), (A6, B6),  #TODO add some sort of naming convention to this family other than the same thing that the bivariate group has #
                    (A₇₂, B₇₂), (A₁₉₆, B₁₉₆), (A₂₈₈, B₂₈₈), (A₁₀₈, B₁₀₈), (A₃₆₀, B₃₆₀), (A₇₅₆, B₇₅₆)], #TODO the (A,B) cluster goes to the 2BGA group and the other cluster goes to the bivariate group need some way to distinguish those two
        :decoders => [BitFlipDecoder, PyBeliefPropDecoder, PyBeliefPropOSDecoder],
        :setups => [CommutationCheckECCSetup],
        :ecczoo => "https://errorcorrectionzoo.org/c/2bga",
        :errrange => (eᵐⁱⁿ, eᵐᵃˣ, steps),
        :description => "The two-block group algebra (2BGA) codes extend the generalized bicycle (GB) codes by replacing the cyclic group with a general finite group, which can be non-abelian. The stabilizer generator matrices are defined using commuting square matrices derived from elements of a group algebra: H_X = (A, B), H_Z^T = [B; -A] where A and B are commuting ℓ × ℓ matrices, ensuring the CSS orthogonality condition."
    )

)

end
