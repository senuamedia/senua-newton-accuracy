# Thirty-sixth pre-registration: VBD's chain far from the origin, its poses carried in two 32-bit numbers

Registered 21 October 2026, after run 125's host checks of Senua AI's VBD pose carry. Registered before any play of this
registration existed. To be played once, as run 139, on Newton 1.7.0.

## The question

Issue 12, VBD's part: a free two-link chain loses energy, and with Senua AI's VBD displacement patch (validated for issue
13 by Study 23) the loss falls with the step at the origin, as a consistent integrator's should, but away from the origin
it grows as the step shrinks: VBD keeps each body's pose in 32 bits, whose spacing grows with the distance from the
origin, so a step's motion falls under it (Study 22, R5; run 125's notes: 7,774 ppm at 10 m and 24,002 at 40 m at the
smallest step on VBD's compliant-ALM path, against 353 at the origin).

Senua AI's VBD pose carry ([`vbd_pose_carry_on_displacement.diff`](../patches/in_design/vbd_pose_carry_on_displacement.diff),
on the displacement patch, switch `NEWTON_VBD_POSE_CARRY=1` read once) carries each body's centre from step to step as
two 32-bit numbers (Fast2Sum), makes the forward step's target and the solve's pose from them, sees each joint from the
child's target centre with the pairs, and hands the joints' starting error shifted copies of the poses made from them.
On the hosts (run 125's notes), on the compliant-ALM path, the chain played 10 and 40 m out as at the origin within 1 in
20 at every step from 0.375 to 0.023 ms and its departure fell with the step everywhere; on the legacy path it held 10 m
out but not 40 m out at the two smallest steps. The compliant-ALM path is the one Newton 1.6 says becomes VBD's default.
On a chain, distances and steps no run used: does the carry make VBD's chain on that path play as at the origin, its
loss falling with the step, with nothing else of Study 23's made worse?

## The right answers

- A free chain's energy is constant. A consistent integrator's departure from it falls as the step shrinks, and does
  not depend on where in the world the chain is.
- A body spinning about its centre of mass keeps that centre still; a slide settles as the step shrinks; a cube pushed
  below its friction limit stays still.

## Engines and rigs

Newton 1.7.0 from PyPI (`newton==1.7.0`, Warp 1.18.0, MuJoCo Warp 3.15.0) as released, Study 7's environment, and
engines made from it by this run's `setup_engine.sh`, no fuzz, first on the path: **dsp**, the displacement patch alone
(Study 23's engine); and the displacement patch with the pose carry: **off** without `NEWTON_VBD_POSE_CARRY`, **on** with
it set to 1. `NEWTON_VBD_DISPLACEMENT=1` in every play. Rigs as committed at this registration: `tools/nwt_chain.py`
(its `x0`) and `tools/nwt_contact.py` (its `comx`, `wz0`, `matching`). Warp's CPU device. Measured by Senua AI's
`sx_contact` (`chain`: the largest energy departure in ppm; `creep`, `stop`) and judged by its `rule`.

## The scenes, registered parameters

None of these numbers was used in a run.

- **C, a free chain**: links of 1.3 and 0.7 kg, radius 0.04 m, the first's centre 0.24 m from the base hinge, the second
  hinge 0.48 m out and the second's centre 0.19 m beyond it, released at 0 and 0.6 rad turning at 2.1 and -1.2 rad/s,
  no gravity, 2 s; its base at 0, 15 and 60 m from the origin along x; at 0.4, 0.2, 0.1, 0.05 and 0.025 ms; on VBD's
  compliant-ALM path (`rigid_compliant_alm=True`) and, reported, its legacy path.
- **S, a spinning body** on the compliant-ALM path: a 1.4 kg cube of half-size 0.05 m whose box sits 0.025 m along its x
  from its origin, turning at 4.2 rad/s about z through its centre of mass, 1 m above the ground, no gravity, 1.2 s; at
  1.2, 0.24 and 0.06 ms.
- **L, a slide** on the compliant-ALM path: a 1.2 kg cube of half-size 0.045 m sent along the ground at 0.9 m/s at
  friction 0.35, 0.5 s; at 1.2, 0.24, 0.06 and 0.03 ms.
- **H, a hold** on the compliant-ALM path: a 1.1 kg cube of half-size 0.04 m resting on the ground at friction 0.45,
  pushed sideways from 0.3 s at 2.4255 N (50% of its friction's limit, gravity 9.8 m/s2 as the rig plays it), 1.2 s,
  with Study 17's contact history and sticky matching; at 1.2 and 0.06 ms.

Every scene played dsp, off and on.

## The rules

Each judged by `sx_contact rule`, from the measured lines, and nowhere else. "The departure" is C's largest energy
departure in ppm (`chain`'s `energy_largest_drift_ppm`); "far" is 15 and 60 m.

| Rule | Statement | Kind |
|---|---|---|
| R1 safe when off | Off, every play byte for byte dsp's | eq (count) |
| R2 the fault is there | Off, on the compliant-ALM path, C's departure at 0.025 ms at least twice the origin's, at 15 m and at 60 m | ge |
| R3 far as at the origin | On, on the compliant-ALM path, at each step, C's departure at 15 and at 60 m within 1 in 10 of the origin's at that step | all_within |
| R4 falls with the step | On, on the compliant-ALM path, at 0, 15 and 60 m, C's departure falls at each halving of the step | falls |
| R5 nothing else worse | On, S's centre within 3 um/s of still at every step; L's distance at 0.24 and 0.06 ms within 1 in 200 of its play at 0.03 ms; H within 10 um/s of still at both steps | all_in, all_within |
| R6 a number | Every play on a number throughout | all_eq |

Reported, not ruled: every reading, the legacy path's chain (run 125's notes: the carry held 10 m out but not 40 m out at
its two smallest steps), and S, L and H off and dsp.

## What it decides

When R1 to R6 hold, issue 12's VBD part is fixed on VBD's compliant-ALM path by Senua AI's VBD displacement and pose
carry patches together: the chain's loss falls with the step wherever the chain is. The legacy path, and XPBD's part
(a joint solve stable at full relaxation), stay open, and issue 12 stays open until they are resolved. A rule that fails
is reported as failed, and VBD's part stays open.
