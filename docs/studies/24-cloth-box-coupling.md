# Study 24: a light cloth and a box coupled two-way, the feedback the force the cloth exerts

**Outcome: 14 of 14 rule lines held; issue 21's #4698 part fixed and validated** by Senua AI's VBD proxy coupling
patch. Registered 21 October 2026 ([`PREREGISTRATION_24.md`](../../preregistrations/PREREGISTRATION_24.md)); played
once as [run 119](../../validation/run_119_study_24/README.md).

## How it got here

| Run | What | Result |
|---|---|---|
| [112](../../validation/run_112_cloth_proxy/README.md) | #4698's scene on 1.7.0 | VBD harvests 13 to 168 times the cloth's weight for the box; fed back, the box is pressed into the ground and shaken |
| [116](../../validation/run_116_vbd_proxy_coupling/README.md) | The patch's first form: the rewind by gravity only, and the harvest as the cloth received it | The box under the cloth still, the feedback within 25% and 5%; an impact's momentum lost to the last substep and the proxy's own contact list |
| [118](../../validation/run_118_vbd_proxy_coupling_v2/README.md) | The second form: summed over substeps, every contact walked, an impact shared by its candidates | Momentum kept to 1 in 1,200, the feedback the cloth's exactly; a box on a held cloth thrown, where the explicit harvest with the rewind settles it |
| (the third form, checked on the host) | A deformable that pins hold keeps the explicit harvest | Every scene as wanted |

## The rules and the result

| Rule | Result |
|---|---|
| R1 safe when off | held: 10 of 10 plays byte for byte |
| R2 the fault is there as released | held, 4 lines: the feedback 19 and 139 times the cloth's force; momentum 3.5 and 10.9 times |
| R3 the feedback the cloth's force | held, 2 lines: 590 against 590 mN |
| R4 the box at rest under the cloth | held: 0 to 1 um/s |
| R5 momentum kept | held, 2 lines: within 1 in 430 and 1 in 2,900 |
| R6 the held cloth carries the box, no faster than it landed | held, 3 lines: 3,977 and 3,945 mN against 3,983 |
| R7 a number | held |

## What it decides

**#4698 (issue 21), fixed and validated:** [`vbd_proxy_coupling.diff`](../../patches/newton-1.7.0/vbd_proxy_coupling.diff),
switch `NEWTON_VBD_PROXY_COUPLING=2`: SolverVBD rewinds a proxy body by its gravity only (#4698's B, its author's fix,
written afresh) and harvests the contact force as the deformable received it (#4698's A). Issue 21's other report,
#4712 (the implicit MPM solver's colliders), stays open.
