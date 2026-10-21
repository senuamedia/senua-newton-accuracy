# Run 037: Study 5, played once

15 October 2026, 10:04 to 10:06 UTC, on the Newton host, by [`play.sh`](play.sh), under
[`PREREGISTRATION_05.md`](../../preregistrations/PREREGISTRATION_05.md), registered and pushed with the runner before
any play. The runner's dry run (`dry/`, throwaway parameters, the on arm only) ran to the end first; no rule was read
from it. Measured by Senua AI's `sx_contact` (`final`) and byte comparisons, judged by its `rule` (`rules.txt`); the
measured lines and the rules were re-made byte for byte on the laptop from the kept files. In the logs the home folder
is written `~/`.

## The result: 6 of 8 rule lines held; R4 failed

| Rule | Measured | |
|---|---|---|
| R1 safe when off | 8 of 8 files byte-identical (off to stock) | held |
| R2 the fault is there | stock: the arm inside its limits is thrown past pi (it ends turning at 1,284,321 and 19,643,442 rad/s), no file the same as with no limits | held |
| R3 inside, as with none | on: the arm inside its limits is its play with no limits byte for byte, at both steps | held |
| R4 reach, held at the limit: the angle | on: the last angle 2,882,046 and 2,757,972 urad, not within 0.05 rad of 3,600,000 | **failed** |
| R4 the speed, at most 0.1 rad/s | on: -2,136,837 and -2,174,066 urad/s | held |
| R4 the speed, at least -0.1 rad/s | the same | **failed** |
| R5 nothing else changes | on: the play with no limits and the play with a limit before pi, 4 of 4 files byte-identical to stock | held |
| R6 nothing blows up | No play of the on arm stopped being a number | held |

| One arm turning at 3 rad/s, its last angle (rad) and speed (rad/s) | 1.6 ms | 0.32 ms |
|---|---|---|
| No limits, every arm | 4.742, 2.93 | 4.789, 2.99 |
| Limits -0.5 and 5 rad (inside, past pi): released | thrown, 1,284,321 rad/s | thrown, 19,643,442 rad/s |
| The same, with the patch | 4.742, 2.93 (as with none) | 4.789, 2.99 (as with none) |
| Limits -0.5 and 3.6 rad (reached past pi): released | thrown | thrown |
| The same, with the patch | **2.882, -2.14** | **2.758, -2.17** |
| Limits -0.5 and 2.5 rad (reached before pi), every arm | 1.328, -2.29 | 1.170, -2.39 |

## What it shows

- **The patch does what it was made for:** past pi, an arm inside its limits plays exactly as with no limits, where as
  released it is thrown at millions of radians a second; every play in which the joint never passes pi is the
  release's byte for byte; with its switch unset Newton is the release.
- **R4 failed, and the reason is in the release itself:** an arm that reaches its limit is thrown back off it by
  XPBD's limit, not held. The arm reaching 2.5 rad, before pi, does the same in every arm, unpatched (-2.29 and -2.39
  rad/s). With the patch, the arm reaching 3.6 rad past pi now does what XPBD does at a limit before pi (-2.14 and
  -2.17 rad/s) instead of being thrown at millions of radians a second; but R4 asked for it to be held. XPBD's limit
  returning the arm is a separate finding (F14), not this patch's.
- **The patch stays in design.** A later study on fresh numbers can revisit R4 posed against XPBD's own limit; a limit
  that does not return the arm is a separate correction.
