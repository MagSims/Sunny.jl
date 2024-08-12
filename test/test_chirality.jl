@testitem "Spin precession handedness" begin
    using LinearAlgebra

    crystal = Crystal(lattice_vectors(1, 1, 1, 90, 90, 90), [[0, 0, 0]])
    sys_dip = System(crystal, (1, 1, 1), [SpinInfo(1; S=1, g=2)], :dipole)
    sys_sun = System(crystal, (1, 1, 1), [SpinInfo(1; S=1, g=2)], :SUN)

    B = [0, 0, 1]
    set_field!(sys_dip, B)
    set_field!(sys_sun, B)

    ic = [1/√2, 0, 1/√2]
    set_dipole!(sys_dip, ic, (1, 1, 1, 1))
    set_dipole!(sys_sun, ic, (1, 1, 1, 1))

    integrator = ImplicitMidpoint(0.05)
    for _ in 1:5
        step!(sys_dip, integrator)
        step!(sys_sun, integrator)
    end

    dip_is_lefthanded = B ⋅ (ic × magnetic_moment(sys_dip, (1,1,1,1))) < 0
    sun_is_lefthanded = B ⋅ (ic × magnetic_moment(sys_sun, (1,1,1,1))) < 0

    @test dip_is_lefthanded == sun_is_lefthanded == true
end


@testitem "DM chain" begin
    latvecs = lattice_vectors(2, 2, 1, 90, 90, 90)
    cryst = Crystal(latvecs, [[0,0,0]], "P1")
    sys = System(cryst, (1,1,1), [SpinInfo(1,S=1,g=-1)], :dipole)
    D = 1
    B = 10.0
    set_exchange!(sys, dmvec([0, 0, D]), Bond(1, 1, [0, 0, 1]))
    set_field!(sys, [0, 0, B])

    # Above the saturation field, the ground state is fully polarized, with no
    # energy contribution from the DM term.

    randomize_spins!(sys)
    minimize_energy!(sys)
    @test energy_per_site(sys) ≈ -B
    qs = [[0, 0, -1/2], [0, 0, 1/2]]
    path = Sunny.q_space_path(cryst, qs, 10)
    swt = SpinWaveTheory(sys)
    measure = Sunny.DSSF_trace(sys)
    res = Sunny.intensities_bands2(swt, path; measure)
    disp_ref = [B + 2D*sin(2π*q[3]) for q in path.qs]
    intens_ref = [1.0 for _ in path.qs]
    @test res.disp[1,:] ≈ disp_ref
    @test res.data[1,:] ≈ intens_ref

    # Below the saturation field, the ground state is a canted spiral

    sys2 = resize_supercell(sys, (1, 1, 4))
    B = 1
    set_field!(sys2, [0, 0, B])
    randomize_spins!(sys2)
    minimize_energy!(sys2)
    @test energy_per_site(sys2) ≈ -5/4
    swt = SpinWaveTheory(sys2)
    measure = Sunny.DSSF_trace(sys2)
    qs = [[0,0,-1/3], [0,0,1/3]]
    res2 = Sunny.intensities_bands2(swt, qs; measure)
    disp2_ref = [3.0133249314 2.5980762316 1.3228756763 0.6479760935
                 3.0133249314 2.5980762316 1.3228756763 0.6479760935]
    intens2_ref = [0.0292617379 0.4330127014 0.0 0.8804147011
                   0.5292617379 0.4330127014 0.0 0.3804147011]
    @test res2.disp ≈ disp2_ref'
    @test res2.data ≈ intens2_ref'

    # Perform the same calculation with Single-Q functions

    sys3 = resize_supercell(sys2, (1, 1, 1))
    axis = [0, 0, 1]
    randomize_spins!(sys3)
    k = Sunny.minimize_energy_spiral!(sys3, axis; k_guess=randn(3))
    @test k[3] ≈ 3/4
    @test Sunny.spiral_energy_per_site(sys3; k, axis) ≈ -5/4
    swt = SpinWaveTheory(sys3)
    res = Sunny.intensities_bands_spiral(swt, qs, k, axis; measure=Sunny.DSSF_trace(sys; apply_g=false))
    disp3_ref = [3.0133249314 2.5980762316 0.6479760935
                 3.0133249314 2.5980762316 0.6479760935]
    intens3_ref = [0.0292617379 0.4330127014 0.8804147011
                   0.5292617379 0.4330127014 0.3804147011]
    @test res.disp ≈ disp3_ref'
    @test res.data ≈ intens3_ref'

    # Finally, test fully polarized state

    B = 10
    set_field!(sys3, [0, 0, B])
    polarize_spins!(sys3, [0, 0, 1])
    @test energy_per_site(sys3) ≈ -B
    swt = SpinWaveTheory(sys3)
    res = Sunny.intensities_bands_spiral(swt, qs, k, axis; measure=Sunny.DSSF_trace(sys; apply_g=false))

    # For the wavevector, qs[1] == [0,0,-1/2], corresponding to the first row of
    # disp4 and intens4, all intensity is in the third (lowest energy)
    # dispersion band. For the wavevector, qs[2] == [0,0,+1/2], all intensity is
    # in the first (highest energy) dispersion band.
    @test all(res.disp[1, :] .≈ B + 2D*sin(2π*qs[2][3]))
    @test all(res.disp[3, :] .≈ B + 2D*sin(2π*qs[1][3]))
    @test res.data ≈ [0 1; 0 0; 1 0]
end
