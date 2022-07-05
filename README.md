<div align="left">
    <img src="https://raw.githubusercontent.com/MagSims/Sunny.jl/readme_updates/assets/sunny_homes.jpg" width=70% alt="Sunny.jl">
</div>
<p>

<!--- [![](https://img.shields.io/badge/docs-stable-blue.svg)](https://sunnysuite.github.io/Sunny.jl/stable) --->

[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://sunnysuite.github.io/Sunny.jl/dev)

A package for simulating classical spin systems, including the Landau-Lifshitz dynamics of spin dipoles and its generalization to multipolar spin components. In the latter case, Sunny resolves the local quantum structure of individual spins, making it particularly suited for modeling magnetic compounds with strong local anisotropy.

Sunny additionally provides Monte Carlo algorithms for sampling from thermal equilibrium, as well as tools for measuring dynamical structure factors that can be compared with experimental neutron scattering data. Sunny provides symmetry analyses to facilitate the design and specification of model Hamiltonians, and interactive tools to visualize 3D crystal structures and (coming soon) structure factor data.

## Example notebooks

 To get a feeling for what Sunny can do, we recommend to start by browsing some [Jupyter notebook examples](http://nbviewer.org/github/ddahlbom/SunnyTutorials/tree/main/tutorials/).

## Technical description of SU(_N_) spin dynamics.

A quantum spin of magnitude _S_ has $N = 2 S + 1$ distinct levels, and evolves under the group of special unitary transformations, SU(_N_). Local physical observables correspond to expectation values of the $N^2-1$ generators of SU(_N_), which may be interpreted as multipolar spin components. The standard treatment keeps only the expected dipole components, $\langle \hat S^x\rangle,\langle \hat S^y\rangle,\langle \hat S^z\rangle$, yielding the Landau-Lifshitz dynamics. The "SU(_N_) spin dynamics" naturally generalizes the LL equation by modeling the coupled dynamics of all $N^2-1$ generalized spin components. Note, crucially, that a local SU(_N_) symmetry is never assumed. For more details, please see our papers:
* H. Zhang and C. D. Batista, _Classical spin dynamics based on SU(N) coherent states_, Phys. Rev. B 104, 104409 (2021) [[arXiv:2106.14125](https://arxiv.org/abs/2106.14125)].
* D. Dahlbom et al., _Geometric integration of classical spin dynamics via a mean-field Schrödinger equation_ [[arXiv:2204.07563](https://arxiv.org/abs/2204.07563)].

## Comparison with other tools

A defining feature of Sunny is its support for generalized SU(_N_) spin dynamics. As a special case, however, Sunny can be restricted to the dipole-only approximation of spin. In this mode, the capabilities of Sunny are similar to [SpinW](https://spinw.org/). A key difference is that Sunny does not (currently) employ linear spin wave theory. Advantages are: (1) Applicability to finite temperature measurements and (2) Support for single-ion anisotropies beyond quadratic order.   A disadvantage is that structure factor measurements $\mathcal S(q,\omega)$ have momentum-space ($q$) resolution that is limited by the size of magnetic super cell.

## Installation

Sunny is implemented in the [Julia programming language](https://julialang.org/). New Julia users may wish to start with our [Getting Started](GettingStarted.md) guide.

From the Julia prompt, one can install Sunny using the built-in package manager. We currently recommend tracking the main branch:
```
julia> ]
pkg> add Sunny#main
```

Check that Sunny is working properly by running the unit tests: `pkg> test Sunny`. Please keep up-to-date by periodically running the Julia update command: `pkg> update`.

A good way to interact with Sunny is through the Jupyter notebook interface. This support can be installed through the [IJulia](https://github.com/JuliaLang/IJulia.jl) package.

## API Reference

[Documentation available here](https://sunnysuite.github.io/Sunny.jl/dev).

## Contact us

If you discover bugs, or find Sunny useful, please contact us at kbarros@gmail.com and david.dahlbom@gmail.com.

<!-- Users who wish to contribute to Sunny source-code development should instead use the `dev` command:
```
julia> ]
pkg> dev Sunny
```

This will `git clone` the source code to the directory `~/.julia/dev/Sunny`. You can make changes to these files,
and they will be picked up by Julia.  The package manager will not touch
any package installed by `dev`, so you will be responsible
for keeping Sunny up to date, e.g., using the command `git pull` from Sunny package directory. -->


<!-- 
For plotting, you may also wish to install
```
pkg> add Plots
pkg> add GLMakie
```

At the time of this writing, GLMakie has some rough edges, especially on Mac platforms. Run `test GLMakie` to make sure it is working properly. -->

