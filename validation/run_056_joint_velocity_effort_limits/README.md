# Run 056: a joint's velocity and effort limits, applied or ignored (issue 19)

Not registered: a trace. Its play script [`play.sh`](play.sh) and the predictions below were pushed before any play.
Newton 1.7.0 as released. The rig [`tools/nwt_joint.py`](../../tools/nwt_joint.py) gains `vlimit=` and `elimit=`
(`add_joint_revolute`'s `velocity_limit` and `effort_limit`); a play setting neither is unchanged.

## The question

Issue 19 (N7): joint features silently ignored. Read in 1.7.0's source: every solver's own documentation says
`joint_velocity_limit` is not supported (XPBD, Featherstone, SemiImplicit, VBD, the MuJoCo solver), and
`joint_effort_limit` is not supported but by the MuJoCo solver, which converts it to MuJoCo's `jnt_actfrcrange`;
`ModelBuilder.add_joint_revolute` takes both for every solver. Played: are they applied, and is anything said?

## What is played

The record's arm (1 kg, 0.05 m, 0.5 m; I = 0.2516667 kg m2), no gravity, 0.1 ms, on Featherstone, the MuJoCo
solver, XPBD, SemiImplicit and VBD (closed forms with `bc`):

- **velocity**: a torque of 1 N m from rest for 1 s, with a velocity limit of 1 rad/s and without. Applied, the last
  speed is 1 rad/s; ignored, t / I = **3,973,510 urad/s**.
- **effort**: a drive of 100 N m/rad toward 1 rad from rest at 0, 0.2 s, with an effort limit of 1 N m and without.
  Applied, the torque stays at 1 N m and the angle is t^2 / (2 I) = **79,470 urad**; ignored, 1 - cos(sqrt(k / I) t)
  = **1,663,626 urad**.
- Each play's error stream is kept: whether the solver says anything about a limit it does not apply.

Checked within 1 in 100.

## Predictions, before any play

- The velocity limit is applied by no solver: every limited play ends at 3,973,510 urad/s, as its free play.
- The effort limit is applied by the MuJoCo solver only: its limited drive reaches 79,470 urad; the others' limited
  drives reach the free drive's 1,663,626.
- No solver says anything on its error stream about a limit it does not apply.
- Every free play holds its closed form within 1 in 100 (SemiImplicit and XPBD, which keep the body as their state,
  not predicted beyond that).

## What was found

Played on the Newton host, 2026-10-19T13:28:22Z to 2026-10-19T13:34:12Z. Reading [`reading.txt`](reading.txt), checks
[`checks.txt`](checks.txt) (7 of 25 held; every failure below is read).

- **The velocity limit is applied by no solver, and none says so.** On every solver the limited play reads exactly as
  its free play (Featherstone and the MuJoCo solver 3,973,875 urad/s against the closed form's 3,973,510; SemiImplicit
  3,960,963). The prediction held.
- **The effort limit is applied by the MuJoCo solver only.** Its limited drive reaches 79,510 urad against the capped
  closed form's 79,470; every other solver's limited drive is its free drive (Featherstone 1,662,881 against the free
  closed form's 1,663,626). The prediction held.
- **Nothing is said about either.** Each play's error stream holds one line, Warp's notice that no CUDA driver was
  found, and VBD's also a deprecation warning about `rigid_compliant_alm`; no line names a limit. The check counted
  every line, so it failed on the notice; read, the prediction held.
- **Two free plays depart from their closed forms, each for a cause the record already has:** XPBD's speed under the
  torque is 6,910,794 urad/s, 1.74 times the closed form, run 054's torque excess at 0.7 and 0.4 relaxations (issue
  25), and its free drive overshoots (1,803,264), its drive stiffer at two iterations (run 054, issue 26); VBD's speed
  is 0.92 of it at this 0.1 ms step over 1 s, where run 057 found its torque answer right at 0.8 to 4 ms (consistent with
  its 32-bit poses at small steps, F9, not traced here).

Every reading and check of this run was made again on the laptop, byte for byte, from its kept files, with a build of
[the measure](../../measure/README.md) (20 October 2026).
