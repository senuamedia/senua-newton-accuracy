# Run 057: VBD's joint limit and a joint torque on 1.7.0's dense rigid path (issue 29)

Not registered: a trace. Its play script [`play.sh`](play.sh) and the predictions below were pushed before any play.
Newton 1.7.0 as released.

## The question

Issue 29 (N20, [#4720](https://github.com/newton-physics/newton/issues/4720)): on VBD's block-sparse rigid path, joint
limits give way at coarse steps on light links behind heavy motor inertia, and outside torques on light links are
under-converged. Read in 1.7.0's source: 1.7.0 has no block-sparse rigid path (`solvers/vbd/` holds the dense rigid
kernels only), and VBD does not support `joint_armature`; draft PR #4721's fixes target that later path and do not
apply. Played here: whether 1.7.0's VBD shows either departure on the arms this record plays, without armature.

## What is played

One arm on one hinge (the closed forms with `bc`):

- **torque**, no gravity, 0.1 s from rest: the record's arm (1 kg, 0.05 m, 0.5 m; I = 0.2516667 kg m2) under 1 N m,
  theta = t^2 / (2 I) = **19,868 urad**; a light arm (0.05 kg, 0.01 m, 0.02 m; I = 2.333e-5 kg m2) under 1e-4 N m,
  **21,429 urad**. Checked within 1 in 100.
- **limit**, gravity on, released level onto a lower limit at -0.5 rad (upper 0.5): the record's arm for 0.8 s, the
  light arm for 0.3 s. Held: the last angle within 1 in 100 of -0.5 rad and the last speed within 0.01 rad/s of 0.
- At 4, 2 and 0.8 ms (#4720's steps), on VBD, with Featherstone and the MuJoCo solver beside (Featherstone not on the
  light arm's limit, which run 055 traced).

## Predictions, before any play

- VBD's torque response within 1 in 100 of the closed form on both arms at every step (the departure #4720 reports is
  the sparse path's, with armature).
- VBD holds both arms on the limit at every step.
- Featherstone and the MuJoCo solver within 1 in 100 under the torque; both hold the record's arm and the MuJoCo
  solver the light arm on the limit.

## What was found

Played on the Newton host, 2026-10-19T13:23:10Z to 2026-10-19T13:27:49Z. Reading [`reading.txt`](reading.txt), checks
[`checks.txt`](checks.txt) (55 of 81 held).

- **The torque: VBD answers it exactly as Featherstone and the MuJoCo solver do, at every step.** The three read the
  same angle on both arms: 20,662 urad at 4 ms and 20,265 at 2 ms against the closed form's 19,868 (the light arm
  22,286 and 21,857 against 21,429), within 1 in 100 at 0.8 ms. The excess is semi-implicit Euler's own under a
  constant acceleration, exactly (n + 1) / n of the closed form after n steps (26/25 at 4 ms, 51/50 at 2 ms), common to
  all three; the prediction (within 1 in 100 at every step) failed at 4 and 2 ms on that, for every solver. No torque
  departure of VBD's own on its dense path, on either arm.
- **The limit: VBD holds where Featherstone and the MuJoCo solver do not.** VBD holds the light arm on its limit at
  every step (-500,001 urad, at rest), and the record's arm at 4 and 2 ms (430 urad past the limit, at rest); at 0.8
  ms the record's arm is still turning at 0.23 rad/s at 0.8 s (the prediction failed there). Featherstone and the
  MuJoCo solver hold the record's arm at no step: at the end Featherstone is 12 to 87 mrad off the limit turning at
  1.1 to 1.6 rad/s (its limit pulls, F16), the MuJoCo solver 18 to 23 mrad off it at 3.7 rad/s (its limit softer than
  Newton gives it, F15). The MuJoCo solver's light arm rests 6.9, 1.7 and 0.4 mrad past its limit at 4, 2 and 0.8 ms.
- **Issue 29 on 1.7.0.** #4720's departures belong to VBD's block-sparse rigid path, which 1.7.0 does not have; on its
  dense path, without armature (which it does not support), neither departure is seen here: its torque response is the
  other solvers', and its limit holds better than theirs.

Every reading and check of this run was made again on the laptop, byte for byte, from its kept files, with a build of
[the measure](../../measure/README.md) (20 October 2026).
