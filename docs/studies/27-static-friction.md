# Study 27: a static friction coefficient imported from USD and applied

**Outcome: 13 of 16 rule lines held; issue 18's static part stays open.** Registered 21 October 2026
([`PREREGISTRATION_27.md`](../../preregistrations/PREREGISTRATION_27.md)); played once as
[run 130](../../validation/run_130_study_27/README.md). The static coefficient is imported from a USD physics material
(pull request #4306) and applied by SemiImplicit and Featherstone at both steps, and by XPBD at 1 ms; at 0.25 ms XPBD
creeps 12 um/s against the 10 registered, its own floor at that step, the same with the static patch or without it.

## How it got here

| Run | What | Result |
|---|---|---|
| (the source, 1.7.0) | One coefficient per shape | No static coefficient anywhere; a USD material's `staticFriction` dropped by the importer |
| [129](../../validation/run_129_static_friction/README.md) | Pull request #4306's coefficient applied by the needed-impulse rule on XPBD, SemiImplicit and Featherstone | 10 of 10: held between the limits, the dynamic coefficient once sliding; the MuJoCo solver warns |
| (host checks) | VBD by the same rule | Neither VBD path holds: its friction decides on the solve's iterate; VBD warns instead, as the MuJoCo solver does |

## The rules and the result

| Rule | Result |
|---|---|
| R1 safe when off | held: 60 of 60 plays byte for byte the chain's |
| R2 the fault is there as released | the import: held (12 of 12 models without the coefficient); the hold: **failed as registered**, SemiImplicit and Featherstone at 0.25 ms moving backward at 5.4 to 6.4 mm/s, not sliding on |
| R3 held | **failed**: XPBD 3 and 12 um/s at 1 and 0.25 ms; SemiImplicit and Featherstone 0 |
| R4 kinetic on the dynamic | held: within 1 in 340 of 2.36 m/s |
| R5 breaks away | held: within 1 in 440 of 4.41 m/s |
| R6 slides on the dynamic | held, six lines: within 1 in 1,050 of the chain's slide |
| R7 imported and applied | the coefficient: held (24 of 24 models read 0.7); the hold: **failed**, as R3 (XPBD 12 um/s at 0.25 ms) |
| R8 the others say so | held: 204 of 204 plays warn where registered and nowhere else |
| R9 a number | held |

## What it decides

**Issue 18's static part stays open**: the import is fixed (#4306), and the coefficient held by SemiImplicit and
Featherstone at both steps; XPBD's hold at 0.25 ms is above the bar. After the run (not registered): XPBD's chain alone,
pushed below its dynamic limit at 0.25 ms, creeps the same 12 um/s at 64 to 256 iterations, so what fails is XPBD's
floor at that step, not the static rule.
