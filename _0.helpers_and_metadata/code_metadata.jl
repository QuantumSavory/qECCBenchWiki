module CodeMetadata

using QuantumClifford
using QuantumClifford.ECC
import PyQDecoders
import LDPCDecoders

ENV["HECKE_PRINT_BANNER"] = "false"
import Hecke
using Hecke: group_algebra, GF, abelian_group, gens

const eᵐⁱⁿ = 0.00001
const eᵐᵃˣ = 0.3
const steps = 20

include("hodgepodge/hodgepodge_codes.jl")

using ..Helpers: Helpers, logrange, codelink, PrettyCodeFamilyWrapper

include("code_wrappers.jl")

# Keep tag keys stable for filtering while allowing their display labels to be
# edited independently.
const code_tag_labels = Dict(
    :algebraic => "Algebraic",
    :color_code => "Color code",
    :concatenated => "Concatenated",
    :css => "CSS",
    :custom => "Custom example",
    :generalized_bicycle => "Generalized bicycle",
    :mixed_css => "Mixed CSS",
    :non_css => "Non-CSS",
    :qldpc => "qLDPC",
    :quantum_hamming => "Quantum Hamming",
    :stabilizer => "Stabilizer",
    :surface_code => "Surface code",
    :topological => "Topological",
    :toric_code => "Toric code",
    :two_block_group_algebra => "2BGA",
)

