# Study 23: VBD's spinning body still, its contacts settling, in displacement form

**Outcome: 7 of 7 rule lines held; issue 13 fixed and validated on VBD-ALM and VBD** by Senua AI's VBD displacement
patch, and with Study 9 on the MuJoCo solver, issue 13 resolved. Registered 21 October 2026
([`PREREGISTRATION_23.md`](../../preregistrations/PREREGISTRATION_23.md)); played once as
[run 117](../../validation/run_117_study_23/README.md).

## How it got here

| Run | What | Result |
|---|---|---|
| [104](../../validation/run_104_vbd_spin_iterations/README.md), [108](../../validation/run_108_vbd_spin_forward_step/README.md) | Where VBD's spinning body's drift comes from | The velocity read back from 32-bit poses, and the solve's own writes of the pose |
| [111](../../validation/run_111_vbd_displacement/README.md) | The displacement form | The centre still at every step; contacts kept |
| [114](../../validation/run_114_study_22/README.md), Study 22 | The patch for issues 13 and 12 | Not validated: the centre still (R3) and the chain's loss falling with the step at the origin, but 10 m out a second 32-bit cost, and the slide 1.4% from the release's at 0.075 ms |
| [115](../../validation/run_115_vbd_displacement_slide/README.md) | VBD-ALM's slide as the step shrinks | As released it comes apart (13% short, or never stopping); with the patch it settles within 0.14%: Study 22's comparison was with a release that carries F2's fault |

## The rules and the result

| Rule | Result |
|---|---|
| R1 safe when off | held: 16 of 16 plays byte for byte |
| R2 the fault is there as released | held: 8,249 um/s at 0.06 ms |
| R3 the centre still | held: 0 um/s at every step on both paths |
| R4 the slides settle | held, 2 lines: within 0.1% from 0.24 ms down |
| R5 the hold kept | held |
| R6 a number | held |

## What it decides

**Issue 13, fixed and validated on VBD-ALM and VBD:** [`vbd_displacement.diff`](../../patches/newton-1.7.0/vbd_displacement.diff),
switch `NEWTON_VBD_DISPLACEMENT=1`. With Study 9 (the MuJoCo solver's RK4), issue 13 is resolved. Issue 12's VBD part,
for which Study 22 did not validate the patch, stays open: the patch makes the chain's loss fall with the step at the
origin, but away from it the joints' 32-bit evaluation leaves a floor at the smallest steps.
