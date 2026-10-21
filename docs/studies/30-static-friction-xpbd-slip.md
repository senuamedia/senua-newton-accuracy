# Study 30: a static friction coefficient imported and applied, XPBD's slip seen whole

**Outcome: 16 of 16 rule lines held; issue 18 resolved.** Registered 21 October 2026
([`PREREGISTRATION_30.md`](../../preregistrations/PREREGISTRATION_30.md)); played once as
[run 133](../../validation/run_133_study_30/README.md). With pull request #4306, Senua AI's static friction patch and its
XPBD friction slip patch, a USD material's static friction reaches the model, and XPBD, SemiImplicit and Featherstone
hold a cube pushed between its limits at 1 and 0.25 ms, imported or built, and play the dynamic coefficient once it
slides; the MuJoCo solver and VBD say they do not apply it.

## How it got here

| Run | What | Result |
|---|---|---|
| [129](../../validation/run_129_static_friction/README.md) | The static coefficient on XPBD, SemiImplicit and Featherstone, a design probe | 10 of 10: held between the limits, the dynamic coefficient once sliding |
| [130](../../validation/run_130_study_27/README.md) (Study 27) | The same with the USD import, registered | 13 of 16: XPBD 12 um/s at 0.25 ms, its own floor with or without the patch |
| (after run 130, host checks) | Why XPBD creeps | Its slip measured from 32-bit world positions; carried per body it falls to 7 um/s, a stopped slide still |

## The rules and the result

| Rule | Result |
|---|---|
| R1 safe when off | held: 60 of 60 plays byte for byte the chain's |
| R2 the fault is there as released | held: the hold and the import depart from rest by 9 mm/s or more; 12 of 12 imports drop the coefficient |
| R3 held | held: XPBD 1 and 7 um/s, SemiImplicit and Featherstone 0 |
| R4 kinetic on the dynamic | held: within 1 in 2,300 of 2.26 m/s |
| R5 breaks away | held: within 1 in 340 of 4.41 m/s |
| R6 slides on the dynamic | held, six lines: within 1 in 1,060 of the chain's slide |
| R7 imported and applied | held: 0.75 in 24 of 24 models; the imported cube held as the built one |
| R8 the others say so | held: 204 of 204 plays |
| R9 a number | held |

## What it decides

**Issue 18 resolved:** its combination by Study 26, its static coefficient and import by this study.
[`static_friction.diff`](../../patches/newton-1.7.0/static_friction.diff) (`NEWTON_STATIC_FRICTION=1`) and
[`xpbd_friction_slip.diff`](../../patches/newton-1.7.0/xpbd_friction_slip.diff) (`NEWTON_XPBD_FRICTION_SLIP=1`), on
the record's friction chains and pull request #4306. VBD and the MuJoCo solver warn instead of applying it.
