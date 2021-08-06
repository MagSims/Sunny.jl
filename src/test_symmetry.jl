###################################################### TESTS


function clean_digits(x, n_digits)
    # keep only n_digits past the decimal point
    x = 10.0^-n_digits * round(10.0^n_digits * x)
    # map -0 to 0
    x == -0.0 ? 0.0 : x
end

# Count the number of symmetries with even/odd parity
function count_symmetries(sym)
    n1 = length(filter(x ->  x[2], sym))
    n2 = length(filter(x -> !x[2], sym))
    return n1, n2
end


### FCC lattice, primitive unit cell

lattice = [1 1 0; 1 0 1; 0 1 1]' / 2
positions = [[0., 0, 0]]
species = [1]
cell = Cell(lattice, positions, species)

bonds = all_bonds_for_atom(cell, 1, 2.)

b1 = Bond{3}(1, 1, Vec3([1, 0, 0]))
b2 = Bond{3}(1, 1, Vec3([0, 1, 0]))
is_equivalent_by_symmetry(cell, b1, b2)

cbonds = canonical_bonds(cell, 2.)
cbonds[1]
cbonds[3]

[distance(cell, b) for b=cbonds]

# Populate interactions for a random bond
bond = cbonds[4]
basis = basis_for_symmetry_allowed_couplings(cell, bond)
for x = basis
    display(clean_digits.(x, 4))
end
J = basis' * randn(length(basis))
verify_coupling_matrix(cell, bond, J)
bonds, Js = all_symmetry_related_interactions(cell, bond, J)

for (b, J) = zip(bonds, Js)
    display(b)
    display(J)
end



### Diamond lattice, Spglib inferred symmetry

lattice = [1 1 0; 1 0 1; 0 1 1]' / 2
positions = eachrow([1 1 1; -1 -1 -1] / 8)
species = ["C", "C"]
cell = Cell(lattice, positions, species)

# bonds = all_bonds_for_atom(cell, 1, 2.)

# b1 = Bond(1, 2, @SVector [0, 0, 0])
# b2 = Bond(1, 3, @SVector [0, 0, 0])
# distance(cell, b1)
# distance(cell, b2)

cbonds = canonical_bonds(cell, 2.)
[distance(cell, b) for b=cbonds]


### Diamond lattice, explicit symops

