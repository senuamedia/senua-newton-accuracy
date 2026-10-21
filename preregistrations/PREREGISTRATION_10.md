# Tenth pre-registration: XPBD's joints and its speed floor

Registered 20 October 2026, after the design probe of run 065 (and runs 044, 053 and 054). Registered before any play
of this registration existed. To be played once, as run 071, on Newton 1.7.0.

## The question

Four open issues on XPBD each have a fix measured in run 065 but never held to rules registered in advance. On scenes
and steps no probe used: is each fault there as released, and does its fix remove it?

| Issue | The fault | The fix | Measured in |
|---|---|---|---|
| 17 | A body slower than 0.1 mm/s is stopped | Senua AI's speed-floor patch, `NEWTON_XPBD_NO_SPEED_FLOOR=1` ([`xpbd_no_speed_floor_on_1.7.0.diff`](../patches/in_design/xpbd_no_speed_floor_on_1.7.0.diff)) | run 065 |
| 25 | A joint torque answered 1.75 times too strongly at the default relaxations | Pull request #4317, with the speed-floor patch where a step's speed gain is under the floor | runs 054, 065 |
| 26 | The drive's stiffness grows with the iteration count, and its effort limit is ignored | Pull request #4318's `joint_drive_mode="pd"` | run 065 |
| 7 | A joint turning past pi inside its limits is thrown | Pull request #4318 (its form of #4316) on XPBD; Newton 1.7.0's winding fix (#4470) on VBD | runs 053, 058, 065 |

## The right answers

- A body nothing acts on keeps its velocity; a body under a constant force F gains F t / m (Newton's first and second
  laws).
- One arm on a hinge from rest under a joint torque tau turns tau t^2 / (2 I); released level under gravity it turns
  -(m g a / I) t^2 / 2 while the angle is small; under a drive of stiffness k from theta_0 at rest, theta_0 cos(sqrt(k /
  I) t); under a drive whose torque is clamped at an effort limit e while the spring's is above it, theta_0 - e t^2 /
  (2 I). I is the arm's inertia about the joint: m (a^2 + (2 r)^2 / 6) for a cube of half-size r whose centre is a
  from the joint.
- A joint's limits act only where the joint reaches them: an arm turning inside them moves as an arm with none.

## Engines

Newton 1.7.0 from PyPI (`newton==1.7.0`, Warp 1.18.0, MuJoCo Warp 3.15.0) as released, Study 7's environment, and five
engines made from it by run 065's [`setup_engine.sh`](../validation/run_065_xpbd_floor_relaxation_drive/setup_engine.sh):
the speed-floor patch; #4317 ([`pr_4317.diff`](../patches/upstream/pr_4317.diff)); #4317 then the patch; #4318 rebased
onto 1.7.0 ([`pr_4318_on_1.7.0.diff`](../patches/upstream/pr_4318_on_1.7.0.diff)); #4318 then the patch in its form for
#4318's tree. Rigs as committed at this registration: `tools/nwt_contact.py`, `tools/nwt_joint.py`, and the contact
suite `tools/contact_suite.sh`. Warp's CPU device. Measured by Senua AI's `sx_contact` (`final`, and the first deep
dive's suite runner `sx_contact_suite.sh` for the suite's verdicts) and judged by its `rule`.

## The scenes, registered parameters

None of these numbers was used in the probes. XPBD in every play but D's VBD plays.

- **A, the floor** (as released, the patch with its switch unset, and set): A1 a 2 kg cube (half-size 0.05 m) with no
  gravity, 1 m up, moving at 30 um/s, 1.5 s, at 2 ms: it keeps **30 um/s**. A2 the same cube from rest pushed by 0.07 N,
  1.5 s, at 2 ms and 5 ms: after 1.5 s, **52,500 um/s** (each 2 ms step adds 70 um/s, under the floor; each 5 ms step 175
  um/s, above it). A3 an arm of 0.8 kg, half-size 0.04 m, centre 0.3 m out, no gravity, turning at 40 urad/s, 1.5 s, at
  2 ms: it keeps **40 urad/s**. A4 the contact suite on XPBD, as released, with the switch unset, and set.
