module CodeMetadata

using QuantumClifford
using QuantumClifford.ECC
#import PyQDecoders
import LDPCDecoders
import Hecke
using Hecke: group_algebra, GF, abelian_group, gens

const eᵐⁱⁿ = 0.00001
const eᵐᵃˣ = 0.3
const steps = 20


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
        :decoders => [TableDecoder],
        :setups => [CommutationCheckECCSetup],
        :ecczoo => "https://errorcorrectionzoo.org/c/surface",
        :errrange => (eᵐⁱⁿ, eᵐᵃˣ, steps),
        :description => "The famous toric code, the first topological code. Terrible rate, ok-ish distance, awesome locality -- a tradeoff that will turn out to be fundamental to codes with only 2D connectivity.",
    ),
    Surface => Dict(
        :family => [(3,3), (4,4), (6,6), (8,8), (10,10), (12,12)],
        :decoders => [TableDecoder],
        :setups => [CommutationCheckECCSetup],
        :ecczoo => "https://errorcorrectionzoo.org/c/surface",
        :errrange => (eᵐⁱⁿ, eᵐᵃˣ, steps),
        :description => "An open-boundary version of the famous toric code, the first topological code. Terrible rate, ok-ish distance, awesome locality -- a tradeoff that will turn out to be fundamental to codes with only 2D connectivity.",
    ),
    Hodgepodge.NithinCode => Dict(
        :family => [()],
        :decoders => [TableDecoder,
                      BeliefPropDecoder,
                      BitFlipDecoder
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
        :family => [([0 , 15, 16, 18], [0 ,  1, 24, 27], 35), 
                    ([0 , 15, 16, 18], [0 ,  1, 24, 27], 35), 
                    ([0 ,  1,  3,  7], [0 ,  1, 12, 19], 27), 
                    ([0 ,  1,  3,  7], [0 ,  1, 12, 19], 27), 
                    ([0 , 10,  6, 13], [0 , 25, 16, 12], 30), 
                    ([0 , 10,  6, 13], [0 , 25, 16, 12], 30)],
        :decoders => [BitFlipDecoder, BeliefPropDecoder],
        :setups => [CommutationCheckECCSetup],
        :ecczoo => "https://errorcorrectionzoo.org/c/generalized_bicycle",
        :errrange => (eᵐⁱⁿ, eᵐᵃˣ, steps),
        :description => "The generalized bicycle codes (GBCs) extend the original bicycle codes by using two commuting square n × n binary matrices A and B, satisfying AB + BA = 0. This ensures the stabilizer conditions required for quantum error correction. The code is defined using the generator matrices: G_X = (A, B), G_Z = (Bᵀ, Aᵀ)"
    ),

    two_block_group_algebra_codes => Dict(
        :family => [(A1, B1), (A2, B2), (A3, B3), (A4, B4), (A5, B5), (A6, B6)],
        :decoders => [BitFlipDecoder, BeliefPropDecoder],
        :setups => [CommutationCheckECCSetup],
        :ecczoo => "https://errorcorrectionzoo.org/c/2bga",
        :errrange => (eᵐⁱⁿ, eᵐᵃˣ, steps),
        :description => "The two-block group algebra (2BGA) codes extend the generalized bicycle (GB) codes by replacing the cyclic group with a general finite group, which can be non-abelian. This generalization allows for a richer structure and potentially improved error-correcting properties. The stabilizer generator matrices are defined using commuting square matrices derived from elements of a group algebra: H_X = (A, B), H_Z^T = [B; -A] where A and B are commuting ℓ × ℓ matrices, ensuring the CSS orthogonality condition."
    )

    
)

end
