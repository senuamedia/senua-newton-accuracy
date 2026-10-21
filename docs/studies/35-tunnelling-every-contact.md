# Study 35: a fast body kept from passing through a thin slab, every contact given its normal

**Outcome: 6 of 6 rule lines held; issue 20's tunnelling fixed on Newton's own solvers.** Registered 21 October 2026
([`PREREGISTRATION_35.md`](../../preregistrations/PREREGISTRATION_35.md)); played once as
[run 138](../../validation/run_138_study_35/README.md). As released XPBD, SemiImplicit and Featherstone let a cube
through a 4 mm slab in every scene; with Newton's own configuration XPBD, and with Senua AI's speculative normal patch
SemiImplicit and Featherstone, keep it on the slab in every scene, the slides within 1 in 540 of Coulomb's distance and
the holds still.

## How it got here

| Run | What | Result |
|---|---|---|
| [060](../../validation/run_060_tunnelling/README.md) | A fast cube onto a thin slab | Through wherever a step carries it past; speculative contacts changed nothing |
| [136](../../validation/run_136_study_33/README.md) (Study 33) | The first form, on contacts still apart | 6 of 8: kept, but a slide's touching start carried without friction for a step |
| [137](../../validation/run_137_study_34/README.md) (Study 34) | The third form, on contacts strictly apart | 7 of 8: slides kept, but a cube landing touching at speed through |
| (host checks) | Featherstone with the friction cone counting the impulse | Its rotation grew sweep after sweep: the inertia built where the step left the joints; rebuilt each sweep, it converges |

## The rules and the result

| Rule | Result |
|---|---|
| R1 safe when off | held: 8 of 8 plays byte for byte |
| R2 the fault is there as released | held: all three through in every scene at both steps |
| R3 kept | held: none through; at rest on the slab within 34 nm at 1 ms (XPBD within 7 nm everywhere); at 3 ms SemiImplicit's and Featherstone's cube thrown back up |
| R4 the slide and the hold right | held: within 1 in 540 of Coulomb's distance; 6, 1 and 1 um/s |
| R5 a number | held |

## What it decides

**Issue 20's tunnelling fixed on Newton's own solvers**: XPBD by Newton's own configuration (64 iterations and
speculative contacts), SemiImplicit and Featherstone by [`speculative_normal.diff`](../../patches/newton-1.7.0/speculative_normal.diff)
(`NEWTON_SPECULATIVE_NORMAL=1`) with speculative contacts. The MuJoCo solver goes through regardless (MuJoCo's contact).
Issue 20's force calibration, grasps and point clouds need a GPU and stay unplayed.
