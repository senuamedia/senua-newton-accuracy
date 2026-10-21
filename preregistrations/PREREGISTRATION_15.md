# Fifteenth pre-registration: XPBD holds a load at rest

Registered 20 October 2026, after the design probes of runs 027, 044, 065, 082, 083 and 085. Registered before any play
of this registration existed. To be played once, as run 088, on Newton 1.7.0.

## The question

Issue 6, XPBD's part: a load inside the friction limit creeps on XPBD. Two causes, measured: the solve left unconverged
(the creep falls as one over the iteration count, run 027, run 083) and, under it, a floor that no iteration count
removes: each iteration's friction bounded by that iteration's normal correction (run 044), 1,531 and 380 um/s from 32
iterations on (run 085). Senua AI's friction patch bounds a contact's friction over the step by mu times its normal
correction summed over the step's iterations; with XPBD's speed floor removed (Study 10's patch) and 64 iterations it
held run 044's cube within 8 um/s (run 085). On a cube, a load and steps no probe used: does it hold?

## The right answer

A body pushed with less force than its friction can hold does not move (Coulomb's law); a body sliding is slowed by
friction at mu times the normal force, whatever holds it at rest.

## Engines and rigs

Newton 1.7.0 from PyPI as released, Study 7's environment, and two engines made from it by this run's
`setup_engine.sh`: Senua AI's speed-floor patch ([`xpbd_no_speed_floor_on_1.7.0.diff`](../patches/in_design/xpbd_no_speed_floor_on_1.7.0.diff),
validated by Study 10); the same with the friction patch in its form for that tree
([`xpbd_friction_total_on_nofloor.diff`](../patches/in_design/xpbd_friction_total_on_nofloor.diff), switch
`NEWTON_XPBD_FRICTION_TOTAL=1`). Rigs as committed at this registration: `tools/nwt_contact.py`, `tools/contact_suite.sh`.
Warp's CPU device. Measured by Senua AI's `sx_contact` (`creep`, `stop`, the first deep dive's suite runner for the
verdicts) and judged by its `rule`.

## The scenes, registered parameters

None of these numbers was used in the probes. XPBD in every play.

- **H, a hold**: a 2 kg cube of half-size 0.06 m on the ground, friction 0.6, pushed by 8.232 N (0.7 of what friction
  holds) from 0.4 s, 1.8 s, at 64 iterations, at 3 and 0.75 ms; as released, with the floor patch alone, with both. The
  creep is the mean speed over the run's second half; the right answer 0.
- **S, a slide**: the same cube from 0.8 m/s, friction 0.6, 1 s, at 64 iterations, at 3 and 0.75 ms; as released and
  with both.
- **T, the contact suite** on XPBD at its default iterations, as released and with both patches' switches set.

## The rules

| Rule | Statement | Kind |
|---|---|---|
| R1 safe when off | With both switches unset, the stacked tree's H plays byte for byte the release's | eq (count) |
| R2 the fault is there | As released, and with the floor patch alone, the hold creeps 100 um/s or more at both steps | all_ge |
| R3 held | With both patches the creep within 10 um/s of 0 at both steps | all_in |
| R4 the slide kept | With both patches the slide within 1 in 100 of the release's at both steps | within |
| R5 nothing lost | Every suite verdict that passes as released passes with both patches | eq (count) |

Reported, not ruled: the slide against Coulomb's distance v^2 / (2 mu g), and every reading.

## What it decides

When R1 to R5 hold, issue 6 is fixed and validated on XPBD by the friction patch with the speed floor removed and 64
iterations, the iterations a configuration XPBD needs for its solve to converge. A rule that fails is reported as
failed, and the part stays open.
