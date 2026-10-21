# Twenty-seventh pre-registration: a static friction coefficient, imported and applied

Registered 21 October 2026, after the design probe of run 129. Registered before any play of this registration existed.
To be played once, as run 130, on Newton 1.7.0.

## The question

Issue 18's last part (N3): Newton's shapes carry one friction coefficient, so nothing that sticks before it slides can
be modelled on any solver, and a USD physics material's `staticFriction` is dropped on import. Pull request #4306, open
upstream, adds the static coefficient to the data model (`ShapeConfig.mu_static`, `Model.shape_material_mu_static`)
and to the USD importer; no solver reads it. Senua AI's static friction patch, with `NEWTON_STATIC_FRICTION=1`, makes
XPBD, SemiImplicit and Featherstone apply it by the needed-impulse rule (the friction a contact needs to stop its slip
within the step is applied whole when it is within the static limit, otherwise the dynamic limit), and makes the two
solvers that do not apply it say so: the MuJoCo solver (MuJoCo models one coefficient) and VBD (its contact does not
yet). In run 129 the three held a pushed cube between the limits and played the dynamic coefficient once it slid. On
a cube, coefficients, steps and an import no probe used: do they?

## The right answers

- A cube pushed between its dynamic and its static limit stays where it is; pushed past the static limit it breaks
  away, and sliding it plays the dynamic coefficient.
- A static coefficient authored in a USD physics material reaches the model and plays as the same coefficient given
  in Python.
- A solver that does not apply a static coefficient says so.

## Engines and rigs

Newton 1.7.0 from PyPI (`newton==1.7.0`, Warp 1.18.0, MuJoCo Warp 3.15.0) as released, Study 7's environment, and
engines made from it by this run's `setup_engine.sh`, all no fuzz, first on the path: **chain**, the base
environment's Newton with the record's validated friction chains (SemiImplicit's and Featherstone's:
`unit_friction_direction`, `contact_damping_no_pull`, `semi_coulomb_friction`, `featherstone_coulomb_friction`, Study
18; XPBD's: `xpbd_no_speed_floor`, `xpbd_friction_total`, Study 15) and pull request #4306 rebased onto 1.7.0
([`pr_4306_on_1.7.0.diff`](../patches/upstream/pr_4306_on_1.7.0.diff), sha256 a3e22f05518b7df9...); and the chain
with Senua AI's static friction patch
([`static_friction_v2_on_chain.diff`](../patches/in_design/static_friction_v2_on_chain.diff), sha256
ac70ebdcb1ea088e...): **off** without `NEWTON_STATIC_FRICTION`, **on** with it set to 1. Newton's USD importer's own
dependencies, from PyPI, beside every engine: `usd-core==26.8` (sha256 204fb1ef1fc977b8...) and
`newton-usd-schemas==0.6.0` (sha256 05e027d2bd1f1b1e...). The chains' switches set on every engine:
`NEWTON_XPBD_NO_SPEED_FLOOR=1`, `NEWTON_XPBD_FRICTION_TOTAL=1`, `NEWTON_UNIT_FRICTION_DIRECTION=1`,
`NEWTON_CONTACT_DAMPING_NO_PULL=1`, `NEWTON_SEMI_COULOMB_FRICTION=1`, `NEWTON_SEMI_COULOMB_FRICTION_ITERATIONS=64`,
`NEWTON_FEATHERSTONE_COULOMB_FRICTION=64`; XPBD at 64 iterations. Rig as committed at this registration:
`tools/nwt_contact.py` (its `mus`, `groundmus` and `usd`). Warp's CPU device. Measured by Senua AI's `sx_contact`
(`creep`, `final`, `stop`) and judged by its `rule`.

## The scenes, registered parameters

None of these numbers was used in the probes. A 0.6 kg cube of half-size 0.04 m on the plane, at 1 ms and 0.25 ms, on
XPBD, SemiImplicit, Featherstone, the MuJoCo solver, VBD-ALM and VBD; both shapes' friction 0.3 and static friction
0.7 (dynamic limit 1.764 N, static 4.116 N), g = 9.8 m/s^2:

- **hold**: pushed at 2.94 N (0.5 g) from 0.3 s, 1.2 s. Right answer: held (as released and with the chain it slides,
  its mean speed over the second half 1.176 m/s).
- **kinetic**: sent at 0.4 m/s under the same push from the start, 1 s. Right answer: 2.36 m/s.
- **break**: pushed at 4.704 N (0.8 g) from 0.3 s, 1.2 s. Right answer: 4.41 m/s.
- **slide**: sent at 0.8 m/s with no push, 0.6 s. Right answer: 108,844 um.
- **import**: the cube and its friction from a UsdPhysics stage through Newton's importer (`usd=1`), its material's
  dynamicFriction 0.3 and staticFriction 0.7, the plane's friction 0.3 with no static coefficient (the pair's static
  coefficient, the mean of each shape's larger, 0.5: limit 2.94 N); pushed at 2.352 N (0.4 g) from 0.3 s, 1.2 s.
  Right answer: held, the imported static coefficient 0.7.

Hold and import as released too; every scene with the chain, off and on.

## The rules

Each judged by `sx_contact rule`, from the measured lines, and nowhere else. "The three" are XPBD, SemiImplicit and
Featherstone.

| Rule | Statement | Kind |
|---|---|---|
| R1 safe when off | Off, every play byte for byte the chain's | eq (count) |
| R2 the fault is there | As released, the hold and the import slide on the three (mean speed 100 mm/s or more), and the imported static coefficient is not in the model | all_ge, eq (count) |
| R3 held | On, the hold within 10 um/s of rest on the three at both steps | all_in |
| R4 kinetic on the dynamic | On, the kinetic case within 1 in 50 of 2.36 m/s on the three at both steps | all_within |
| R5 breaks away | On, the break within 1 in 20 of 4.41 m/s on the three at both steps | all_within |
| R6 slides on the dynamic | On, each of the three's slide within 1 in 50 of its slide with the chain, at both steps | within |
| R7 imported and applied | The imported static coefficient 0.7 in the model with the chain and on (every play), and on, the import held within 10 um/s on the three at both steps | eq (count), all_in |
| R8 the others say so | On, every MuJoCo solver, VBD-ALM and VBD play warns once that it does not apply a static coefficient, and no play warns without the switch | eq (count) |
| R9 a number | Every play on a number throughout | all_eq |

Reported, not ruled: every reading, and the MuJoCo solver's and VBD's plays.

## What it decides

When R1 to R9 hold, issue 18 is resolved: its combination by Study 26, and its static coefficient by this study, imported
from USD and applied by XPBD, SemiImplicit and Featherstone, with the MuJoCo solver (which cannot) and VBD (which does not
yet) saying so. A rule that fails is reported as failed, and the part stays open.
