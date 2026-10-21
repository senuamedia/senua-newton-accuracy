# Study 10: XPBD's joints and its speed floor

**Outcome: 24 of 24 rule lines held.** Issue 17 is fixed and validated by Senua AI's speed-floor patch; issue 25 by
pull request #4317 with that patch; issue 26 by pull request #4318's `pd` drive; issue 7 on XPBD by #4318 (its form of
#4316) and on VBD by Newton 1.7.0 as released. Registered 20 October 2026
([`PREREGISTRATION_10.md`](../../preregistrations/PREREGISTRATION_10.md)); played once as
[run 071](../../validation/run_071_study_10/README.md).

## The question

Four open issues on XPBD each have a fix measured in run 065 but never held to rules registered in advance. On scenes
and steps no probe used, on Newton 1.7.0: is each fault there as released, and does its fix remove it?

## How it got here

| Run | What | Result |
|---|---|---|
| [044](../../validation/run_044_xpbd_creep_floor/README.md) | XPBD's creep at rest | The speed floor read in the source (F17) |
| [053](../../validation/run_053_study_08/README.md), [054](../../validation/run_054_joint_torque_drive/README.md) | #4316 and #4317; a torque and a drive against closed forms | #4316 stops the throw past pi; the torque 1.75 times too strong (F18), #4317 right at 0.1 ms; the drive in proportion to the iterations (F19) |
| [065](../../validation/run_065_xpbd_floor_relaxation_drive/README.md) | The speed-floor patch, #4317 and #4318 together | 32 of 32 predictions held: #4317's hold at 0.05 ms is the floor; #4318's `pd` drive is its own spring |

## The rules and the result

| Rule | Result |
|---|---|
| R1 safe when off (17): the patch's tree with its switch unset gives the release's files | held: 4 of 4 plays, 39 of 39 suite files |
| R2 the fault is there (17): a free body at 30 um/s, and a body pushed at 2 ms, read 0 | held |
| R3 kept (17): 30 um/s; 52,500 um/s pushed, within 1 in 1,000 | held: 30; 52,499 and 52,500 |
| R4 the turn (17): 0 as released, 40 urad/s with the patch | held |
| R5 nothing else (17): the suite's 10 verdicts unchanged | held: 6 of 10 pass with and without |
| R6 the fault is there (25): the torque answer at least 1.5 times 2,832 urad | held: 4,959 |
| R7 right (25): within 1 in 100 of 2,832 urad (#4317 at 0.2 ms; #4317 and #4318 with the patch at both steps), gravity within 1 in 100 of -22,207 | held: 2,852 and 2,836; -22,317 and -22,229 |
| R8 the fault is there (26): as released the drive at 12 iterations ends past its target | held: -126,952 and -127,989 urad |
| R9 right (26): `pd` within 1 in 400 of 93,289 urad at 1, 3, 6 and 12 iterations | held: 93,131 to 93,261 |
| R10 the effort limit (26): `pd` within 1 in 400 of 130,577 urad; the release ignores the limit | held: 130,517 and 130,570; byte for byte |
| R11 the fault is there (7): XPBD's arm inside its limits thrown | held: 797,855 and 32.7 million rad/s |
| R12 kept on XPBD (7): #4318, inside as none | held: to 1 urad |
| R13 kept on VBD (7): VBD as released, inside as none | held: exactly |

## What it decides

- **Issue 17, fixed and validated:** [`xpbd_no_speed_floor.diff`](../../patches/newton-1.7.0/xpbd_no_speed_floor.diff),
  switch `NEWTON_XPBD_NO_SPEED_FLOOR=1` (see [the patches](../patches.md)). It shows what the floor hid: XPBD's creep at
  rest under 0.1 mm/s (issue 6, run 065).
- **Issue 25, fixed and validated:** pull request #4317, with the speed-floor patch wherever a step's speed gain is
  under the floor (there #4317 alone leaves the arm still, as the release's floor does).
- **Issue 26, fixed and validated:** pull request #4318's `joint_drive_mode="pd"`, which also honours the effort limit.
- **Issue 7, fixed and validated:** on XPBD by #4318, on VBD by Newton 1.7.0's winding fix (#4470).
- #4316, #4317 and #4318 are open pull requests; their state is in [the fixes in the wild](../fixes-in-the-wild.md).
