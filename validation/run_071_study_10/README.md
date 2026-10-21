# Run 071: Study 10, played once

20 October 2026, 10:14 to 10:18 UTC, on the second x86-64 host, by [`play.sh`](play.sh), under
[`PREREGISTRATION_10.md`](../../preregistrations/PREREGISTRATION_10.md), registered and pushed with the runner before
any play. The runner's dry run (`dry/`, throwaway parameters) ran to the end first; no rule was read from it. Played from
the record at its commit 905dbeb, on Newton 1.7.0 and run 065's engines made by its
[`setup_engine.sh`](../run_065_xpbd_floor_relaxation_drive/setup_engine.sh). Measured by Senua AI's `sx_contact` (`final`;
the suite's verdicts by the first deep dive's `sx_contact_suite.sh`) and judged by its `rule` (`rules.txt`). In the logs
the home folder is written `~/`.

## The result: 24 of 24 rule lines held

| Rule | Measured | |
|---|---|---|
| R1 safe when off (17) | With the switch unset: A's 4 plays and the suite's 39 files byte for byte the release's | held, both lines |
| R2 the fault is there (17) | As released the free body at 30 um/s and the body pushed at 2 ms read 0 | held |
| R3 kept (17) | With the patch: 30 um/s; pushed, 52,499 and 52,500 um/s; as released at 5 ms, 52,500 | held, both lines |
| R4 the turn (17) | As released 0; with the patch 40 urad/s | held, both lines |
| R5 nothing else (17) | With the patch every one of the suite's 10 verdicts the release's (6 of 10 pass in both) | held |
| R6 the fault is there (25) | As released at 0.2 ms the torque answer 4,959 urad (1.75 times 2,832) | held |
| R7 right (25) | Torque: #4317 at 0.2 ms 2,852; #4317 and #4318 with the patch 2,852 at 0.2 ms and 2,836 at 0.04 ms. Gravity on those three: -22,317 and -22,229 (closed form -22,207) | held, both lines |
| R8 the fault is there (26) | As released at 12 iterations the drive ends at -126,952 and -127,989 urad, past its target | held |
| R9 right (26) | `pd` at 1, 3, 6 and 12 iterations: 93,131 to 93,148 urad at 0.2 ms, 93,256 to 93,261 at 0.04 ms (closed form 93,289) | held |
| R10 the effort limit (26) | `pd` with the limit 130,517 and 130,570 urad (closed form 130,577); as released the limit's plays byte for byte the plays without it | held, both lines |
| R11 the fault is there (7) | XPBD as released, inside its limits: its last speed 797,855 rad/s at 1.6 ms and 32.7 million rad/s at 0.4 ms (none 3.4) | held |
| R12 kept on XPBD (7) | #4318: inside's last angle and speed those of none, to 1 urad and 0 urad/s at both steps | held, 4 lines |
| R13 kept on VBD (7) | VBD as released: inside's last angle and speed those of none, exactly, at both steps | held, 4 lines |

## The readings

| A, the floor | As released | Switch unset | The patch | The answer |
|---|---|---|---|---|
| A1 a free body at 30 um/s, after 1.5 s | 0 | 0 | **30** | 30 |
| A2 pushed by 0.07 N, 2 ms | 0 | 0 | **52,499** | 52,500 |
| A2, 5 ms | 52,500 | 52,500 | 52,500 | 52,500 |
| A3 an arm turning at 40 urad/s | 0 | 0 | **40** | 40 |

| B, the arm after 0.04 s, urad | 0.2 ms | 0.04 ms | The closed form |
|---|---|---|---|
| Torque, as released | 4,959 | 10 | 2,832 |
| Torque, the patch alone | 4,959 | 4,930 | |
| Torque, #4317 | **2,852** | 6 | |
| Torque, #4317 with the patch, and #4318 with the patch | **2,852** | **2,836** | |
| Gravity, as released | -22,173 | -22,085 | -22,207 |
| Gravity, #4317, alone and with the patch, and #4318 with the patch | -22,317 | -22,229 | |

| C, the drive after 0.08 s, urad (closed form 93,289) | 1 | 3 | 6 | 12 iterations |
|---|---|---|---|---|
| As released, 0.2 ms | 109,699 | 40,346 | -38,870 | -126,952 |
| `pd`, 0.2 ms | **93,131** | **93,144** | **93,148** | **93,146** |
| As released, 0.04 ms | 109,779 | 40,332 | -39,164 | -127,989 |
| `pd`, 0.04 ms | **93,261** | **93,256** | **93,259** | **93,258** |

| D, the arm after 1.4 s | 1.6 ms | 0.4 ms |
|---|---|---|
| XPBD, none | 4.833 rad, 3.40 rad/s | 4.883 rad, 3.48 rad/s |
| XPBD as released, inside | thrown: 5.943 rad, 797,855 rad/s | thrown: -2.465 rad, 32.7 million rad/s |
| #4318, inside | 4.830 rad, 3.40 rad/s, as #4318's none | 4.883 rad, 3.48 rad/s, as none to 1 urad |
| VBD, none and inside | 4.835 rad, 3.41 rad/s, the same | 4.879 rad, 3.47 rad/s, the same |

The suite on XPBD (`suites/`): 6 of 10 as released, with the switch unset and with the patch, every verdict the same;
with the patch one figure of T08 moves by 1 um (191,593 for 191,592).

## What it shows

- **Issue 17 is fixed and validated by Senua AI's speed-floor patch.** A body moving or turning slower than XPBD's floor,
  and a body a force too small to pass the floor in one step sets moving, are each stopped as released and kept with
  the patch; with its switch unset Newton is the release byte for byte; the suite's verdicts are unchanged.
- **Issue 25 is fixed and validated by pull request #4317, with the patch where a step's gain is under the floor.**
  At 0.2 ms #4317 alone answers the torque within 0.8%; at 0.04 ms the floor holds the arm still (6 urad), as it holds
  the release's arm (10 urad: the release's own 1.75 times too strong answer is still under the floor there); with the
  patch the answer is within 0.8% and 0.2%. #4318 with the patch gives #4317's numbers exactly.
- **Issue 26 is fixed and validated by pull request #4318's `pd` drive:** the drive's own spring within 0.17% at every
  iteration count, where as released it acts as 0.70 of its stiffness at 1 iteration (109,699 urad; run 054 found 0.69 an iteration) and goes past its target from 6 on; it honours
  the effort limit, which the release ignores.
- **Issue 7 is fixed and validated on both solvers:** on XPBD by #4318 (its form of #4316), on VBD by Newton 1.7.0 as
  released (#4470): an arm turning past pi inside limits it never reaches moves as an arm with none, where XPBD as
  released throws it at up to 32.7 million rad/s.
