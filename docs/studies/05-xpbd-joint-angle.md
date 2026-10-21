# Study 5: XPBD's joint angle tracked continuously past pi

**Outcome: 6 of 8 rule lines held; R4 failed. The patch stays in design.** Registered 15 October 2026
([`PREREGISTRATION_05.md`](../../preregistrations/PREREGISTRATION_05.md)); played once as
[run 037](../../validation/run_037_study_05/README.md).

## The question

XPBD throws a joint that turns past pi inside limits it never reaches (F13): its joint solve compares the limits with an
angle in [-pi, pi]. A patch keeps each revolute joint's last angle, unwrapped. On a single arm at fresh numbers: is the
fault there, does the patch remove it, is a joint reaching a limit beyond pi held there, and does nothing else change?

## How it got here

| Run | What | Result |
|---|---|---|
| [032](../../validation/run_032_joint_limit_past_pi/README.md) | N6 measured | A joint turning past pi inside its limits is thrown |
| [035](../../validation/run_035_xpbd_joint_angle_unwrap/README.md) | The patch held to the five checks on the chain | Removes the throw; every play with no joint past pi the release's |

## The rules and the result

| Rule | Result |
|---|---|
| R1 safe when off: 8 of 8 files | held |
| R2 the fault is there: thrown at 1,284,321 and 19,643,442 rad/s | held |
| R3 inside its limits past pi, as with none, byte for byte | held |
| R4 a limit reached past pi holds the arm: within 0.05 rad of it and slower than 0.1 rad/s | **failed** (2 of 3 lines): the arm turns back off it at 2.1 rad/s, as XPBD returns an arm off a limit before pi in every arm, unpatched (F14) |
| R5 plays with no joint past pi, the release's byte for byte: 4 of 4 | held |
| R6 no play stops being a number | held |

## The patch

[`patches/in_design/xpbd_joint_angle_unwrap.diff`](../../patches/in_design/xpbd_joint_angle_unwrap.diff) (sha256
ce0fe02dcf4b2ebe...), switch `NEWTON_XPBD_JOINT_ANGLE_UNWRAP=1`. See [the patches](../patches.md).
