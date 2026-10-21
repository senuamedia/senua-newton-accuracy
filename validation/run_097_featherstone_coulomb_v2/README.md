# Run 097: Featherstone's Coulomb friction pass, its free root's change kept about its centre (issues 6 and 9)

Not registered: a design probe, its predictions pushed with [`play.sh`](play.sh) before any play. Newton 1.7.0 from
PyPI with the same patches as [run 094](../run_094_featherstone_coulomb/README.md), the Featherstone patch in its
second form
([`featherstone_coulomb_friction_v2_on_semi_coulomb_v3.diff`](../../patches/in_design/featherstone_coulomb_friction_v2_on_semi_coulomb_v3.diff),
sha256 af889cb8b5c81dd8...).

## The patch

Run 094 found the first form holds the cube at every step but, sliding, gives too much friction, first order in the
step. A free root's speeds inside Featherstone are its twist at the world's origin; the pass solves their change with
the step's inertia, built about where the centre was at the step's start, and reads them back where the centre is now,
so the centre's change of speed gains the turn's change times the centre's move. The second form moves the solved
change so that the centre's change of speed is the one solved about where the centre is when it is applied
(`keep_free_root_centre`); nothing else differs.

## What is played

The patched tree with no switch set (`off`), the pass at 64 sweeps (`f64`), and with the damping patch at 16 and 64
(`df16`, `df64`): run 094's hold and slide at 2, 0.5 and 0.125 ms on Featherstone; the contact suite for `df16` and
`df64`. The release's and the damping patch's plays and suites are run 094's.

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
`measured.txt`, the checks in [`checks.txt`](checks.txt), the suites under `suites/`. **8 of 10 checks held.**

| Check | Result |
|---|---|
| C0 | Held: `off` 6 of 6 byte for byte run 094's release; every play with the pass a number |
| C1 | Held: `f64`'s and `df64`'s hold 0, 0 and 0 um/s |
| C2 | Held: `df64`'s slide 101,538, 102,281 and 102,467 um (run 094: 99,448, 101,761, 102,337) |
| C3 | T05 and T10 **failed** at the suite's 1/2 step (3,792 and 3,815 per 10,000), within 1 in 100 from 1/4 on; T06's reading at 1/16 0 (held); nothing lost against the release or the damping patch (held) |

- **Keeping the free root's change about its centre removes most of the excess**: Coulomb at impact (T05) is now
  3,037, 3,792, 3,970, 3,989, 3,995, 3,997 and 3,998 per 10,000 from 10 ms to 1/64, where the first form gave 6,827 to
  4,048; the friction over an impact (T10) and the refinement chain (T08) pass, and steady sliding is 4,000 at 1/16
  (T02; 4,146 at 10 ms). The suite passes 5 of 10, 4 as released.
- **What is left is first order again, and below 4,000**: 208, 30, 11, 5, 3 and 2 short from 1/2 to 1/64. The pass
  still solves with the joint-space inertia built at the step's start, while the impulses act on the body where the
  step leaves it, turned by its spin over the step; SemiImplicit's pass takes each body's inertia as the step leaves it
  and is exact at every step (run 093). Run 099 builds Featherstone's inertia where the step ends.
- T04, T06 and T07 still fail at the suite's 10 ms step only, past the normal contact's limit (the cube rebounds 1.69
  times its drop there); T07 is 990,500 um/s at 1/16, within 3 in 100.
