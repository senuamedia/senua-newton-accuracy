# Run 063: a loop-closing joint's limit and drive (issue 19)

Not registered: a trace. Its play script [`play.sh`](play.sh), its rig and the predictions below were pushed before
its plays. Newton 1.7.0 as released. The rig [`tools/nwt_loop.py`](../../tools/nwt_loop.py): one arm (1 kg, 0.05 m,
its centre 0.5 m from the joint), no gravity, on two revolute joints about +z at the origin, A in the articulation and
free, B coaxial with it and left out of the articulation (a loop-closing joint, Newton's way of marking one), carrying
a limit or a drive; the two hinges agree, so what the arm does is B's features applied or not. (Newton warns that a
second joint connects the same bodies; checked on the host that it builds and steps.)

## Read in the source (Newton 1.7.0)

The MuJoCo solver makes a loop-closing revolute two MuJoCo CONNECT constraints, offset along its axis
(`solver_mujoco.py`: "CONNECT equality constraints synthesized from loop-closure joints ... that have no associated
articulation"); a CONNECT carries no limit and no drive. [#2428](https://github.com/newton-physics/newton/issues/2428)
reports limits, drives, effort and velocity limits, friction and armature all silently ignored on such a joint.

## What is played

At 0.1 ms, on Featherstone, the MuJoCo solver, XPBD, SemiImplicit and VBD: the arm turning at 1 rad/s from 0 for 1.5
s with B absent (the control), B free, and B limited to -0.5 and 0.5 rad; and from rest with B driven toward 0.3 rad
(100 N m/rad, 10 N m s/rad), 1 s. Applied: the limit held within 0.05 rad of 0.5 rad; the drive within 3 mrad of 0.3.

## Predictions, before the plays

- The MuJoCo solver ignores B's limit (the arm reaches 1.5 rad) and B's drive (the arm stays at 0).
- With B absent or free, every solver turns the arm to 1.5 rad.
- Featherstone, XPBD, SemiImplicit and VBD not predicted.

## What was found

Played on the Newton host, 2026-10-19T14:25:40Z to 2026-10-19T14:34:38Z. Reading [`reading.txt`](reading.txt), checks
[`checks.txt`](checks.txt) (9 of 20 held; SemiImplicit's three loop plays have no reading, below).

| Solver | B free (1.5 s at 1 rad/s) | B limited to 0.5 rad | B driven to 0.3 rad |
|---|---|---|---|
| Featherstone | 1.500 rad (as B absent) | **ignored**: 1.500 rad | **ignored**: 0 |
| the MuJoCo solver | 1.500 rad | **ignored**: 1.500 rad | **ignored**: 0 |
| XPBD | 1.500 rad | applied, and the arm thrown back: -0.377 rad, turning at -0.88 rad/s (F14) | applied: 0.300 rad, at rest |
| VBD | 1.632 rad (its free arm, B absent, 1.631) | applied, thrown back: -0.237 rad, -0.73 rad/s | applied: 0.299 rad |
| SemiImplicit | **not a number** at step 2,928 (0.29 s) | not a number at step 2,898 | not a number at step 7,381 |

- **The predictions on the MuJoCo solver held:** a loop-closing joint's limit and drive are ignored, as #2428 reports
  and its CONNECT constraints imply; nothing is said. Featherstone ignores the loop joint altogether (it plays a tree).
- **XPBD and VBD apply the loop joint's limit and drive**, the limit with the throw-back XPBD's limits have (F14).
- **SemiImplicit cannot play the loop at all:** with B present, free or not, the arm stops being a number within 0.3 s
  to 0.74 s at 0.1 ms, where the single hinge plays (the prediction, every solver turning the arm with B free, failed
  on SemiImplicit). Its plays' files carry numbers past the format's 64-bit range before the step their STATS lines name,
  so the measuring program refuses them ("not whole"); the rig, new here, lacks the joint rig's range check.
- **VBD's free arm runs fast:** with nothing acting, it turns 1.631 rad in 1.5 s and ends at 1.035 rad/s from 1.0
  (a 3.5% gain at 0.1 ms; consistent with its 32-bit poses at small steps, F9, not traced here).

Every reading and check of this run was made again on the laptop, byte for byte, from its kept files, with a build of
[the measure](../../measure/README.md) (20 October 2026).
