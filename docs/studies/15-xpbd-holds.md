# Study 15: XPBD holds a load at rest

**Outcome: 6 of 6 rule lines held; issue 6 fixed and validated on XPBD** by Senua AI's friction patch, with Study 10's
speed-floor patch and 64 iterations. Registered 20 October 2026 ([`PREREGISTRATION_15.md`](../../preregistrations/PREREGISTRATION_15.md));
played once as [run 088](../../validation/run_088_study_15/README.md).

## How it got here

| Run | What | Result |
|---|---|---|
| [027](../../validation/run_027_xpbd_creep_iterations/README.md), [044](../../validation/run_044_xpbd_creep_floor/README.md) | XPBD's creep at rest | Most of it the solve unconverged; under it a floor, the friction bounded by each iteration's normal correction |
| [082](../../validation/run_082_xpbd_friction_total/README.md), [083](../../validation/run_083_xpbd_hold_iterations/README.md) | The friction bounded on the step's totals | Still at 32 iterations; unchanged at the default 2 |
| [085](../../validation/run_085_xpbd_hold_nofloor/README.md) | The same with the speed floor removed | Within 8 um/s from 64 iterations; the release at its floor at any count |

## The rules and the result

| Rule | Result |
|---|---|
| R1 safe when off | held |
| R2 the fault is there: as released and with the floor patch alone, 100 um/s or more | held: 3,415 and 854 um/s |
| R3 held within 10 um/s | held: 0 and 4 um/s |
| R4 the slide within 1 in 100 of the release's | held: to 0.02% |
| R5 no suite verdict lost | held |

## What it decides

**Issue 6 on XPBD, fixed and validated:** [`xpbd_friction_total.diff`](../../patches/newton-1.7.0/xpbd_friction_total.diff)
(the friction patch in its form for the speed-floor patch's tree), switches `NEWTON_XPBD_NO_SPEED_FLOOR=1` and
`NEWTON_XPBD_FRICTION_TOTAL=1`, and `iterations=64`. Issue 6 stays open on SemiImplicit, Featherstone and VBD.