lattice = [1 1 0; 1 0 1; 0 1 1]' / 2
base_positions = [[1, 1, 1] / 8]
species = ["C"]
symops = SymOp[SymOp([1.0 0.0 0.0; 0.0 1.0 0.0; 0.0 0.0 1.0], [0.0, 0.0, -0.0]), SymOp([0.0 0.0 -1.0; -1.0 0.0 0.0; 1.0 1.0 1.0], [0.0, 0.0, 0.5]), SymOp([-1.0 -1.0 -1.0; 0.0 0.0 1.0; 0.0 1.0 0.0], [0.5, 0.0, -0.0]), SymOp([0.0 -1.0 0.0; 1.0 1.0 1.0; -1.0 0.0 0.0], [0.0, 0.5, -0.0]), SymOp([0.0 1.0 0.0; 1.0 0.0 0.0; -1.0 -1.0 -1.0], [0.0, 0.0, 0.5]), SymOp([-1.0 0.0 0.0; 0.0 0.0 -1.0; 0.0 -1.0 0.0], [0.0, 0.0, -0.0]), SymOp([0.0 0.0 1.0; -1.0 -1.0 -1.0; 1.0 0.0 0.0], [0.0, 0.5, -0.0]), SymOp([1.0 1.0 1.0; 0.0 -1.0 0.0; 0.0 0.0 -1.0], [0.5, 0.0, -0.0]), SymOp([0.0 1.0 0.0; 0.0 0.0 1.0; 1.0 0.0 0.0], [0.0, 0.0, -0.0]), SymOp([-1.0 0.0 0.0; 1.0 1.0 1.0; 0.0 0.0 -1.0], [0.0, 0.5, -0.0]), SymOp([0.0 0.0 1.0; 0.0 1.0 0.0; -1.0 -1.0 -1.0], [0.0, 0.0, 0.5]), SymOp([1.0 1.0 1.0; -1.0 0.0 0.0; 0.0 -1.0 0.0], [0.5, 0.0, -0.0]), SymOp([1.0 0.0 0.0; -1.0 -1.0 -1.0; 0.0 1.0 0.0], [0.0, 0.5, -0.0]), SymOp([0.0 0.0 -1.0; 0.0 -1.0 0.0; -1.0 0.0 0.0], [0.0, 0.0, -0.0]), SymOp([-1.0 -1.0 -1.0; 1.0 0.0 0.0; 0.0 0.0 1.0], [0.5, 0.0, -0.0]), SymOp([0.0 -1.0 0.0; 0.0 0.0 -1.0; 1.0 1.0 1.0], [0.0, 0.0, 0.5]), SymOp([0.0 0.0 1.0; 1.0 0.0 0.0; 0.0 1.0 0.0], [0.0, 0.0, -0.0]), SymOp([1.0 1.0 1.0; 0.0 0.0 -1.0; -1.0 0.0 0.0], [0.5, 0.0, -0.0]), SymOp([0.0 1.0 0.0; -1.0 -1.0 -1.0; 0.0 0.0 1.0], [0.0, 0.5, -0.0]), SymOp([-1.0 0.0 0.0; 0.0 -1.0 0.0; 1.0 1.0 1.0], [0.0, 0.0, 0.5]), SymOp([-1.0 -1.0 -1.0; 0.0 1.0 0.0; 1.0 0.0 0.0], [0.5, 0.0, -0.0]), SymOp([0.0 -1.0 0.0; -1.0 0.0 0.0; 0.0 0.0 -1.0], [0.0, 0.0, -0.0]), SymOp([1.0 0.0 0.0; 0.0 0.0 1.0; -1.0 -1.0 -1.0], [0.0, 0.0, 0.5]), SymOp([0.0 0.0 -1.0; 1.0 1.0 1.0; 0.0 -1.0 0.0], [0.0, 0.5, -0.0]), SymOp([-1.0 0.0 0.0; 0.0 -1.0 0.0; 0.0 0.0 -1.0], [0.0, 0.0, -0.0]), SymOp([0.0 0.0 1.0; 1.0 0.0 0.0; -1.0 -1.0 -1.0], [0.0, 0.0, 0.5]), SymOp([1.0 1.0 1.0; 0.0 0.0 -1.0; 0.0 -1.0 0.0], [0.5, 0.0, -0.0]), SymOp([0.0 1.0 0.0; -1.0 -1.0 -1.0; 1.0 0.0 0.0], [0.0, 0.5, -0.0]), SymOp([0.0 -1.0 0.0; -1.0 0.0 0.0; 1.0 1.0 1.0], [0.0, 0.0, 0.5]), SymOp([1.0 0.0 0.0; 0.0 0.0 1.0; 0.0 1.0 0.0], [0.0, 0.0, -0.0]), SymOp([0.0 0.0 -1.0; 1.0 1.0 1.0; -1.0 0.0 0.0], [0.0, 0.5, -0.0]), SymOp([-1.0 -1.0 -1.0; 0.0 1.0 0.0; 0.0 0.0 1.0], [0.5, 0.0, -0.0]), SymOp([0.0 -1.0 0.0; 0.0 0.0 -1.0; -1.0 0.0 0.0], [0.0, 0.0, -0.0]), SymOp([1.0 0.0 0.0; -1.0 -1.0 -1.0; 0.0 0.0 1.0], [0.0, 0.5, -0.0]), SymOp([0.0 0.0 -1.0; 0.0 -1.0 0.0; 1.0 1.0 1.0], [0.0, 0.0, 0.5]), SymOp([-1.0 -1.0 -1.0; 1.0 0.0 0.0; 0.0 1.0 0.0], [0.5, 0.0, -0.0]), SymOp([-1.0 0.0 0.0; 1.0 1.0 1.0; 0.0 -1.0 0.0], [0.0, 0.5, -0.0]), SymOp([0.0 0.0 1.0; 0.0 1.0 0.0; 1.0 0.0 0.0], [0.0, 0.0, -0.0]), SymOp([1.0 1.0 1.0; -1.0 0.0 0.0; 0.0 0.0 -1.0], [0.5, 0.0, -0.0]), SymOp([0.0 1.0 0.0; 0.0 0.0 1.0; -1.0 -1.0 -1.0], [0.0, 0.0, 0.5]), SymOp([0.0 0.0 -1.0; -1.0 0.0 0.0; 0.0 -1.0 0.0], [0.0, 0.0, -0.0]), SymOp([-1.0 -1.0 -1.0; 0.0 0.0 1.0; 1.0 0.0 0.0], [0.5, 0.0, -0.0]), SymOp([0.0 -1.0 0.0; 1.0 1.0 1.0; 0.0 0.0 -1.0], [0.0, 0.5, -0.0]), SymOp([1.0 0.0 0.0; 0.0 1.0 0.0; -1.0 -1.0 -1.0], [0.0, 0.0, 0.5]), SymOp([1.0 1.0 1.0; 0.0 -1.0 0.0; -1.0 0.0 0.0], [0.5, 0.0, -0.0]), SymOp([0.0 1.0 0.0; 1.0 0.0 0.0; 0.0 0.0 1.0], [0.0, 0.0, -0.0]), SymOp([-1.0 0.0 0.0; 0.0 0.0 -1.0; 1.0 1.0 1.0], [0.0, 0.0, 0.5]), SymOp([0.0 0.0 1.0; -1.0 -1.0 -1.0; 0.0 1.0 0.0], [0.0, 0.5, -0.0])]
cell = Cell(lattice, base_positions, species, symops)

