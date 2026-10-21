# Study 37: XPBD's joints solved colour by colour, at full relaxation

**Outcome: 8 of 9 rule lines held; R4 failed, issue 12's XPBD part open.** Registered 21 October 2026
([`PREREGISTRATION_37.md`](../../preregistrations/PREREGISTRATION_37.md)); played once as
[run 140](../../validation/run_140_study_37/README.md). Senua AI's joint colours make XPBD's joint pass a Gauss-Seidel
sweep over colours of joints sharing no body. At XPBD's own full relaxation the free chain is stable (as released it
diverges at every iteration count) and its loss falls with every halving of the step, 24,779 to 717 ppm, seven times
below the released solver's at 0.1 ms; but at 0.4 ms 32 iterations depart by 4,178 ppm against 3,615 at 128, so the
solve at 32 is not converged within the registered 1 in 10.

## How it got here

| Run | What | Result |
|---|---|---|
| [014](../../validation/run_014_chain/README.md) | The free chain on every solver | XPBD loses 30% in 2 s at 10 ms |
| [125](../../validation/run_125_far_chain_solvers/README.md)'s notes | XPBD's relaxations; joint averaging; joint colours | At full relaxation the released solve diverges; averaging is stable but gains 12%; colours are stable and the loss falls with the step |

## The rules and the result

| Rule | Result |
|---|---|
| R1 safe when off | held: 9 of 9 plays byte for byte |
| R2 the fault is there | held: stock at full relaxation diverges at 2, 8, 32 and 128 iterations |
| R3 falls with the step | held: 24,779, 11,852, 4,178, 1,408 and 717 ppm from 1.6 to 0.1 ms |
| R4 converged | **failed**: 3,615 ppm at 128 iterations against 4,178 at 32 |
| R5 better than released | held: at most half of stock's at its defaults at 0.4, 0.2 and 0.1 ms |
| R6 one joint unchanged | held |
| R7 a number | held |

## What it decides

Not validated; issue 12's XPBD part stays open. A chain swinging under gravity is reported: the colours about halve its
departure at the finest step (57,009 against 112,988 ppm) but do not keep its energy.
