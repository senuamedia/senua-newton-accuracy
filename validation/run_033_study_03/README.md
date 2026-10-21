# Run 033: Study 3, played once

15 October 2026, 09:40 to 09:45 UTC, on the Newton host, by [`play.sh`](play.sh), under
[`PREREGISTRATION_03.md`](../../preregistrations/PREREGISTRATION_03.md), registered and pushed with the runner before
any play. The runner's dry run (`dry/`, throwaway parameters, the on arm only) ran to the end first; no rule was read
from it. Measured by Senua AI's `sx_contact` (`bounce`, `creep`, `rest`, `pull`), judged by its `rule` (`rules.txt`);
the measured lines and the rules were re-made byte for byte on the laptop from the kept files. In the logs the home
folder is written `~/`.

## The result: 9 of 9 rule lines held

| Rule | Measured | |
|---|---|---|
| R1 safe when off | 32 of 32 files byte-identical (off to stock) | held |
| R2 the rebound is there | unit (Study 1's patch alone): the drop rebounds 184 and 285 per 10,000 at 0.75 and 0.375 ms, on both solvers | held |
| R3 no rebound | on: 0 per 10,000 at all five ruled steps (6 ms to 0.375 ms), on both solvers | held |
| R4 the slide | on: friction over the normal force 3,499 and 3,500 per 10,000 (Coulomb's 3,500), on both solvers | held |
| R5 the rest | on: the ground carries 29,400 mN at both steps, the weight | held |
| R6 the lift | on: the ground's lowest force 0, it never pulls | held |
| R7 the hold | on: 1,985 and 1,984 um/s at 0.2 and 0.1 ms (the viscous law's 1,985) on both solvers | held |
| R8 other solvers | XPBD's drop with both switches set is stock's byte for byte | held |
| R9 nothing blows up | No play of unit or on stopped being a number | held |

| A 3 kg cube dropped 70 mm, no restitution: rebound per 10,000 of the height | 6 ms | 3 ms | 1.5 ms | 0.75 ms | 0.375 ms |
|---|---|---|---|---|---|
| Newton as released (both solvers) | 0 | 134 | 259 | 184 | 285 |
| With Study 1's patch alone | 0 | 134 | 259 | 184 | 285 |
| **With this patch and Study 1's** | **0** | **0** | **0** | **0** | **0** |

Reported, not ruled, with the registration's reason:

- **The drop at 12 ms and 15 ms** (4 kd h / m of 1.6 and 2.0, past the damper's monotone limit): 5,509 and 16,645 per
  10,000 in every arm, byte for byte the release, as run 021 found: the damper throws the cube in its first contact
  step, before the contact opens.
- **The hold at 0.75 ms** (10 kf h / m of 2.5, where friction does not settle): stock -89 (SemiImplicit) and -244
  (Featherstone) um/s, Study 1's patch 2,790, both patches 2,841: a chatter's speed, not the creep of a steady friction.
- Study 1's patch alone gives the slide 3,499 and 3,500, the rest 29,400 mN, the lift 0 and the hold 1,984 um/s at the
  ruled steps: this patch leaves them as they are. Newton as released reads the slide's ratio as -298 and 56: the
  stock friction (F1) pitches the cube.

## What it shows

**The patch is validated within its range.** On scenes and steps no probe used, with Study 1's patch, SemiImplicit's
and Featherstone's normal contact damped in both phases and kept from pulling removes the rebound a body dropped with no
restitution makes as released, at every step where Newton's explicit integration of the contact damper is inside its
monotone limit, and changes nothing else measured there: Coulomb's slide, the weight at rest, a lift that never pulls,
the steady hold. With its switch unset, Newton plays byte for byte as released; XPBD is untouched. Above the limit
(here 7.5 ms on a 3 kg cube) the integration, not the contact law, decides, and the patch is not reached.
