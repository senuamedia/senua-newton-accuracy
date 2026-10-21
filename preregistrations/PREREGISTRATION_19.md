# Nineteenth pre-registration: VBD's legacy path holds a load at rest with its contacts carried

Registered 21 October 2026, after Study 17 (run 101). Registered before any play of this registration existed. To be
played once, as run 103, on Newton 1.7.0.

## The question

Issue 6 on VBD's legacy path (`SolverVBD`'s default in 1.7.0): a load inside the friction limit creeps, faster as the
step shrinks. Study 17 found Newton's own contact history with the collision pipeline's sticky contact matching holds
it still at every step, but its rule for the slide took the cold slide as its reference, and on this path the cold
slide is itself wrong, longer than Coulomb's distance by more as the step shrinks (F2): carrying the contacts moved the
slide toward Coulomb's distance at every step, and the rule failed. Here the same configuration on a cube, a load and
steps no study or probe used, the slide judged against the right answer.

## The right answers

- A body pushed with less force than its friction can hold does not move (Coulomb's law).
- A body sliding from v0 is stopped by friction in v0^2 / (2 mu g).

## Engines and rigs

Newton 1.7.0 from PyPI (`newton==1.7.0`, Warp 1.18.0, MuJoCo Warp 3.15.0) as released, Study 7's environment, no
patch: `SolverVBD` with its defaults, cold (as released) and carried (`SolverVBD(rigid_contact_history=True)` with
`CollisionPipeline(contact_matching="sticky")`, Newton's own options). Rigs as committed at this registration:
`tools/nwt_contact.py`. Warp's CPU device. Measured by Senua AI's `sx_contact` (`creep`, `stop`) and judged by its
`rule`.

## The scenes, registered parameters

None of these numbers was used in Study 17 or the probes.

- **H, a hold**: a 1.2 kg cube of half-size 0.05 m on the ground, friction 0.55, pushed by 4.851 N (0.75 of what
  friction holds) from 0.35 s, 1.4 s; at 2.5, 0.6 and 0.15 ms; cold and carried.
- **S, a slide**: the same cube from 0.7 m/s, friction 0.55, 0.5 s: Coulomb's distance 45,455 um; at the same steps,
  cold and carried.

## The rules

Each judged by `sx_contact rule`, from the measured lines, and nowhere else.

| Rule | Statement | Kind |
|---|---|---|
| R1 the fault is there | Cold, the hold creeps 1,000 um/s or more at every step | all_ge |
| R2 held | Carried, the hold within 10 um/s of still at every step | all_in |
| R3 the slide no further from the right answer | At every step the carried slide no further from Coulomb's 45,455 um than the cold slide | all_ge (the cold slide's distance from it less the carried's) |
| R4 a number | Every play a number throughout | all_eq |

Reported, not ruled: each slide against Coulomb's distance, the cube's tilt, every reading.

## What it decides

When R1 to R4 hold, issue 6 is fixed and validated on VBD's legacy path by Newton's own configuration, and with Study
17 on VBD. A rule that fails is reported as failed, and the part stays open.
