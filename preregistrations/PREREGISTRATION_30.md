# Thirtieth pre-registration: a static friction coefficient imported and applied, XPBD's slip seen whole

Registered 21 October 2026, after Study 27 (run 130) and the host checks that followed it. Registered before any play
of this registration existed. To be played once, as run 133, on Newton 1.7.0.

## The question

Issue 18's last part (N3): a static friction coefficient, and its import from USD. Study 27 found the coefficient
imported (pull request #4306) and held by SemiImplicit and Featherstone at 1 and 0.25 ms with Senua AI's static
friction patch, and XPBD held at 1 ms but creeping 12 um/s at 0.25 ms, the same as its chain without the patch: XPBD's
friction measures a step's slip as the difference of two contact points' 32-bit world positions, which cannot see a
slip under one spacing of those coordinates (3.7 nm at 0.04 m from the origin), so a held body slips by about that a
step. Senua AI's XPBD friction slip patch, with `NEWTON_XPBD_FRICTION_SLIP=1`, measures the slip as the points'
separation at the step's start plus each body's motion over the step, carried (the integrator's v dt and w dt and
every iteration's correction); on the host it took the hold at 0.25 ms from 12 to 7 um/s and left the slides as they
were, a stopped one now still. On a cube and coefficients no study used: do XPBD, SemiImplicit and Featherstone hold a
statically held cube, imported or built, and play the dynamic coefficient once it slides?

## The right answers

- A cube pushed between its dynamic and its static limit stays where it is; pushed past the static limit it breaks
  away, and sliding it plays the dynamic coefficient.
- A static coefficient authored in a USD physics material reaches the model and plays as the same coefficient given
  in Python.
- A solver that does not apply a static coefficient says so.

## Engines and rigs

Newton 1.7.0 from PyPI (`newton==1.7.0`, Warp 1.18.0, MuJoCo Warp 3.15.0) as released, Study 7's environment, and
engines made from it by this run's `setup_engine.sh`, all no fuzz, first on the path: **chain**, the base environment's
Newton with the record's validated friction chains (Studies 15 and 18) and pull request #4306 rebased onto 1.7.0
([`pr_4306_on_1.7.0.diff`](../patches/upstream/pr_4306_on_1.7.0.diff), sha256 a3e22f05518b7df9...); and the chain with
Senua AI's static friction patch
([`static_friction_v2_on_chain.diff`](../patches/in_design/static_friction_v2_on_chain.diff), sha256
ac70ebdcb1ea088e...) and its XPBD friction slip patch on that
([`xpbd_friction_slip_on_static.diff`](../patches/in_design/xpbd_friction_slip_on_static.diff), sha256
104a1a88390f1c3d...): **off** without `NEWTON_STATIC_FRICTION` and `NEWTON_XPBD_FRICTION_SLIP`, **on** with both set to
1. Newton's USD importer's own dependencies beside every engine, as Study 27 (`usd-core==26.8`,
`newton-usd-schemas==0.6.0`, each checked by sha256). The chains' switches set on every engine, as Study 27; XPBD at 64
iterations. Rig as committed at this registration: `tools/nwt_contact.py`. Warp's CPU device. Measured by Senua AI's
`sx_contact` (`creep`, `final`, `stop`) and judged by its `rule`.

## The scenes, registered parameters

None of these numbers was used in a probe or a study. A 0.75 kg cube of half-size 0.045 m on the plane, at 1 ms and
0.25 ms, on XPBD, SemiImplicit, Featherstone, the MuJoCo solver, VBD-ALM and VBD; both shapes' friction 0.35 and static
friction 0.75 (dynamic limit 2.5725 N, static 5.5125 N), g = 9.8 m/s^2:

- **hold**: pushed at 4.0425 N (0.55 g) from 0.3 s, 1.2 s. Right answer: held.
- **kinetic**: sent at 0.3 m/s under the same push from the start, 1 s. Right answer: 2.26 m/s.
- **break**: pushed at 6.2475 N (0.85 g) from 0.3 s, 1.2 s. Right answer: 4.41 m/s.
- **slide**: sent at 0.9 m/s with no push, 0.6 s. Right answer: 118,076 um.
- **import**: the cube and its friction from a UsdPhysics stage through Newton's importer (`usd=1`), its material's
  dynamicFriction 0.35 and staticFriction 0.75, the plane's friction 0.35 with no static coefficient (the pair's static
  coefficient, the mean of each shape's larger, 0.55: limit 4.0425 N); pushed at 3.3075 N (0.45 g) from 0.3 s, 1.2 s.
  Right answer: held, the imported static coefficient 0.75.

Hold and import as released too; every scene with the chain, off and on.

## The rules

Each judged by `sx_contact rule`, from the measured lines, and nowhere else. "The three" are XPBD, SemiImplicit and
Featherstone.

| Rule | Statement | Kind |
|---|---|---|
| R1 safe when off | Off, every play byte for byte the chain's | eq (count) |
| R2 the fault is there | As released, the hold and the import depart from rest on the three (mean speed 100 um/s or more, either way), and the imported static coefficient is not in the model | all_ge, eq (count) |
| R3 held | On, the hold within 10 um/s of rest on the three at both steps | all_in |
| R4 kinetic on the dynamic | On, the kinetic case within 1 in 50 of 2.26 m/s on the three at both steps | all_within |
| R5 breaks away | On, the break within 1 in 20 of 4.41 m/s on the three at both steps | all_within |
| R6 slides on the dynamic | On, each of the three's slide within 1 in 50 of its slide with the chain, at both steps | within |
| R7 imported and applied | The imported static coefficient 0.75 in the model with the chain and on (every play), and on, the import held within 10 um/s on the three at both steps | eq (count), all_in |
| R8 the others say so | On, every MuJoCo solver, VBD-ALM and VBD play warns once that it does not apply a static coefficient, and no play warns without the switch | eq (count) |
| R9 a number | Every play on a number throughout | all_eq |

Reported, not ruled: every reading, and the MuJoCo solver's and VBD's plays.

## What it decides

When R1 to R9 hold, issue 18 is resolved: its combination by Study 26, and its static coefficient by this study,
imported from USD and applied by XPBD, SemiImplicit and Featherstone, with the MuJoCo solver (which cannot) and VBD
(which does not yet) saying so. A rule that fails is reported as failed, and the part stays open.
