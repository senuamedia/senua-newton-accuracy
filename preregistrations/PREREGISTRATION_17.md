# Seventeenth pre-registration: VBD holds a load at rest with its contacts carried from step to step

Registered 21 October 2026, after the design probes of runs 089, 091, 095 and 098. Registered before any play of this
registration existed. To be played once, as run 101, on Newton 1.7.0.

## The question

Issue 6, VBD's part: a load inside the friction limit creeps on VBD, faster as the step shrinks (run 089: 12, 58 and
223 mm/s at 2, 0.5 and 0.125 ms), and on VBD-ALM at small steps (run 091: 99, 74 and 225 um/s at 0.25, 0.125 and
0.0625 ms). VBD's rigid contact friction is AVBD's Coulomb projection of a penalty times the slip plus a multiplier
(run 095); Newton's VBD starts every contact cold each step unless its `rigid_contact_history` is set, with the
collision pipeline's contact matching to restore each contact's state, sticky matching carrying a persistent friction
anchor (Newton's documentation). With both, VBD-ALM and VBD held run 044's cube still at every step from 2 to 0.0625 ms,
and the slide was the same as cold (run 098). On a cube, a load and steps no probe used: does it hold?

## The right answer

A body pushed with less force than its friction can hold does not move (Coulomb's law).

## Engines and rigs

Newton 1.7.0 from PyPI (`newton==1.7.0`, Warp 1.18.0, MuJoCo Warp 3.15.0) as released, Study 7's environment, no
patch: the configuration is Newton's own, `SolverVBD(rigid_contact_history=True)` with
`CollisionPipeline(contact_matching="sticky")`. Rigs as committed at this registration: `tools/nwt_contact.py` (its
`matching` option). Warp's CPU device. VBD as `SolverVBD` with its defaults (its legacy path, the default in 1.7.0) and
VBD-ALM as `SolverVBD(rigid_compliant_alm=True)`, the path Newton's documentation says will become the default.
Measured by Senua AI's `sx_contact` (`creep`, `stop`) and judged by its `rule`.

## The scenes, registered parameters

None of these numbers was used in the probes.

- **H, a hold**: a 1.4 kg cube of half-size 0.045 m on the ground, friction 0.45, pushed by 4.0131 N (0.65 of what
  friction holds) from 0.3 s, 1.5 s; at 1.5, 0.3 and 0.08 ms; on VBD and VBD-ALM, cold (as released) and carried
  (`opt.rigid_contact_history=true matching=sticky`).
- **S, a slide**: the same cube from 0.9 m/s, friction 0.45, 0.5 s; the same steps, paths and settings.

## The rules

Each judged by `sx_contact rule`, from the measured lines, and nowhere else.

| Rule | Statement | Kind |
|---|---|---|
| R1 the fault is there | Cold, VBD's hold creeps 1,000 um/s or more at every step, and VBD-ALM's 10 um/s or more at 0.08 ms | all_ge, ge |
| R2 held | Carried, both paths' holds within 10 um/s of still at every step | all_in |
| R3 the slide kept | Carried, both paths' slides within 1 in 100 of the cold slide at the same step | within |
| R4 a number | Every play a number throughout | all_eq |

Reported, not ruled: the slides against Coulomb's distance v^2 / (2 mu g) (VBD-ALM's slide runs past it cold and
carried alike, run 098, a finding of its own), the cube's tilt, every reading.

## What it decides

When R1 to R4 hold, issue 6 is fixed and validated on VBD and VBD-ALM by Newton's own configuration: its contact
history with the collision pipeline's sticky contact matching. A rule that fails is reported as failed, and the part
stays open.
