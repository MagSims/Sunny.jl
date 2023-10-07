# Stevens function expansion, renormalized for dipole projection
struct StevensExpansion
    kmax ::Int
    c0 :: SVector{1, Float64}
    c2 :: SVector{5, Float64}
    c4 :: SVector{9, Float64}
    c6 :: SVector{13, Float64}
end

function StevensExpansion(c)
    c = map(c) do ck
        norm(ck) < 1e-12 ? zero(ck) : ck
    end
    iszero(c[[1,3,5]]) || error("Single-ion anisotropy must be time-reversal invariant.")
    kmax = max(!iszero(c[2])*2, !iszero(c[4])*4, !iszero(c[6])*6)
    return StevensExpansion(kmax, c[0], c[2], c[4], c[6])
end

struct ExchangeCoupling
end

struct TensorDecomposition
    # Dimensions of (Aᵢ, Bᵢ) respectively
    N1 :: Int
    N2 :: Int

    # Generators of rotations for (Aᵢ, Bᵢ) respectively
    gen1 :: SVector{3, HermitianC64}
    gen2 :: SVector{3, HermitianC64}

    # [(A₁, B₁), (A₂, B₂), ...] interpreted as ∑ₖ Aₖ ⊗ Bₖ
    data :: Vector{Tuple{HermitianC64, HermitianC64}}
end

function TensorDecomposition(op, gen1, gen2)
    N1 = size(gen1[1], 1)
    N2 = size(gen2[1], 1)
    return TensorDecomposition(N1, N2, gen1, gen2, svd_tensor_expansion(op, N1, N2))
end

# Pair couplings are counted only once per bond
struct PairCoupling
    isculled :: Bool # Bond directionality is used to avoid double counting
    bond     :: Bond

    # TODO: Make union!
    # In :dipole mode, these will be renormalized couplings following
    # the procedure in https://arxiv.org/abs/2304.03874
    bilin    :: Union{Float64, Mat3} # Bilinear exchange
    biquad   :: Float64              # Scalar biquadratic

    # General pair interactions, only valid in SU(N) mode
    general  :: TensorDecomposition
end

mutable struct Interactions
    # Onsite coupling is either an N×N Hermitian matrix or possibly renormalized
    # Stevens coefficients, depending on the mode :SUN or :dipole.
    onsite :: Union{HermitianC64, StevensExpansion}
    # Pair couplings for every bond that starts at the given atom
    pair :: Vector{PairCoupling}
end

const rFTPlan = FFTW.rFFTWPlan{Float64, -1, false, 5, UnitRange{Int64}}
const rBFTPlan = FFTW.rFFTWPlan{ComplexF64, 1, false, 5, UnitRange{Int64}}
const rIFTPlan = FFTW.AbstractFFTs.ScaledPlan{ComplexF64, rBFTPlan, Float64}

struct Ewald
    A        :: Array{Mat3, 5}        # Interaction matrices in real-space         [offset+1,i,j]
    μ        :: Array{Vec3, 4}        # Magnetic moments μ = g s                   [cell,i]
    ϕ        :: Array{Vec3, 4}        # Cross correlation, ϕ = A⋆μ                 [cell,i]
    # Space for Fourier transforms; compressed along first index m1
    FA       :: Array{ComplexF64, 7}  # Transformed interactions F[A]              [α,β,m1,m2,m3,i,j]
    Fμ       :: Array{ComplexF64, 5}  # Transformed spins F[s]                     [α,m1,m2,m3,i]
    Fϕ       :: Array{ComplexF64, 5}  # Cross correlation, F[ϕ] = conj(F[A]) F[s]  [α,m1,m2,m3,i]
    plan     :: rFTPlan
    ift_plan :: rIFTPlan
end

mutable struct System{N}
    const origin           :: Union{Nothing, System{N}}
    const mode             :: Symbol
    const crystal          :: Crystal
    const latsize          :: NTuple{3, Int}            # Size of lattice in unit cells

    # To facilitate handling of inhomogeneous systems, these are stored for
    # every cell in the system
    const Ns               :: Array{Int, 4}             # S=(N-1)/2 per atom in unit cell
    const κs               :: Array{Float64, 4}         # Sets either |Z| = √κ or |s| = κ
    const gs               :: Array{Mat3, 4}            # g-tensor per atom in unit cell

    # Interactions may be homogeneous (defined for one unit cell), or
    # inhomogeneous (defined for every cell in the system).
    interactions_union     :: Union{Vector{Interactions}, Array{Interactions,4}}

    # Optional long-range dipole-dipole interactions
    ewald                  :: Union{Ewald, Nothing}

    # Dynamical variables and buffers
    const extfield         :: Array{Vec3, 4}            # External B field
    const dipoles          :: Array{Vec3, 4}            # Expected dipoles
    const coherents        :: Array{CVec{N}, 4}         # Coherent states
    const dipole_buffers   :: Vector{Array{Vec3, 4}}    # Buffers for dynamics routines
    const coherent_buffers :: Vector{Array{CVec{N}, 4}} # Buffers for dynamics routines

    # Global data
    const units            :: PhysicalConsts
    const rng              :: Random.Xoshiro
end
