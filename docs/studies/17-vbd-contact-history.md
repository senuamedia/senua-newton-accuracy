# Study 17: VBD holds a load at rest with its contacts carried from step to step

**Outcome: 8 of 11 rule lines held; issue 6 fixed and validated on VBD-ALM** by Newton's own configuration, its contact
history with the collision pipeline's sticky contact matching. On VBD's legacy path the hold is held too, but its
slide changes (toward Coulomb's distance), and the rule that asked it to stay the same failed. Registered 21 October
2026 ([`PREREGISTRATION_17.md`](../../preregistrations/PREREGISTRATION_17.md)); played once as
[run 101](../../validation/run_101_study_17/README.md).

## How it got here

| Run | What | Result |
|---|---|---|
| [089](../../validation/run_089_vbd_hold/README.md), [091](../../validation/run_091_vbd_alm_hold_steps/README.md) | VBD's and VBD-ALM's hold against the step | VBD creeps faster as the step shrinks; VBD-ALM holds at large steps and creeps at small ones |
| [095](../../validation/run_095_vbd_friction_epsilon/README.md) | VBD's `friction_epsilon` and iterations | The option does not reach its rigid contact, AVBD's penalty-and-multiplier Coulomb projection; the creep falls with the iterations |
| [098](../../validation/run_098_vbd_contact_history/README.md) | Newton's contact history with latest and sticky matching | Sticky matching holds both paths at every step to 0.0625 ms |

## The rules and the result

| Rule | Result |
|---|---|
| R1 the fault is there, cold | held: VBD 24,971 to 400,648 um/s; VBD-ALM 308 um/s at 0.08 ms |
| R2 held, carried | held: 0 um/s on both paths at every step |
| R3 the slide within 1 in 100 of the cold slide | held on VBD-ALM; **failed on VBD**: the carried slide nearer Coulomb's distance than the cold one at every step |
| R4 a number | held |

## What it decides

**Issue 6 on VBD-ALM, fixed and validated** by `SolverVBD(rigid_compliant_alm=True, rigid_contact_history=True)` with
`CollisionPipeline(contact_matching="sticky")`, the path Newton's documentation says will become VBD's default. On
VBD's legacy path issue 6 stays open, for a registration judging its slide against Coulomb's distance.