- **B, a torque and gravity** (an arm of 1.6 kg, half-size 0.04 m, centre 0.35 m out, I = 0.197707 kg m^2, 0.04 s), at
  0.2 and 0.04 ms (the arm's centre gains 248 and 50 um/s a step under the torque), as released, on #4317, on #4317 with
  the patch, on #4318 with the patch: under 0.7 N m from rest **2,832 urad**; released level under gravity **-22,207
  urad**.
- **C, the drive** (the same arm, a drive of 25 N m/rad toward 0 from 0.15 rad at rest, 0.08 s), at 1, 3, 6 and 12
  iterations, at 0.2 and 0.04 ms, as released and on #4318 with `joint_drive_mode=pd`: **93,289 urad**. With an effort
  limit of 1.2 N m (the spring's torque at the start 3.75 N m), at XPBD's default iterations, as released and with
  `pd`: **130,577 urad** (the spring's torque stays above the limit).
- **D, past pi** (an arm of 2 kg, half-size 0.035 m, centre 0.25 m out, no gravity, turning at 3.5 rad/s, 1.4 s, so
  4.9 rad, past pi at 0.9 s): with no limit (none) and inside limits of -0.6 and 5.6 rad it never reaches (inside), at
  1.6 and 0.4 ms; XPBD as released and on #4318; VBD as released, its bodies placed before its solver is built
  (`place=first`, run 058).

## The rules

Each judged by `sx_contact rule`, from the measured lines, and nowhere else.

| Rule | Statement | Kind |
|---|---|---|
| R1 safe when off (17) | With the switch unset, A1 to A3's files and the suite's files byte for byte the release's | eq (counts) |
| R2 the fault is there (17) | As released A1 reads 0 at the end, and A2 at 2 ms reads 0 | all_eq |
| R3 kept (17) | With the patch A1 within 1 um/s of 30, A2 within 1 in 1,000 of 52,500 at both steps; as released A2 at 5 ms within 1 in 1,000 of 52,500 | all_within |
| R4 the turn (17) | As released A3 reads 0; with the patch within 1 in 10 of 40 urad/s | all_eq, all_within |
| R5 nothing else (17) | With the patch every one of the suite's 10 verdicts is the release's | eq (count) |
| R6 the fault is there (25) | As released the torque answer at 0.2 ms at least 1.5 times 2,832 urad (4,249) | all_ge |
| R7 right (25) | The torque answer within 1 in 100 of 2,832 urad on #4317 at 0.2 ms and on #4317 and #4318 with the patch at both steps; gravity within 1 in 100 of -22,207 urad on those three at both steps | all_within |
| R8 the fault is there (26) | As released the drive at 12 iterations ends past its target (below 0 urad), at both steps | all_le |
| R9 right (26) | `pd` within 1 in 400 of 93,289 urad at every iteration count, at both steps | all_within |
| R10 the effort limit (26) | `pd` with the limit within 1 in 400 of 130,577 urad at both steps; as released the limit's play byte for byte the play without it | all_within, eq |
| R11 the fault is there (7) | XPBD as released, inside: its last speed at least 100 rad/s, at both steps (none turns at 3.5) | all_ge |
| R12 kept on XPBD (7) | #4318, inside: its last angle within 10 urad and its last speed within 10 urad/s of none's, at both steps | all_within |
| R13 kept on VBD (7) | VBD as released, inside: the same, against VBD's none | all_within |

Reported, not ruled: #4317 alone at 0.04 ms (its arm's centre gains 50 um/s a step, under the floor), the patch alone
on B (unequal relaxations, the floor off), every reading's numbers at every step.

## What it decides

Issue 17 is fixed by Senua AI's patch when R1 to R5 hold; issue 25 by #4317 with the patch when R6 and R7 hold; issue
26 by #4318's `pd` drive when R8 to R10 hold; issue 7 by #4318 on XPBD when R11 and R12 hold, and on VBD by Newton 1.7.0
when R13 holds. A rule that fails is reported as failed, and its issue stays open.