const code_metadata = Dict(
    Gottesman => Dict(
        :family => [(3,),(4,),(5,),(6,)],
        :decoders => [TableDecoder],
        :setups => [CommutationCheckECCSetup],
        :tags => [:stabilizer, :non_css, :quantum_hamming],
        :ecczoo => "https://errorcorrectionzoo.org/c/quantum_hamming",
        :errrange => (eᵐⁱⁿ, eᵐᵃˣ, steps),
        :description => "The `[[2ʲ, 2ʲ - j - 2, 3]]` family of codes, the quantum equivalent of the Hamming codes, capable of correcting any single-qubit error.",
    ),
    Shor9 => Dict(
        :family => [()],
        :decoders => [TableDecoder],
        :setups => [CommutationCheckECCSetup],
        :tags => [:stabilizer, :css, :concatenated],
        :ecczoo => "https://errorcorrectionzoo.org/c/shor_nine",
        :errrange => (eᵐⁱⁿ, eᵐᵃˣ, steps),
        :description => "One of the earliest proof-of-concept error correcting codes, a concatenation of a 3-bit classical repetition code dedicated to protecting against bit-flips, and a 3-bit repetition code dedicated to protecting against phase-flips.",
    ),
    Steane7 => Dict(
        :family => [()],
        :decoders => [TableDecoder],
        :setups => [CommutationCheckECCSetup],
        :tags => [:stabilizer, :css, :quantum_hamming],
        :ecczoo => "https://errorcorrectionzoo.org/c/steane",
        :errrange => (eᵐⁱⁿ, eᵐᵃˣ, steps),
        :description => "One of the earliest proof-of-concept error correcting codes.",
    ),
    Perfect5 => Dict(
        :family => [()],
        :decoders => [TableDecoder],
        :setups => [CommutationCheckECCSetup],
        :tags => [:stabilizer, :non_css],
        :ecczoo => "https://errorcorrectionzoo.org/c/stab_5_1_3",
        :errrange => (eᵐⁱⁿ, eᵐᵃˣ, steps),
        :description => "One of the earliest proof-of-concept error correcting codes. The smallest code that can protect against any single-qubit error. Not a CSS code.",
    ),
    Cleve8 => Dict(
        :family => [()],
        :decoders => [TableDecoder],
        :setups => [CommutationCheckECCSetup],
        :tags => [:stabilizer, :non_css],
        :ecczoo => nothing,
        :errrange => (eᵐⁱⁿ, eᵐᵃˣ, steps),
        :description => "The `[[8,3,3]]` code from Cleve and Gottesman (1997), a convenient pedagogical example when studying how to construct encoding circuits, as it is one of the smallest codes with more than one logical qubit.",
    ),
    Toric => Dict(
        :family => [(3,3), (4,4), (6,6), (8,8), (10,10), (12,12)],
        :decoders => [TableDecoder, PyMatchingDecoder],
        :setups => [CommutationCheckECCSetup],
        :tags => [:stabilizer, :css, :topological, :toric_code],
        :ecczoo => "https://errorcorrectionzoo.org/c/surface",
        :errrange => (eᵐⁱⁿ, eᵐᵃˣ, steps),
        :description => "The famous toric code, the first topological code. Terrible rate, ok-ish distance, awesome locality -- a tradeoff that will turn out to be fundamental to codes with only 2D connectivity.",
    ),
    Surface => Dict(
        :family => [(3,3), (4,4), (6,6), (8,8), (10,10), (12,12)],
        :decoders => [TableDecoder, PyMatchingDecoder],
        :setups => [CommutationCheckECCSetup],
        :tags => [:stabilizer, :css, :topological, :surface_code],
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
        :tags => [:stabilizer, :css, :custom],
        :ecczoo => "",
        :errrange => (eᵐⁱⁿ, eᵐᵃˣ, steps),
        :description => "My friend Nithin made this one. It is here as an example placeholder as we built out the page for this code family.",
        :redundantrows => true,
    ),
    GeneralizedBicycle => Dict(
        :family => [(:C₂₇,), (:C₃₀,), (:C₃₅,), (:C₃₆,), (:C₃₆K₁₀,)],  # Subscripts correspond to the structures of the GB codes in table one [lin2024quantum](@cite) # Note K₁₀ was added because of repeated C₃₆ #
        :decoders => [BitFlipDecoder, PyBeliefPropDecoder],
        :setups => [CommutationCheckECCSetup],
        :tags => [:stabilizer, :css, :qldpc, :algebraic, :generalized_bicycle],
        :ecczoo => "https://errorcorrectionzoo.org/c/generalized_bicycle",
        :errrange => (eᵐⁱⁿ, eᵐᵃˣ, steps),
        :description => "The generalized bicycle codes (GBCs) extend the original bicycle codes by using two commuting square n × n binary matrices A and B, satisfying AB + BA = 0. The code is defined using the generator matrices: G_X = (A, B), G_Z = (Bᵀ, Aᵀ).  See Table I in [Lin and Pryadko (2023)](https://doi.org/10.48550/arXiv.2306.16400) for the subscripts."
    ),
    TwoBlockGroupAlgebra => Dict(
        :family => [(:A1, :B1), (:A2, :B2), (:A3, :B3), (:A4, :B4), (:A5, :B5), (:A6, :B6),  #TODO add some sort of naming convention to this family other than the same thing that the bivariate group has #
                    (:A₇₂, :B₇₂), (:A₁₉₆, :B₁₉₆), (:A₂₈₈, :B₂₈₈), (:A₁₀₈, :B₁₀₈), (:A₃₆₀, :B₃₆₀), (:A₇₅₆, :B₇₅₆)], #TODO the (A,B) cluster goes to the 2BGA group and the other cluster goes to the bivariate group need some way to distinguish those two
        :decoders => [BitFlipDecoder, PyBeliefPropDecoder, PyBeliefPropOSDecoder],
        :setups => [CommutationCheckECCSetup],
        :tags => [:stabilizer, :css, :qldpc, :algebraic, :two_block_group_algebra],
        :ecczoo => "https://errorcorrectionzoo.org/c/2bga",
        :errrange => (eᵐⁱⁿ, eᵐᵃˣ, steps),
        :description => "The two-block group algebra (2BGA) codes extend the $(codelink(GeneralizedBicycle, "generalized bicycle (GB) codes")) by replacing the cyclic group with a general finite group, which can be non-abelian. The stabilizer generator matrices are defined using commuting square matrices derived from elements of a group algebra: H_X = (A, B), H_Z^T = [B; -A] where A and B are commuting ℓ × ℓ matrices, ensuring the CSS orthogonality condition."
    ),
    Triangular488 => Dict(
        :family => [(3,), (5,), (7,), (9,)],
        :decoders => [TableDecoder, PyBeliefPropOSDecoder],
        :setups => [CommutationCheckECCSetup],
        :tags => [:stabilizer, :css, :topological, :color_code],
        :ecczoo => "https://errorcorrectionzoo.org/c/488_color",
        :errrange => (eᵐⁱⁿ, eᵐᵃˣ, steps),
        :description => "The 4.8.8 Square-Octagon color code, defined on a lattice where each qubit sits on a vertex shared by two octagons and a square.  Each shape has an X and Z check on all the qubits on its vertices.  A code of odd distance 𝑑 has (𝑑² - 1)/2 + 𝑑 physical qubits."
    ),
    Triangular666 => Dict(
        :family => [(3,), (5,), (7,), (9,)],
        :decoders => [TableDecoder, PyBeliefPropOSDecoder],
        :setups => [CommutationCheckECCSetup],
        :tags => [:stabilizer, :css, :topological, :color_code],
        :ecczoo => "https://errorcorrectionzoo.org/c/triangular_color",
        :errrange => (eᵐⁱⁿ, eᵐᵃˣ, steps),
        :description => "The 6.6.6 Honeycomb color code, defined on a hexagonal lattice.  Each hexagon has an X and Z check on all the qubits on its vertices.  A code of odd distance 𝑑 has either (3𝑑² + 1)/4 or (3𝑑 - 1)²/4 physical qubits."
    ),
    Concat => Dict(
        :family => [
            (Perfect5(), Perfect5()), 
            (Perfect5(), Steane7()), 
            (Steane7(), Cleve8()), 
            (Toric(2,2), Shor9())
        ],
        :decoders => [TableDecoder],
        :setups => [CommutationCheckECCSetup],
        :tags => [:stabilizer, :concatenated, :mixed_css],
        :ecczoo => "https://errorcorrectionzoo.org/c/quantum_concatenated",
        :errrange => (eᵐⁱⁿ, eᵐᵃˣ, steps),
        :description => "Concatenated codes recursively encode the logical qubits of an outer code using an inner code. For outer code `[[n₁, k₁, d₁]]` and inner code `[[n₂, k₂, d₂]]`, the result is `[[n₁n₂, k₁k₂, d₁d₂]]`."
    )
)

# Fail during site generation instead of silently hiding misspelled or
# contradictory categories from the filter controls.
function validate_code_tags!(metadata)
    allowed_tags = Set(keys(code_tag_labels))
    for (codetype, item) in pairs(metadata)
        haskey(item, :tags) || error("Missing tags for $(typenameof(codetype))")
        tags = item[:tags]
        unknown_tags = setdiff(tags, allowed_tags)
        isempty(unknown_tags) || error("Unknown tags for $(typenameof(codetype)): $(unknown_tags)")
        length(tags) == length(unique(tags)) || error("Duplicate tags for $(typenameof(codetype))")
        (:css in tags && :non_css in tags) && error("Conflicting CSS tags for $(typenameof(codetype))")
    end
end

validate_code_tags!(code_metadata)

end
