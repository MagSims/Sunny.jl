# # 7. Long-range dipole interactions
#
# This example demonstrates Sunny's ability to incorporate long-range dipole
# interactions using Ewald summation. The calculation reproduces previous
# results in  [Del Maestro and Gingras, J. Phys.: Cond. Matter, **16**, 3339
# (2004)](https://arxiv.org/abs/cond-mat/0403494).

using Sunny, GLMakie

# Create a Pyrochlore crystal from spacegroup 227.

units = Units(:K)
latvecs = lattice_vectors(10.19, 10.19, 10.19, 90, 90, 90)
positions = [[0, 0, 0]]
cryst = Crystal(latvecs, positions, 227, setting="2")

sys = System(cryst, (1, 1, 1), [SpinInfo(1, S=7/2, g=2)], :dipole, seed=2)
J1 = 0.304 # (K)
set_exchange!(sys, J1, Bond(1, 2, [0,0,0]))

# Reshape to the primitive cell with four atoms. To facilitate indexing, the
# function [`position_to_site`](@ref) accepts positions with respect to the
# original (cubic) cell.

shape = [1/2 1/2 0; 0 1/2 1/2; 1/2 0 1/2]
sys_prim = reshape_supercell(sys, shape)

set_dipole!(sys_prim, [+1, -1, 0], position_to_site(sys_prim, [0, 0, 0]))
set_dipole!(sys_prim, [-1, +1, 0], position_to_site(sys_prim, [1/4, 1/4, 0]))
set_dipole!(sys_prim, [+1, +1, 0], position_to_site(sys_prim, [1/4, 0, 1/4]))
set_dipole!(sys_prim, [-1, -1, 0], position_to_site(sys_prim, [0, 1/4, 1/4]))

plot_spins(sys_prim; ghost_radius=8, color=[:red, :blue, :yellow, :purple])

# Calculate dispersions with and without long-range dipole interactions. The
# high-symmetry k-points are specified with respect to the conventional cubic
# cell.

qs = [[0,0,0], [0,1,0], [1,1/2,0], [1/2,1/2,1/2], [3/4,3/4,0], [0,0,0]]
labels = ["Γ", "X", "W", "L", "K", "Γ"]
path = q_space_path(cryst, qs, 400; labels)

corrspec = ssf_trace(sys_prim)
swt = SpinWaveTheory(sys_prim; corrspec)
res1 = intensities_bands(swt, path)

sys_prim_dd = clone_system(sys_prim)
enable_dipole_dipole!(sys_prim_dd, units.vacuum_permeability)
swt = SpinWaveTheory(sys_prim_dd; corrspec)
res2 = intensities_bands(swt, path)

sys_prim_tdd = clone_system(sys_prim)
modify_exchange_with_truncated_dipole_dipole!(sys_prim_tdd, 5.0, units.vacuum_permeability)
swt = SpinWaveTheory(sys_prim_tdd; corrspec)
res3 = intensities_bands(swt, path)

# Create a panel that qualitatively reproduces Fig. 2 of [Del Maestro and
# Gingras](https://arxiv.org/abs/cond-mat/0403494). That previous work had two
# errors: The energy scales are too small by a factor of 2 and, in addition,
# slight corrections are needed for the third dispersion band.

fig = Figure(size=(768, 300))
plot_intensities!(fig[1, 1], res1; units)
ax = plot_intensities!(fig[1, 2], res2; units)
for c in eachrow(res3.disp)
    lines!(ax, eachindex(c), c; linestyle=:dash, color=:black)
end
fig
