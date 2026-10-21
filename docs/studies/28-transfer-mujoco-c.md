# Study 28: one model across engines, MuJoCo C as the reference

**Outcome: 14 of 18 rule lines held; issue 22 stays open.** Registered 21 October 2026
([`PREREGISTRATION_28.md`](../../preregistrations/PREREGISTRATION_28.md), amended before any play); played once as
[run 131](../../validation/run_131_study_28/README.md). With the record's friction chains, XPBD, SemiImplicit and
Featherstone play MuJoCo C's slide and hold at 1 and 0.5 ms and its push at 0.5 ms; at 1 ms MuJoCo C's own push is 4.5%
slow, and Newton's three, right there within 1 in 800, were ruled against it.

## How it got here

| Run | What | Result |
|---|---|---|
| [059](../../validation/run_059_friction_combination/README.md) | One model, two frictions, by solver | Within Newton one scene slides 92.5 mm on XPBD and 56.9 mm on the MuJoCo solver; fixed by Study 26 |
| [066](../../validation/run_066_mujoco_cpu_path/README.md), Study 11 | The MuJoCo solver's CPU path, MuJoCo C | Plays the record's scenes as the Warp path does; with noslip it holds |

## The rules and the result

| Rule | Result |
|---|---|
| R1 the reference is right | slide and hold: held; push: **failed**, MuJoCo C 1.8955 m/s at 1 ms against 1.9845 (1.9943 at 0.5 ms) |
| R2 the fault is there as released | held: one or more of the three departs from MuJoCo C at both steps |
| R3 the slide transfers | held, six lines: within 1 in 300 of MuJoCo C's |
| R4 the hold transfers | held: 0 to 6 um/s |
| R5 the push transfers | held at 0.5 ms; **failed at 1 ms**, three lines, against MuJoCo C's slow push |
| R6 a number | held |

## What it decides

**Issue 22 stays open.** After the run (not registered): MuJoCo C's push at 1 ms is the same bytes with noslip at 10 or
50 iterations or none; its elliptic cone's friction rises with the cube's speed, the pyramidal cone ends 1% slow. The
divergence at 1 ms is MuJoCo's soft friction; Newton's three play the model right at both steps.
