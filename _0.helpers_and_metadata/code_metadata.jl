module CodeMetadata

using QuantumClifford
using QuantumClifford.ECC
import Hecke
import PyQDecoders
import LDPCDecoders

const eᵐⁱⁿ = 0.00001
const eᵐᵃˣ = 0.3
const steps = 20

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
    haah_cubic_codes => Dict(
        :family => [([0, 15, 20, 28, 66], [0, 58, 59, 100, 121], 6)],
        :decoders => [TableDecoder],
        :setups => [CommutationCheckECCSetup],
        :ecczoo => "https://errorcorrectionzoo.org/c/haah_cubic",
        :errrange => (eᵐⁱⁿ, eᵐᵃˣ, steps),
        :description => "The Haah cubic code to protect against simultaneous independent Pauli errors on different sites."
    ),
)

end
