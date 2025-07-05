# Structures from lin2024quantum for use with generalized_bicycle_codes

GeneralizedBicycle = PrettyCodeFamilyWrapper(
    :GeneralizedBicycle,
    splat(generalized_bicycle_codes),
    Dict(
        :C₂₇ => ([0 ,  1,  3,  7], [0 ,  1, 12, 19], 27),
        :C₃₀ => ([0 , 10,  6, 13], [0 , 25, 16, 12], 30),
        :C₃₅ => ([0 , 15, 16, 18], [0 ,  1, 24, 27], 35),
        :C₃₆ => ([0 ,  9, 28, 31], [0 ,  1, 21, 34], 36),
        :C₃₆K₁₀ => ([0 ,  9, 28, 13], [0 ,  1,  3, 22], 36),
    )
)


# Constants used for the 2BGA codes
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

TwoBlockGroupAlgebra = PrettyCodeFamilyWrapper(
    :TwoBlockGroupAlgebra,
    two_block_group_algebra_codes,
    Dict(
        :A1 => A1,
        :A2 => A2,
        :A3 => A3,
        :A4 => A4,
        :A5 => A5,
        :A6 => A6,
        :B1 => B1,
        :B2 => B2,
        :B3 => B3,
        :B4 => B4,
        :B5 => B5,
        :B6 => B6,
        :A₇₂ => A₇₂,
        :B₇₂ => B₇₂,
        :A₁₉₆ => A₁₉₆,
        :B₁₉₆ => B₁₉₆,
        :A₂₈₈ => A₂₈₈,
        :B₂₈₈ => B₂₈₈,
        :A₁₀₈ => A₁₀₈,
        :B₁₀₈ => B₁₀₈,
        :A₃₆₀ => A₃₆₀,
        :B₃₆₀ => B₃₆₀,
        :A₇₅₆ => A₇₅₆,
        :B₇₅₆ => B₇₅₆
    )
)
