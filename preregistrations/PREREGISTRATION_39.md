# Thirty-ninth pre-registration: VBD's legacy path far from the origin, its poses carried and its joint stabilisation off

Registered 21 October 2026, after Study 36 (run 139) and the host check that followed it. Registered before any play of
this registration existed. To be played once, as run 142, on Newton 1.7.0.

## The question

Issue 12, VBD's legacy path: Study 36 (15 of 15) fixed VBD's chain far from the origin on its compliant-ALM path with
Senua AI's VBD displacement patch and pose carry; on the legacy path (`rigid_compliant_alm=False`) it reported the carry
holding 15 m out but not 60 m out at the two smallest steps (5,269 and 5,558 ppm at 0.05 and 0.025 ms, against 857 and
188 at the origin). The legacy path stabilises each joint by subtracting a share alpha of its starting error every step
(`rigid_avbd_joint_alpha`, 0.95 by default; the compliant-ALM path's default subtracts none), and that starting error is
formed from the 32-bit poses. The host check after Study 36 (Study 36's chain, legacy path, 60 m, the carry set, not
registered): with Newton's own `rigid_avbd_joint_alpha=0`, 844 and 194 ppm at 0.05 and 0.025 ms, the origin's own; at
0.95, 5,269 and 5,558. On a chain, distances and steps no run used: with the pose carry and the joint stabilisation off,
does VBD's legacy path play the chain far from the origin as at the origin, its loss falling with the step?

## The right answers

- A free chain's energy is constant; a consistent integrator's departure from it falls as the step shrinks, and does
  not depend on where in the world the chain is.
- A body spinning about its centre of mass keeps that centre still; a slide settles as the step shrinks; a cube pushed
  below its friction limit stays still.

## Engines and rigs

Newton 1.7.0 from PyPI as released, Study 7's environment, and engines made from it by this run's `setup_engine.sh`, no
fuzz, first on the path (Study 36's): **dsp**, the displacement patch alone; the displacement patch with the pose carry,
**off** without `NEWTON_VBD_POSE_CARRY`, **on** with it set to 1. `NEWTON_VBD_DISPLACEMENT=1` in every play. Every play on
VBD's legacy path (`rigid_compliant_alm=False`) with `rigid_avbd_joint_alpha=0` (Newton's own option), unless named.
Rigs as committed at this registration: `tools/nwt_chain.py` (its `x0`) and `tools/nwt_contact.py`. Warp's CPU device.
Measured by Senua AI's `sx_contact` (`chain`, `creep`, `stop`) and judged by its `rule`.

## The scenes, registered parameters

None of these numbers was used in a run.

- **C, a free chain**: links of 0.85 and 1.15 kg, radius 0.04 m, the first's centre 0.26 m from the base hinge, the
  second hinge 0.52 m out and the second's centre 0.2 m beyond it, released at 0 and 0.45 rad turning at 1.8 and -1.4
  rad/s, no gravity, 2 s; its base at 0, 20 and 50 m from the origin along x; at 0.4, 0.2, 0.1, 0.05 and 0.025 ms;
  dsp, off and on; and on with the default alpha 0.95 (reported).
- **S, a spinning body**: a 1.3 kg cube of half-size 0.045 m whose box sits 0.02 m along its x from its origin, turning at
  3.8 rad/s about z through its centre of mass, 1 m above the ground, no gravity, 1.2 s; at 1.2, 0.24 and 0.06 ms.
- **L, a slide**: a 1.0 kg cube of half-size 0.04 m sent along the ground at 0.8 m/s at friction 0.4, 0.5 s; at 1.2,
  0.24, 0.06 and 0.03 ms.
- **H, a hold**: a 1.25 kg cube of half-size 0.045 m resting on the ground at friction 0.5, pushed sideways from 0.3 s at
  3.0625 N (50% of its friction's limit at 9.8 m/s2), 1.2 s, with Study 17's contact history and sticky matching; at
  1.2 and 0.06 ms.

S, L and H dsp, off and on.

## The rules

Each judged by `sx_contact rule`, from the measured lines, and nowhere else. "The departure" is C's
`energy_largest_drift_ppm`; "far" is 20 and 50 m.

| Rule | Statement | Kind |
|---|---|---|
| R1 safe when off | Off, every play byte for byte dsp's | eq (count) |
| R2 the fault is there | Off, C's departure at 0.025 ms at least twice the origin's, at 20 m and at 50 m | ge |
| R3 far as at the origin | On, at each step, C's departure at 20 and at 50 m within 1 in 10 of the origin's at that step | all_within |
| R4 falls with the step | On, at 0, 20 and 50 m, C's departure falls at each halving of the step | falls |
| R5 nothing else worse | On, S's centre within 3 um/s of still at every step; L's distance at 0.24 and 0.06 ms within 1 in 200 of its play at 0.03 ms; H within 10 um/s of still at both steps | all_in, all_within |
| R6 a number | Every play on a number throughout | all_eq |

Reported, not ruled: every reading, and C on with the default alpha 0.95.

## What it decides

When R1 to R6 hold, issue 12's VBD legacy part is fixed by Senua AI's VBD displacement patch and pose carry with Newton's
own `rigid_avbd_joint_alpha=0`, and with Study 36 and Study 38 issue 12 is resolved for a free chain on VBD (both paths)
and XPBD. A rule that fails is reported as failed, and the legacy path's far chain stays open.
