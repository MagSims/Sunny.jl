# TODO: Optimize performance, perhaps via `unitary_irrep_for_rotation`. Runtime
# is 1.1s on Sunny 0.7.
@testitem "Magnetization Observables" begin
    using LinearAlgebra

    positions = [[0.,0,0], [0.1, 0.2, 0.3]]
    cryst = Crystal(I(3), positions, 1)
    g1 = [0.8 3.2 5.1; -0.3 0.6 -0.1; 1.0 0. 0.]
    g2 = [1.8 2.2 -3.1; -0.3 2.6 0.1; 1.0 0. 0.3]

    for mode = [:SUN, :dipole]
        moments = [1 => Moment(s=3/2, g=g1), 2 => Moment(s=(mode == :SUN ? 3/2 : 1/2), g=g2)]
        sys = System(cryst, moments, mode)

        set_dipole!(sys, [1,3,2], (1,1,1,1))
        set_dipole!(sys, [3,4,5], (1,1,1,2))

        # Dipole magnetization observables (classical)
        sc = SampledCorrelationsStatic(sys; measure=ssf_custom((q, ssf) -> ssf, sys; apply_g=true))
        add_sample!(sc, sys)
        res = intensities_static(sc, [[0,0,0]])
        corr_mat = res.data[1]

        # Compute magnetization correlation "by hand", averaging over sites
        mag_corr = sum([sys.gs[i] * sys.dipoles[i] * (sys.gs[j] * sys.dipoles[j])' for i = 1:2, j = 1:2]) / Sunny.natoms(cryst)
        mag_corr_time_natoms = mag_corr * Sunny.natoms(cryst)
        @test isapprox(corr_mat, mag_corr_time_natoms)

        # For spin wave theory, check that `apply_g=true` is equivalent to
        # setting `apply_g` and manually contracting spin indices with the
        # g-tensor. This only works when g is equal among sites. TODO: Test with
        # anisotropic g-tensors.
        moments_homog = [1 => Moment(s=3/2, g=g1), 2 => Moment(s=(mode == :SUN ? 3/2 : 1/2), g=g1)]
        sys_homog = System(cryst, moments_homog, mode)

        measure = ssf_custom((q, ssf) -> ssf, sys_homog; apply_g=false)
        swt = SpinWaveTheory(sys_homog; measure)
        res1 = intensities_bands(swt, [[0,0,0]])

        measure = ssf_custom((q, ssf) -> ssf, sys_homog; apply_g=true)
        swt = SpinWaveTheory(sys_homog; measure)
        res2 = intensities_bands(swt, [[0,0,0]])

        @test isapprox(g1 * res1.data[1] * g1', res2.data[1])
        @test isapprox(g1 * res1.data[2] * g1', res2.data[2])
    end
end

@testitem "Available Energies Dirac Identity" begin
     # Create a dummy SampledCorrelations object
    cryst = Sunny.cubic_crystal()
    sys = System(cryst, [1 => Moment(s=1/2, g=2)], :SUN; seed=0)
    dt = 0.08
    sc = SampledCorrelations(sys; dt, energies=range(0.0, 10.0, 100), measure=ssf_perp(sys))

    ωs = Sunny.available_energies(sc; negative_energies=true)
    dts = 0:(sc.dt * sc.measperiod):3
    vals = sum(exp.(im .* ωs .* dts'), dims=1)[:]

    # Verify it made a delta function
    @test vals[1] ≈ length(ωs)
    @test all(abs.(vals[2:end]) .< 1e-12)
end

@testitem "Sum rule with reshaping" begin
    s = 1/2
    g = 2.3
    cryst = Sunny.diamond_crystal()
    sys = System(cryst, [1 => Moment(; s, g)], :SUN; dims=(3, 1, 1), seed=1)
    randomize_spins!(sys)
    sc = SampledCorrelationsStatic(sys; measure=ssf_trace(sys; apply_g=true))
    add_sample!(sc, sys)

    # For the diamond cubic crystal, reciprocal space is periodic over a distance of
    # 4 BZs.
    dims = (4, 4, 4)
    qs = Sunny.available_wave_vectors(sc.parent; bzsize=dims)
    res = intensities_static(sc, qs[:])
    @test sum(res.data) / length(qs) ≈ Sunny.natoms(cryst) * s^2 * g^2

    # Repeat the same calculation for a primitive cell.
    shape = [0 1 1; 1 0 1; 1 1 0] / 2
    sys_prim = reshape_supercell(sys, shape)
    sys_prim = repeat_periodically(sys_prim, (4, 4, 4))
    sc_prim = SampledCorrelationsStatic(sys_prim; measure=ssf_trace(sys_prim; apply_g=true))
    add_sample!(sc_prim, sys_prim)

    qs = Sunny.available_wave_vectors(sc_prim.parent; bzsize=dims)
    res_prim = intensities_static(sc_prim, qs[:])
    @test sum(res_prim.data) / length(qs) ≈ Sunny.natoms(cryst) * s^2 * g^2 / 4 # FIXME!
end

@testitem "Polyatomic sum rule" begin
    sys = System(Sunny.diamond_crystal(), [1 => Moment(s=1/2, g=2)], :SUN; dims=(4, 1, 1), seed=1)
    randomize_spins!(sys)
    sc = SampledCorrelations(sys; dt=0.8, energies=range(0.0, 1.0, 3), measure=ssf_trace(sys; apply_g=true))
    add_sample!(sc, sys)

    sum_rule_ixs = [1, 4, 6]  # indices for zz, yy, xx
    sub_lat_sum_rules = sum(sc.data[sum_rule_ixs,:,:,:,:,:,:], dims=[1,4,5,6,7])[1,:,:,1,1,1,1]

    Δq³ = 1/prod(sys.dims) # Fraction of a BZ
    n_all_ω = size(sc.data, 7)
    # Intensities in sc.data are a density in q, but already integrated over dω
    # bins, and then scaled by n_all_ω. Therefore, we need the factor below to
    # convert the previous sum to an integral.
    sub_lat_sum_rules .*= Δq³ / n_all_ω

    # SU(N) sum rule for S = 1/2:
    # ⟨∑ᵢSᵢ²⟩ = 3/4 on every site, but because we're classical, we
    # instead compute ∑ᵢ⟨Sᵢ⟩² = (1/2)^2 = 1/4 since the ⟨Sᵢ⟩ form a vector with
    # length (1/2). Since the actual observables are the magnetization M = gS, we
    # need to include the g factor. This is the equal-space-and-time correlation value:
    gS_squared = (2 * 1/2)^2

    expected_sum = gS_squared
    # This sum rule should hold for each sublattice, independently, and only
    # need to be taken over a single BZ (which is what sc.data contains) to hold:
    [sub_lat_sum_rules[i,i] for i in 1:Sunny.natoms(sc.crystal)] ≈ expected_sum * ones(Sunny.natoms(sc.crystal))

    # The polyatomic sum rule demands going out 4 BZ's for the diamond crystal
    # since there is an atom at relative position [1/4, 1/4, 1/4]. It also
    # requires integrating over the full sampling frequency range, in this
    # case by going over both positive and negative energies.
    nbzs = (4, 4, 4)
    qs = Sunny.available_wave_vectors(sc; bzsize=nbzs)
    res = intensities(sc, qs[:]; energies=:available_with_negative, kT=nothing)
    calculated_sum = sum(res.data) * Δq³ * sc.Δω

    # This tests that `negative_energies = true` spans exactly one sampling frequency
    expected_multi_BZ_sum = gS_squared * prod(nbzs) # ⟨S⋅S⟩
    expected_multi_BZ_sum_times_natoms = expected_multi_BZ_sum * Sunny.natoms(sc.crystal) # Nₐ×⟨S⋅S⟩
    @test calculated_sum ≈ expected_multi_BZ_sum_times_natoms
end
