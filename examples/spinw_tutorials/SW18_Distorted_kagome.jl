# # SW18 - Distorted kagome
#
# This is a Sunny port of [SpinW Tutorial
# 18](https://spinw.org/tutorials/19tutorial), originally authored by Goran
# Nilsen and Sandor Toth. This tutorial illustrates Sunny's support for studying
# incommensurate, single-``Q`` structures. The test system is KCu₃As₂O₇(OD)₃.
# The Cu ions are arranged in a distorted kagome lattice, and exhibit helical
# magnetic order, as described in [G. J. Nilsen, et al., Phys. Rev. B **89**,
# 140412 (2014)](https://doi.org/10.1103/PhysRevB.89.140412).

using Sunny, GLMakie

# Build the distorted kagome crystal, with spacegroup 12.

units = Units(:meV)
latvecs = lattice_vectors(10.2, 5.94, 7.81, 90, 117.7, 90)
positions = [[0, 0, 0], [1/4, 1/4, 0]]
types = ["Cu1", "Cu2"]
cryst = Crystal(latvecs, positions, 12; types, setting="b1")
view_crystal(cryst)

# Define the interactions.

spininfos = [SpinInfo(1, S=1/2, g=2), SpinInfo(3, S=1/2, g=2)]
sys = System(cryst, (1,1,1), spininfos, :dipole, seed=0)
J   = -2
Jp  = -1
Jab = 0.75
Ja  = -J/.66 - Jab
Jip = 0.01
set_exchange!(sys, J, Bond(1, 3, [0, 0, 0]))
set_exchange!(sys, Jp, Bond(3, 5, [0, 0, 0]))
set_exchange!(sys, Ja, Bond(3, 4, [0, 0, 0]))
set_exchange!(sys, Jab, Bond(1, 2, [0, 0, 0]))
set_exchange!(sys, Jip, Bond(3, 4, [0, 0, 1]))

# Optimize the generalized spiral structure. This will determine the propagation
# wavevector `k`, as well as spin values within the unit cell. One must provide
# a fixed `axis` perpendicular to the polarization plane. For this system, all
# interactions are rotationally invariant, and the `axis` vector is arbitrary.
# In other cases, a good `axis` will frequently be determined from symmetry
# considerations.

axis = [0, 0, 1]
randomize_spins!(sys)
k = spiral_minimize_energy!(sys, axis; k_guess=randn(3))
plot_spins(sys; dims=2)

# If successful, the optimization process will find one two possible
# wavevectors, ±k_ref, with opposite chiralities.

k_ref = [0.785902495, 0.0, 0.107048756]
k_ref_alt = [1, 0, 1] - k_ref
@assert isapprox(k, k_ref; atol=1e-6) || isapprox(k, k_ref_alt; atol=1e-6)
@assert spiral_energy_per_site(sys; k, axis) ≈ -0.78338383838

# Check the energy with a real-space calculation using a large magnetic cell.
# First, we must determine a lattice size for which k becomes approximately
# commensurate. 

suggest_magnetic_supercell([k_ref]; tol=1e-3)

# Resize the system as suggested, and perform a real-space calculation. Working
# with a commensurate wavevector increases the energy slightly. The precise
# value might vary from run-to-run due to trapping in a local energy minimum.

new_shape = [14 0 1; 0 1 0; 0 0 2]
sys2 = reshape_supercell(sys, new_shape)
randomize_spins!(sys2)
minimize_energy!(sys2)
energy_per_site(sys2) # < -0.7834 meV

# Define a path in q-space

qs = [[0,0,0], [1,0,0]]
path = q_space_path(cryst, qs, 512)

# Calculate intensities for the incommensurate single-k ordering wavevector
# using [`SpiralSpinWaveTheory`](@ref). It is necessary to provide the original
# `sys`, consisting of a single chemical cell.

measure = ssf_perp(sys; apply_g=false)
swt = SpiralSpinWaveTheory(sys; measure, k, axis)
res = intensities_bands(swt, path)
plot_intensities(res; units)

# Plot the powder-averaged intensities

radii = range(0, 2, 100) # (1/Å)
energies = range(0, 6, 200)
kernel = Sunny.gaussian2(fwhm=0.05)
res = powder_average(cryst, radii, 200) do qs
    intensities(swt, qs; energies, kernel)
end
plot_intensities(res; units)
