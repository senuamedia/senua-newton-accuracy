# Run 099: Featherstone's Coulomb friction pass with the inertia where the step ends (issues 6 and 9)

Not registered: a design probe, its predictions pushed with [`play.sh`](play.sh) before any play, the same plays and
predictions as [run 097](../run_097_featherstone_coulomb_v2/README.md). Newton 1.7.0 from PyPI with the same patches
as run 094, the Featherstone patch in its third form
([`featherstone_coulomb_friction_v3_on_semi_coulomb_v3.diff`](../../patches/in_design/featherstone_coulomb_friction_v3_on_semi_coulomb_v3.diff),
sha256 f3b43db0f6718f0a...).

## The patch

Run 097 left Coulomb at impact first order in the step and below 4,000 (3,792 per 10,000 at the suite's 1/2 step):
the pass solved its impulses with the joint-space inertia built at the step's start, while they act on the bodies where
the step leaves them. The third form builds that inertia where the step leaves the joints, before its sweeps, with
Featherstone's own kernels (forward kinematics, the motion subspaces and spatial inertias, the Jacobian, the mass
matrix, H = J^T M J and its Cholesky factor, at the integrated coordinates), as SemiImplicit's pass takes each body's
inertia as the step leaves it. With it the second form's correction of the free root is not needed: the root's speeds
are read about the centre the inertia was built at. Nothing else differs from the first form.

## What is played

As in run 097: `off`, `f64`, `df16` and `df64`, run 094's hold and slide at 2, 0.5 and 0.125 ms on Featherstone; the
contact suite for `df16` and `df64`; the release's and the damping patch's plays and suites run 094's.

## Predictions (pushed before the plays)

| Check | Prediction |
|---|---|
| C0 | `off` byte for byte run 094's release in every play; every play with the pass a number |
| C1 | `f64`'s and `df64`'s hold within 10 um/s of still at every step |
| C2 | `df64`'s slide within 1 in 100 of Coulomb's 102,041 um at every step |
| C3 | `df64`'s suite: Coulomb at impact (T05) and the friction over an impact (T10) within 1 in 100 of 4,000 at every step from 1/2 to 1/64; T06's reading at 1/16 within 10 um/s of still; no verdict lost that passes as released or with the damping patch alone |

Reported: `df16`, every verdict.

## What it found

Played 20 October 2026 on the second x86-64 host (`started.txt`, `finished.txt`); the measured lines in
`measured.txt`, the checks in [`checks.txt`](checks.txt), the suites under `suites/`. **8 of 10 checks held**, the same
8 as run 097.

| Check | Result |
|---|---|
| C0 | Held: `off` 6 of 6 byte for byte run 094's release; every play with the pass a number |
| C1 | Held: `f64`'s and `df64`'s hold 0, 0 and 0 um/s |
| C2 | Held: `df64`'s slide 101,538, 102,281 and 102,468 um |
| C3 | T05 and T10 **failed** at the suite's 1/2 step (3,792 and 3,815 per 10,000, as in run 097), within 1 in 100 from 1/4 on; T06's reading at 1/16 0 (held); nothing lost (held) |

- **Building the inertia where the step ends changes nothing measurable**: every hold, slide and suite reading is run
  097's to within a micrometre or a unit, but at the suite's 10 ms step, past the normal contact's limit (T05 2,810
  there against 3,037). For a free body, the second form's correction and the third form's inertia are the same
  change.
- **So the shortfall at impact is not the pass's**: Coulomb at impact converges to 4,000 as the step shrinks, 208, 30,
  11, 5, 3 and 2 short from 1/2 to 1/64, first order, where on SemiImplicit the same pass is exact at every step (run
  093). The two solvers share the force pass and the friction pass; they differ in how a spinning body is integrated
  over the step, and Featherstone integrates its joints, a free root's twist among them, by first-order semi-implicit
  Euler: a cube struck at a slant spins, and the shortfall is that integration's. Within the cone the friction is
  never more than Coulomb's.
