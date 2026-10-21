# Run 072: Study 11, played once

20 October 2026, 10:29 to 10:31 UTC, on the Newton host, by [`play.sh`](play.sh), under
[`PREREGISTRATION_11.md`](../../preregistrations/PREREGISTRATION_11.md), registered and pushed with the runner before
any play. The runner's dry run (`dry/`, throwaway parameters) ran to the end first; no rule was read from it. Played from
the record at its commit 94b9478, on Newton 1.7.0 and the two engines made by [`setup_engine.sh`](setup_engine.sh).
Measured by Senua AI's `sx_contact` (`creep`, `stop`, `rest`, `final`, `swing`) and judged by its `rule`
(`rules.txt`). In the logs the home folder is written `~/`.

## The result: 21 of 21 rule lines held

| Rule | Measured | |
|---|---|---|
| R1 safe when off (15) | With noslip unset, the hold's two files byte for byte the release's | held |
| R2 the fault is there (15, 6) | The elliptic cone alone on the CPU path: the hold creeps 1,241 um/s at 1 and 4 ms | held |
| R3 held (15, 6) | With noslip: 0 um/s at both steps | held |
| R4 the slide kept | With noslip 54,488 and 53,077 um against 54,499 and 53,085 without | held, both lines |
| R5 the weight kept | With noslip the ground carries 7,840 mN at both steps, the weight | held |
| R6 the CPU path's contacts (24) | The drop: 7,840 mN on both paths at both steps | held, both lines |
| R7 the CPU path's forces (24) | The push: 60,001 and 60,000 um/s on both paths (60,000) | held |
| R8 the CPU path's joint force (24) | The torque: 2,903 and 3,116 urad on both paths at 1 and 4 ms | held, both lines |
| R9 the CPU path plays (24) | Every one of its 18 plays a number throughout | held |
| R10 safe when off (16) | With the switch unset, the four strikes byte for byte the release's | held |
| R11 the fault is there (16) | As released the arm turns back at -0.630 and -0.631 rad (0.3 kg) and -0.349 and -0.351 rad (2 kg), against -0.572 and -0.327 | held, 4 lines |
| R12 kept from pulling (16) | At `=1`: -0.570 and -0.579 rad (0.3 kg), -0.331 and -0.334 rad (2 kg) | held, 4 lines |

| The hold, mean creep over the second half, um/s (the answer 0) | 1 ms | 4 ms |
|---|---|---|
| The CPU path, elliptic cone, as released | 1,241 | 1,241 |
| The patch's tree, noslip unset | 1,241 | 1,241 |
| **The CPU path, elliptic cone, 5 noslip iterations** | **0** | **0** |

| The strike, where the arm turns back, rad | 0.3 kg, 0.2 ms | 0.3 kg, 0.05 ms | 2 kg, 0.2 ms | 2 kg, 0.05 ms |
|---|---|---|---|---|
| As released | -0.630 | -0.631 | -0.349 | -0.351 |
| **`NEWTON_FEATHERSTONE_LIMIT=1`** | **-0.570** | **-0.579** | **-0.331** | **-0.334** |
| Kept from pulling (the closed form) | -0.572 | -0.572 | -0.327 | -0.327 |

The torque's 2,903 and 3,116 urad are the closed form 2,832 times semi-implicit Euler's (n + 1) / n at 40 and 10
steps, on both paths.

## What it shows

- **Issue 15 is fixed and validated on the MuJoCo solver's CPU path** by Senua AI's noslip patch (second form): with
  the elliptic cone and noslip, MuJoCo's recommended configuration, a cube pushed at 0.7 of what friction holds does
  not move, where the elliptic cone alone creeps 1,241 um/s; a slide and the weight are kept. On the MuJoCo Warp path
  noslip waits on MuJoCo Warp, which refuses it.
- **The MuJoCo solver's part of issue 6 is fixed and validated** by the same configuration on the CPU path.
- **Issue 24: the reported faults are not there on Newton 1.7.0.** The CPU path's contacts, applied forces and joint
  forces give the Warp path's readings in every scene, and every play is a number; it takes one world, by its own code.
- **Issue 16 is fixed and validated on Featherstone** by the limit patch's first form: the strike turns back within
  0.007 rad of the no-tension spring-dashpot, where as released the limit pulls the arm 0.02 to 0.06 rad lower. Its
  SemiImplicit part, which the patch does not change, stays open.
