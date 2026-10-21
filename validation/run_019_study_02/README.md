# Run 019: Study 2, played once

15 October 2026, 05:17 to 05:19 UTC, on the Newton host, by [`play.sh`](play.sh), under
[`PREREGISTRATION_02.md`](../../preregistrations/PREREGISTRATION_02.md), registered and pushed with the runner before
any play. The runner's dry run (`dry/`, throwaway parameters, stock_res only) ran to the end first; no rule was read
from it. Measured by Senua AI's `sx_contact` (`bounce`, `impact`, `settle`), judged by its `rule` (`rules.txt`); the
measured lines and the rules were re-made byte for byte on the laptop from the kept files.

## The result: 9 of 9 rule lines held

| Rule | Measured | |
|---|---|---|
| R1 safe when off | 20 of 20 files byte-identical (off_plain to stock_plain, off_res to stock_res) | held |
| R2 the bounce is there | stock_plain: the drop rebounds 850 and 1,067 per 10,000 of its height at 4 ms and 0.4 ms | held |
| R2 friction is lost | stock_res: friction over the impact 300 and 1,980 per 10,000 (Coulomb's 3,500) | held |
| R3 no bounce | on_res: 0 and 0 | held |
| R4 the impact | on_res: 3,499 and 3,499 | held |
| R5 after the impact | on_res: 3,499 and 3,499 over the impact and the 0.1 s after it | held |
| R6 nothing else changes | on_res: the slide, the rest and the push at both steps, 6 of 6 files byte-identical to stock_res | held |
| R7 nothing when the pass does not run | on_plain: 10 of 10 files byte-identical to stock_plain | held |
| R8 nothing blows up | No play's state stopped being a number | held |

| A 1.4 kg cube, restitution 0, friction 0.35 | 4 ms | 0.4 ms |
|---|---|---|
| Rebound of a 60 mm drop, per 10,000: XPBD as released | 850 | 1,067 |
| The same, with `enable_restitution` | 0 | 0 |
| The same, with the patch | **0** | **0** |
| Friction over the impact (2.5 m/s sideways), per 10,000 (Coulomb's 3,500): as released | 3,499 | 3,500 |
| With `enable_restitution` | 300 | 1,980 |
| With the patch | **3,499** | **3,499** |
| Over the impact and the 0.1 s after it: as released | 3,499 | 3,499 |
| With `enable_restitution` | 1,826 | 3,283 |
| With the patch | **3,499** | **3,499** |

Reported, not deciding, the cube's largest turn in the oblique impact: 346,395 and 393,977 urad as released; 5,027
and 2,490 with `enable_restitution`; 4,784 and 10,125 with the patch.

## What it shows

**The patch is validated.** On scenes and steps no probe used, XPBD with its own `enable_restitution` and the patch
(`NEWTON_XPBD_RESTITUTION_FRICTION=2`) has no bounce with a restitution of 0 and gives Coulomb's friction at an impact
and after it, to 1 part in 3,500. As released, XPBD keeps Coulomb's friction but bounces 8.5% to 10.7% of the drop;
with `enable_restitution` alone it stops bouncing and loses 43% to 91% of the friction at the impact. With the switch
unset, or with the restitution pass not run, Newton plays byte for byte as released.
