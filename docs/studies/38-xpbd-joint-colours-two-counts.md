# Study 38: XPBD's joints solved colour by colour, at full relaxation, at two iteration counts

**Outcome: 12 of 12 rule lines held; issue 12's XPBD part fixed for a free chain.** Registered 21 October 2026
([`PREREGISTRATION_38.md`](../../preregistrations/PREREGISTRATION_38.md)); played once as
[run 141](../../validation/run_141_study_38/README.md). With Senua AI's joint colours, XPBD's joint pass a Gauss-Seidel
sweep over colours of joints sharing no body, and XPBD's own relaxation options at 1.0, a free chain's loss falls with
every halving of the step at 8 and at 32 iterations, to 552 and 489 ppm at 0.1 ms, where as released it is 9,587 and
barely falls as the step shrinks; as released, full relaxation diverges.

## How it got here

| Run | What | Result |
|---|---|---|
| [014](../../validation/run_014_chain/README.md) | The free chain on every solver | XPBD loses 30% in 2 s at 10 ms |
| [125](../../validation/run_125_far_chain_solvers/README.md)'s notes | XPBD's relaxations; joint averaging; joint colours | Full relaxation diverges as released; averaging gains 12%; colours stable |
| [140](../../validation/run_140_study_37/README.md) (Study 37) | Colours at 32 iterations, with a convergence rule | 8 of 9: the loss falls with the step; 32 iterations not converged, and the host check after it found the departure does not settle with the iterations (4,119 ppm at 256, 6,300 at 512) |

## The rules and the result

| Rule | Result |
|---|---|
| R1 safe when off | held: 7 of 7 plays byte for byte |
| R2 the fault is there | held: stock at full relaxation diverges at 8 and 32 iterations |
| R3 falls with the step | held: at 8 iterations 21,486 to 552 ppm, at 32 21,341 to 489 ppm, from 1.6 to 0.1 ms |
| R4 better than released | held: at most half of stock's at its defaults at 0.4, 0.2 and 0.1 ms at either count |
| R5 one joint unchanged | held |
| R6 a number | held |

## What it decides

**Issue 12's XPBD part is fixed for a free chain** by [`xpbd_joint_colours.diff`](../../patches/newton-1.7.0/xpbd_joint_colours.diff)
(`NEWTON_XPBD_JOINT_COLOURS=1`) with `joint_linear_relaxation` and `joint_angular_relaxation` at 1.0. A chain swinging
under gravity, reported, still loses energy on XPBD (46,882 ppm at 0.1 ms with the colours, 59,756 without).
