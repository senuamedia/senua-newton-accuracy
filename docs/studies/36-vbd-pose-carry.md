# Study 36: VBD's chain far from the origin, its poses carried in two 32-bit numbers

**Outcome: 15 of 15 rule lines held; issue 12's VBD part fixed on VBD's compliant-ALM path.** Registered 21 October 2026
([`PREREGISTRATION_36.md`](../../preregistrations/PREREGISTRATION_36.md)); played once as
[run 139](../../validation/run_139_study_36/README.md). With Senua AI's VBD displacement patch alone, a free chain's
energy departure grows as the step shrinks once the chain is away from the origin (33,900 ppm at 0.025 ms 60 m out,
against 440 at the origin): VBD keeps each body's pose in 32 bits. With Senua AI's VBD pose carry as well, the chain 15
and 60 m out plays as at the origin within 2.2% at every step, and its departure falls with the step everywhere.

## How it got here

| Run | What | Result |
|---|---|---|
| [045](../../validation/run_045_vbd_chain_float32/README.md), [047](../../validation/run_047_vbd_chain_spacing/README.md), [049](../../validation/run_049_vbd_chain_spacing_release/README.md) | VBD's chain at small steps and away from the origin | The loss traced to its solve keeping poses in 32 bits |
| [114](../../validation/run_114_study_22/README.md) (Study 22) | The displacement patch on the chain | The loss falls with the step at the origin; a 32-bit cost 10 m out remains |
| [125](../../validation/run_125_far_chain_solvers/README.md)'s notes | The pose carry in design, then against the step at 0, 10 and 40 m on both VBD paths | On the compliant-ALM path the far chain as at the origin at every step; on the legacy path not at 40 m's two smallest steps |

## The rules and the result

| Rule | Result |
|---|---|
| R1 safe when off | held: 39 of 39 plays byte for byte the displacement patch's |
| R2 the fault is there | held: unset, 5,762 ppm at 15 m and 33,900 at 60 m at 0.025 ms, against 440 at the origin |
| R3 far as at the origin | held: set, within 1 in 10 of the origin's at every step (within 2.2%) |
| R4 falls with the step | held: set, 7,957, 4,042, 2,015, 999 and 462 ppm at the origin from 0.4 to 0.025 ms, the same within 2.2% at 15 and 60 m |
| R5 nothing else worse | held: the spinning body's centre still, the slide settling, the hold still |
| R6 a number | held |

## What it decides

**Issue 12's VBD part fixed on VBD's compliant-ALM path**, the path Newton 1.6 says becomes VBD's default, by
[`vbd_displacement.diff`](../../patches/newton-1.7.0/vbd_displacement.diff) (`NEWTON_VBD_DISPLACEMENT=1`) and
[`vbd_pose_carry.diff`](../../patches/newton-1.7.0/vbd_pose_carry.diff) (`NEWTON_VBD_POSE_CARRY=1`) together. On VBD's
legacy path the carry holds 15 m out but not 60 m out at the two smallest steps (reported); with XPBD's part, a joint
solve stable at full relaxation, issue 12 stays open.
