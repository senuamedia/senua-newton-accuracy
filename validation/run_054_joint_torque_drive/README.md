# Run 054: a joint torque and a joint drive, against closed forms (issues 25, 26 and 27)

Not registered: a trace. Its play script [`play.sh`](play.sh) and the predictions below were pushed before any play.
Newton 1.7.0 as released, and with pull requests #4316 and #4317 first on the path (run 053's engines). The rig
[`tools/nwt_joint.py`](../../tools/nwt_joint.py) gains a constant joint torque (`torque=`, through Newton's
`control.joint_f`) and a drive (`drivek=`, `drived=`, `target=`: `add_joint_revolute`'s `target_ke`, `target_kd`,
`target_pos`); a play that sets neither is unchanged (check C0: run 037's stock none and reach at 1.6 ms, byte for byte
as the record's, XPBD's plays being byte-identical on 1.6.1 and 1.7.0 by Study 7).

## What is played, and the closed forms

One arm, 1 kg, half-size 0.05 m, its centre 0.5 m from the joint: I = (2/3) m r^2 + m a^2 = 0.2516667 kg m2 about
the joint (computed with `bc`). Steps 0.1 and 0.05 ms.

- **P1, issue 25** (XPBD at its 0.7 and 0.4 relaxations; at equal relaxations, `opt.joint_angular_relaxation=0.7`;
  with #4317; Featherstone and the MuJoCo solver beside): from rest and level, 0.05 s.
  - under a torque of 1 N m, no gravity: theta = t^2 / (2 I) = **4,967 urad**;
  - under gravity (9.8 m/s2, the rig's), released level: theta = -(m g a / I) t^2 / 2 = **-24,338 urad** (the
    pendulum's next term is 2 in 10^5 of it).
  Checked: within 1 in 100.
- **P2, issue 26** (XPBD at 1, 2, 4, 8 and 16 iterations; Featherstone and the MuJoCo solver beside): no gravity, a
  drive of 10 N m/rad toward 0, from 0.2 rad at rest, 0.1 s: theta = 0.2 cos(sqrt(k / I) t) = **161,563 urad** (a drop
  of 38,437). Checked: the angle within 1 in 400 of it, about 1 in 100 of the drop.
- **P3, issue 27** (SemiImplicit, XPBD, XPBD with #4316, VBD, Featherstone, the MuJoCo solver): no gravity, a drive of
  100 N m/rad and 10 N m s/rad, the arm at rest at its target, 2.5 rad (short of pi) and 3.5 rad (past it), 1 s: held
  is the angle within 1 in 1,000 of the target (2.5 and 3.5 mrad) and the speed within 0.01 rad/s of 0.

## Predictions, before any play

- **P1.** XPBD at 0.7 and 0.4 departs from both closed forms by more than 1 in 100, above under the torque and below
  under gravity: the pull request's own reading at its own scene is 1.36 and 0.78; this arm's own inertia is 0.7% of
  its inertia about the joint, so the size here is not predicted, only the direction. At equal relaxations and with
  #4317, within 1 in 100 under both. Featherstone and the MuJoCo solver within 1 in 100 under both.
- **P2.** XPBD's angle moves with its iteration count by more than 1 in 100 of the drop, between 1 and 16 iterations;
  Featherstone and the MuJoCo solver within the check.
- **P3.** SemiImplicit holds at 2.5 rad and not at 3.5 (the report, N18); VBD holds at both (Newton 1.7.0's winding
  fix, #4470); XPBD with #4316 holds at both (its reference for an unlimited joint is the drive's target); XPBD as
  released not predicted; Featherstone and the MuJoCo solver hold at both.
- **C0** holds.

The D6 half of issue 27 (a two-axis D6 joint not held) needs a joint the rig does not build; not played here.

## What was found

Played on the Newton host, 2026-10-19T13:10:18Z to 2026-10-19T13:28:05Z (a second play: the first lost its files when the
host's disk filled; this one from f864db7, whose rig change, `vlimit=` and `elimit=`, these plays do not use).
Reading [`reading.txt`](reading.txt), checks [`checks.txt`](checks.txt) (85 of 107 held). C0 held: the rig's
change leaves a play without its settings byte for byte as the record's.

- **P1, issue 25: XPBD answers a torque 1.75 times too strongly at its 0.7 and 0.4 relaxations.** Under 1 N m it
  reaches 8,670 urad against the closed form's 4,967 at 0.1 ms (8,648 at 0.05 ms, 1.74 times); at equal relaxations and with #4317 it reads
  4,977 and 4,964 at 0.1 ms, within the check, as Featherstone and the MuJoCo solver (4,977). Under gravity XPBD at
  0.7 and 0.4 is only 0.5% low (-24,265 against Featherstone's -24,386): this arm's own inertia is 0.7% of its inertia
  about the joint, so gravity, which acts at its centre, hardly needs the moment the inconsistent rows scale. The
  prediction held for the torque and failed for gravity. **At 0.05 ms the torque leaves the arm all but still at equal
  relaxations and with #4317 (10 and 11 urad)**: one step's speed at its centre, 9.9e-5 m/s, is under XPBD's 1e-4 m/s
  floor, which sets it to zero after every correction (F17); the inconsistent rows move it faster than the floor.
- **P2, issue 26: XPBD's drive is stiffer in proportion to its iteration count.** Its angle at 0.1 s gives an
  effective stiffness of 0.69, 1.39, 2.78, 5.56 and 11.1 times the drive's at 1, 2, 4, 8 and 16 iterations (doubling
  with the count, the same at both steps); Featherstone and the MuJoCo solver within the check. The prediction held.
- **P3, issue 27:** SemiImplicit holds a driven arm at rest at 3.5 rad as at 2.5, against the prediction (the report's
  case may need what this rig does not build: gravity, or a two-axis D6). XPBD as released is thrown at 3.5 rad (40 and
  28 rad/s); with #4316 it holds at both. Featherstone and the MuJoCo solver hold at both. **VBD's result is the rig's,
  not VBD's drive:** VBD captures each joint's rest angle when it is built, and the rig builds the solver before placing
  the body at its start angle, so VBD's angle was offset by the start angle and its drive took the arm to 0 (from 2.5
  rad) and to 2 pi (from 3.5). The angle reaches VBD's rows only through its limit and drive rows
  (`resolve_drive_limit_mode`, read in the source); the record's earlier VBD plays with a limit start at 0 (runs 032 and
  036), and those that start away from 0 (the free chain of runs 038 and 041, at -0.9 rad) have no limit or drive, so
  none is touched. VBD's drive past pi is played again with the body placed first.

Every reading and check of this run was made again on the laptop, byte for byte, from its kept files, with a build of
[the measure](../../measure/README.md) (20 October 2026).
