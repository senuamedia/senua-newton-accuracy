# Study 8: the fixes proposed upstream, measured

**Outcome: 0 of 2 rules held, as predicted.** Pull request #4010 fixes the friction cone as Senua AI's patch does, to
within a micrometre at its new default width, and makes the slide depend on that width (A1 failed on Study 1's R3 at
the wider width and on R5, as predicted from its algebra). Pull request #4316 stops XPBD throwing a joint that turns
past pi inside its limits, but leaves the limit's throw-back (B1 failed on Study 5's R3 by its bytes only, on R4 and on
R5). Registered 19 October 2026 ([`PREREGISTRATION_08.md`](../../preregistrations/PREREGISTRATION_08.md)); played as
[run 053](../../validation/run_053_study_08/README.md).

## The question

Three of Newton's open pull requests apply to 1.7.0: #4010 (rigid contact friction within the Coulomb cone, a draft,
rebased onto 1.7.0's refactored contact function), #4316 (XPBD hinge angles that cross plus or minus pi) and #4317
(XPBD's joint relaxation made consistent). Each held, as it stands, to the rules Senua AI's own patch for the same issue
was held to.

## The rules and the result

| Rule | Result |
|---|---|
| A1 #4010 holds Study 1 (its lines R2 to R8) | **failed**: 3 lines. R3's plate at the 0.05 m/s width slides 84,863 um against Coulomb's 83,333 (1.8% long, the check is 1%); R5, the plate the same at both widths, fails on both solvers. Every other line held: the slide 191,801 um against 191,610, the plate at the default width 83,245, the impact's friction 2,500 per 10,000, no tip, the other plays unchanged, no play not a number |
| B1 #4316 holds Study 5 (its lines R2 to R6) | **failed**: 4 lines. R3, inside the same bytes as none, fails, but inside's last angle and speed equal none's to the microradian at both steps (4,741,710 urad and 2,927,742 urad/s at 1.6 ms): the throw past pi is gone. R4, held at 3.6 rad, fails: the arm leaves the limit turning back at 2.37 and 2.43 rad/s (2.82 and 2.66 rad), the limit's throw-back (F14) untouched. R5 fails: below, a limit short of pi, ends at 1.28 rad against the release's 1.33 at 1.6 ms (none stays byte for byte the release's) |

## Beside Senua AI's patches on 1.7.0 (Study 7's replay)

| Reading | Release | #4010 | Senua AI's friction patch |
|---|---|---|---|
| The cube's slide, um (Coulomb 191,610) | 84,071 | 191,801 | 191,800 |
| The plate at the default width, um (Coulomb 83,333) | 19,376 | 83,245 | 83,244 |
| The plate at 0.05 m/s, um | 2,943 | 84,863 | 83,244 |
| Friction over the impact, per 10,000 of mu N (2,500) | 4,381 | 2,500 | 2,500 |

| Reading (Study 5, 1.6 ms) | Release | #4316 | Senua AI's joint-angle patch, first form (Study 5) |
|---|---|---|---|
| Inside: the last angle, speed | thrown (6.28 rad, 1.3e6 rad/s) | as none | as none |
| Reach: the last angle, speed | thrown | 2.82 rad, -2.37 rad/s | 2.88 rad, -2.14 rad/s |
| Below: the last angle | 1.33 rad | 1.28 rad | the release's |

## Predicted and found

- **#4010.** Predicted from the pseudo-Huber norm: friction Coulomb's times v / sqrt(delta^2 + v^2), never above the
  cone and fading under the width; R5 to fail by construction (it did); R3's slide and plate at the 1 mm/s default to
  hold (they did); R3 at 0.05 m/s not predicted (it failed, 1.8% long against an estimate of about 1%). Read: at its
  default width #4010 is Senua AI's patch to the micrometre; the departure is the fade, which a width the slip speeds
  approach brings back.
- **#4316.** Predicted: R3 to fail on bytes with the physics right (it did, to the microradian), R4 to fail (it did),
  R5 to fail; R5 failed, but not as predicted: none stays byte-identical (with no swing, the doubled swing rows change
  nothing) and below changes in its physics (the limit short of pi returns the arm 46 mrad lower: the turned frame
  changes the limit's response, not only its rounding).
- **#4317** is reported in [run 053](../../validation/run_053_study_08/README.md) and measured on its own issue in
  [run 054](../../validation/run_054_joint_torque_drive/README.md).
