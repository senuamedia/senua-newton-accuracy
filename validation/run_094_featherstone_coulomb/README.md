# Run 094: Featherstone's friction as Coulomb's law at the step's end (issues 6 and 9)

Not registered: a design probe, its predictions pushed with [`play.sh`](play.sh) before any play. Newton 1.7.0 from
PyPI, and the same with Senua AI's unit friction direction and contact damping patches, the third form of its
SemiImplicit Coulomb friction patch and its Featherstone Coulomb friction patch in design first on the path
([`featherstone_coulomb_friction_on_semi_coulomb_v3.diff`](../../patches/in_design/featherstone_coulomb_friction_on_semi_coulomb_v3.diff),
sha256 cc2a28ac2db35e3a..., switch `NEWTON_FEATHERSTONE_COULOMB_FRICTION=K`).

## The patch

Featherstone's contact pass is SemiImplicit's, its friction a force integrated explicitly, so a load inside the
friction limit creeps (issue 6) and a 10 cm cube at 2 ms is past its limit (issue 9). The patch makes SemiImplicit's
friction pass (runs 090, 092, 093) for Featherstone: the force pass with its friction left out and each contact
recorded, then after the step's integration K sweeps, each finding every contact's slip from the joints' speeds the one
before left and giving it the impulse that stops it, shared among its body's contacts, its total over the step within
Coulomb's cone. A body's impulses reach the joints as its forces do in Featherstone's own `eval_rigid_tau`: each
body's impulse wrench taken about its solve origin and summed over the bodies beyond each joint, projected on the
joint's motion subspace; the change of the joints' speeds solves the step's own joint-space inertia with its Cholesky
factor, as the accelerations do, and the coordinates follow that change over the step. With
`NEWTON_CONTACT_DAMPING_NO_PULL=1` its force pass takes the contact damping patch's change, as SemiImplicit's third
form does. Models with joint mimics keep the stock pass.

## What is played

On Featherstone as released (`stock`); the patched tree with no switch set (`off`); the damping patch alone (`damp`);
the Featherstone pass at 64 sweeps (`f64`); and with the damping patch at 16 and 64 sweeps (`df16`, `df64`): run 090's
hold and slide at 2, 0.5 and 0.125 ms; the contact suite for `stock`, `damp`, `df16` and `df64`.

## Predictions (pushed before the plays)

| Check | Prediction |
|---|---|
| C0 | `off` byte for byte the release; every play with the pass a number |
| C1 | `f64`'s and `df64`'s hold within 10 um/s of still at every step |
| C2 | `df64`'s slide within 1 in 100 of Coulomb's 102,041 um at every step |
| C3 | `df64`'s suite: T06's reading at its 1/16 step within 10 um/s of still, and no verdict lost that passes as released or with the damping patch alone |

Reported: `df16`, every verdict, how far the cube tips.

## What it found

Played 20 October 2026 on the second x86-64 host (`started.txt`, `finished.txt`); the measured lines in
`measured.txt`, the checks in [`checks.txt`](checks.txt), the suites under `suites/`. **6 of 8 checks held; one of the
two failures is the runner's.**

| Check | Result |
|---|---|
| C0 | Held: `off` 6 of 6 byte for byte the release; every play with the pass a number |
| C1 | Held: `f64`'s and `df64`'s hold 0, 0 and 0 um/s at 2, 0.5 and 0.125 ms (as released 172,252, 6,138 and 735) |
| C2 | **Failed**: `df64`'s slide 99,448 um at 2 ms, 2.5% short of 102,041; 101,761 and 102,337 at the smaller steps |
| C3 | Nothing lost against the release or the damping patch alone (held); T06's line **failed for the runner**: its reading at 1/16 is 0, within the prediction, but the line passed the measure's `in` its value last where the value comes first |

- **The hold is held on Featherstone too**, at 16 and 64 sweeps, with the damping patch and without, where as released
  at 2 ms the cube tips 822 mrad and slides off at 172,252 um/s (issue 9's scene).
- **Sliding, the pass gives too much friction, and the excess is first order in the step**: the suite's Coulomb at
  impact (T05) is 6,827, 5,503, 4,818, 4,399, 4,196, 4,097 and 4,048 per 10,000 from 10 ms to 1/64 (right answer
  4,000), its steady sliding (T02) 5,751 and 4,135, its friction over an impact (T10) 6,671 to 4,041; on SemiImplicit
  the same pass gives 3,999 to 4,000 at every step (run 093). The hold converges whatever the impulse's mapping (each
  sweep measures the slip that is left), but within the cone the impulse delivered must be the one computed. A free
  root's speeds inside Featherstone are its twist at the world's origin; the pass solves the impulse's change of them
  with the step's inertia, built at the step's start, but they are read back at its end, where the body has moved v dt,
  so the centre's change of speed gains the turn's change times v dt: about 4 in 10 of the impulse at 10 ms for this
  cube on its corners, halving as the step halves.
- T07 is 959,200 um/s at 1/16 (2.1% low, within its 3 in 100) and 854,400 at 10 ms; T04, T06 and T07 fail at the
  suite's 10 ms step, past the normal contact's limit, as on SemiImplicit. The suite passes 4 of 10 as released and
  with the pass, 3 with the damping patch alone (which loses T08 there).
- Run 097 corrects the free root's change for where its centre is at the step's end.
