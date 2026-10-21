# Run 043: Study 6, played once

15 October 2026, 10:46 to 10:51 UTC, on the Newton host, by [`play.sh`](play.sh), under
[`PREREGISTRATION_06.md`](../../preregistrations/PREREGISTRATION_06.md), registered and pushed with the runner before
any play. The runner's dry run (`dry/`, throwaway parameters, the on arm only) ran to the end first; no rule was read
from it. Measured by Senua AI's `sx_contact swing` and byte comparisons, judged by its `rule` (`rules.txt`); the
measured lines and the rules were re-made byte for byte on the laptop from the kept files. In the logs the home folder
is written `~/`.

## The result: 9 of 9 rule lines held

| Rule | Measured | |
|---|---|---|
| R1 safe when off | 10 of 10 files byte-identical (off to stock) | held |
| R2 the fault is there | stock: the arm turns back at -0.220 and -0.219 rad (0.3 kg) and -0.079 and -0.079 rad (3 kg), against -0.573 and -0.282 | held, both lines |
| R3 the strike | on: -0.595 and -0.585 rad (0.3 kg) and -0.289 and -0.287 rad (3 kg), within 0.03 rad of -0.573 and -0.282 | held, all four lines |
| R4 nothing else changes | on: the free arm, 4 of 4 files byte-identical to stock's | held |
| R5 nothing blows up | on: no ruled play stopped being a number or left the format's range | held |

| How far past the limit at -0.8 rad the arm goes (rad), and where it turns back | 0.3 kg, 0.8 / 0.16 ms | 3 kg, 0.8 / 0.16 ms |
|---|---|---|
| As released | 0.050 and 0.050; turns at -0.220 / -0.219 | 0.168 and 0.168; turns at -0.079 / -0.079 |
| **With the patch** | 0.008 and 0.008; turns at **-0.595 / -0.585** | 0.034 and 0.034; turns at **-0.289 / -0.287** |
| The spring and damper given, kept from pulling | turns at -0.573 | turns at -0.282 |

Reported, not ruled, with the registration's reason (10 ms, where h sqrt(ke / I) is 5.2 and 1.6): with the patch the
0.3 kg arm leaves the format's range at step 111, and the 3 kg arm turns at -0.290 rad; as released they turn at -0.305
and -0.087.

## What it shows

**The patch is validated.** On an arm and steps no probe used, the MuJoCo solver with the conversion corrected strikes
a joint limit as the spring and damper Newton gives it, kept from pulling: the arm turns back within 0.022 rad of that
form at both masses and steps, where as released the limit, 20 times softer and damped at a fifth of the ratio, sends
it back three to four times higher. A joint with no limit is unchanged, and with its switch unset Newton is the release
byte for byte. At a step too long for the limit's own spring (10 ms on the lighter arm) the stiffer limit leaves the
format's range; that step is outside the range ruled.