cell.positions
cell.species
cell.equiv_atoms
cbonds = canonical_bonds(cell, 2.)


###################################################### USAGE EXAMPLE FOR COLE

# Option 1: Have Spglib infer the symmetry
lattice = [1 1 0; 1 0 1; 0 1 1]' / 2
positions = eachrow([1 1 1; -1 -1 -1] / 8)
species = ["C", "C"]
cell = Cell(lattice, positions, species)

# Option 2: Specify a smaller number of "base_positions" and also supply symops
base_positions = [[1, 1, 1] / 8]
species = ["C"]
symops = SymOp[SymOp([1.0 0.0 0.0; 0.0 1.0 0.0; 0.0 0.0 1.0], [0.0, 0.0, -0.0]), SymOp([0.0 0.0 -1.0; -1.0 0.0 0.0; 1.0 1.0 1.0], [0.0, 0.0, 0.5]), SymOp([-1.0 -1.0 -1.0; 0.0 0.0 1.0; 0.0 1.0 0.0], [0.5, 0.0, -0.0]), SymOp([0.0 -1.0 0.0; 1.0 1.0 1.0; -1.0 0.0 0.0], [0.0, 0.5, -0.0]), SymOp([0.0 1.0 0.0; 1.0 0.0 0.0; -1.0 -1.0 -1.0], [0.0, 0.0, 0.5]), SymOp([-1.0 0.0 0.0; 0.0 0.0 -1.0; 0.0 -1.0 0.0], [0.0, 0.0, -0.0]), SymOp([0.0 0.0 1.0; -1.0 -1.0 -1.0; 1.0 0.0 0.0], [0.0, 0.5, -0.0]), SymOp([1.0 1.0 1.0; 0.0 -1.0 0.0; 0.0 0.0 -1.0], [0.5, 0.0, -0.0]), SymOp([0.0 1.0 0.0; 0.0 0.0 1.0; 1.0 0.0 0.0], [0.0, 0.0, -0.0]), SymOp([-1.0 0.0 0.0; 1.0 1.0 1.0; 0.0 0.0 -1.0], [0.0, 0.5, -0.0]), SymOp([0.0 0.0 1.0; 0.0 1.0 0.0; -1.0 -1.0 -1.0], [0.0, 0.0, 0.5]), SymOp([1.0 1.0 1.0; -1.0 0.0 0.0; 0.0 -1.0 0.0], [0.5, 0.0, -0.0]), SymOp([1.0 0.0 0.0; -1.0 -1.0 -1.0; 0.0 1.0 0.0], [0.0, 0.5, -0.0]), SymOp([0.0 0.0 -1.0; 0.0 -1.0 0.0; -1.0 0.0 0.0], [0.0, 0.0, -0.0]), SymOp([-1.0 -1.0 -1.0; 1.0 0.0 0.0; 0.0 0.0 1.0], [0.5, 0.0, -0.0]), SymOp([0.0 -1.0 0.0; 0.0 0.0 -1.0; 1.0 1.0 1.0], [0.0, 0.0, 0.5]), SymOp([0.0 0.0 1.0; 1.0 0.0 0.0; 0.0 1.0 0.0], [0.0, 0.0, -0.0]), SymOp([1.0 1.0 1.0; 0.0 0.0 -1.0; -1.0 0.0 0.0], [0.5, 0.0, -0.0]), SymOp([0.0 1.0 0.0; -1.0 -1.0 -1.0; 0.0 0.0 1.0], [0.0, 0.5, -0.0]), SymOp([-1.0 0.0 0.0; 0.0 -1.0 0.0; 1.0 1.0 1.0], [0.0, 0.0, 0.5]), SymOp([-1.0 -1.0 -1.0; 0.0 1.0 0.0; 1.0 0.0 0.0], [0.5, 0.0, -0.0]), SymOp([0.0 -1.0 0.0; -1.0 0.0 0.0; 0.0 0.0 -1.0], [0.0, 0.0, -0.0]), SymOp([1.0 0.0 0.0; 0.0 0.0 1.0; -1.0 -1.0 -1.0], [0.0, 0.0, 0.5]), SymOp([0.0 0.0 -1.0; 1.0 1.0 1.0; 0.0 -1.0 0.0], [0.0, 0.5, -0.0]), SymOp([-1.0 0.0 0.0; 0.0 -1.0 0.0; 0.0 0.0 -1.0], [0.0, 0.0, -0.0]), SymOp([0.0 0.0 1.0; 1.0 0.0 0.0; -1.0 -1.0 -1.0], [0.0, 0.0, 0.5]), SymOp([1.0 1.0 1.0; 0.0 0.0 -1.0; 0.0 -1.0 0.0], [0.5, 0.0, -0.0]), SymOp([0.0 1.0 0.0; -1.0 -1.0 -1.0; 1.0 0.0 0.0], [0.0, 0.5, -0.0]), SymOp([0.0 -1.0 0.0; -1.0 0.0 0.0; 1.0 1.0 1.0], [0.0, 0.0, 0.5]), SymOp([1.0 0.0 0.0; 0.0 0.0 1.0; 0.0 1.0 0.0], [0.0, 0.0, -0.0]), SymOp([0.0 0.0 -1.0; 1.0 1.0 1.0; -1.0 0.0 0.0], [0.0, 0.5, -0.0]), SymOp([-1.0 -1.0 -1.0; 0.0 1.0 0.0; 0.0 0.0 1.0], [0.5, 0.0, -0.0]), SymOp([0.0 -1.0 0.0; 0.0 0.0 -1.0; -1.0 0.0 0.0], [0.0, 0.0, -0.0]), SymOp([1.0 0.0 0.0; -1.0 -1.0 -1.0; 0.0 0.0 1.0], [0.0, 0.5, -0.0]), SymOp([0.0 0.0 -1.0; 0.0 -1.0 0.0; 1.0 1.0 1.0], [0.0, 0.0, 0.5]), SymOp([-1.0 -1.0 -1.0; 1.0 0.0 0.0; 0.0 1.0 0.0], [0.5, 0.0, -0.0]), SymOp([-1.0 0.0 0.0; 1.0 1.0 1.0; 0.0 -1.0 0.0], [0.0, 0.5, -0.0]), SymOp([0.0 0.0 1.0; 0.0 1.0 0.0; 1.0 0.0 0.0], [0.0, 0.0, -0.0]), SymOp([1.0 1.0 1.0; -1.0 0.0 0.0; 0.0 0.0 -1.0], [0.5, 0.0, -0.0]), SymOp([0.0 1.0 0.0; 0.0 0.0 1.0; -1.0 -1.0 -1.0], [0.0, 0.0, 0.5]), SymOp([0.0 0.0 -1.0; -1.0 0.0 0.0; 0.0 -1.0 0.0], [0.0, 0.0, -0.0]), SymOp([-1.0 -1.0 -1.0; 0.0 0.0 1.0; 1.0 0.0 0.0], [0.5, 0.0, -0.0]), SymOp([0.0 -1.0 0.0; 1.0 1.0 1.0; 0.0 0.0 -1.0], [0.0, 0.5, -0.0]), SymOp([1.0 0.0 0.0; 0.0 1.0 0.0; -1.0 -1.0 -1.0], [0.0, 0.0, 0.5]), SymOp([1.0 1.0 1.0; 0.0 -1.0 0.0; -1.0 0.0 0.0], [0.5, 0.0, -0.0]), SymOp([0.0 1.0 0.0; 1.0 0.0 0.0; 0.0 0.0 1.0], [0.0, 0.0, -0.0]), SymOp([-1.0 0.0 0.0; 0.0 0.0 -1.0; 1.0 1.0 1.0], [0.0, 0.0, 0.5]), SymOp([0.0 0.0 1.0; -1.0 -1.0 -1.0; 0.0 1.0 0.0], [0.0, 0.5, -0.0])]
cell = Cell(lattice, base_positions, species, symops)

# "Canonical" examples of different bonding types up to distance 2.0
cbonds = canonical_bonds(cell, 2.)

# Get basis for symmetry allowed couplings
bond = cbonds[4] # take a "canonical" example
bond = BondRaw(cell, Bond{3}(1, 1, [0, -1, 0])) # alternatively, specify it manually
basis = basis_for_symmetry_allowed_couplings(cell, bond)
for x = basis
    display(clean_digits.(x, 4))
end

# Build a random interaction matrix as linear combination of basis
J = basis' * randn(length(basis))

# Get list of symmetry equivalent interactions
bonds, Js = all_symmetry_related_interactions(cell, bond, J)
for (b, J) = zip(bonds, Js)
    display(b)
    display(J)
end