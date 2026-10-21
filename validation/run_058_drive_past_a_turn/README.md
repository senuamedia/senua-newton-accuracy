# Run 058: a driven joint held at its target past pi and past a full turn (issue 27)

Not registered: a trace. Its play script [`play.sh`](play.sh) and the predictions below were pushed before any play.
Newton 1.7.0 as released, and with #4316 first on the path (run 053's engines). The rig
[`tools/nwt_joint.py`](../../tools/nwt_joint.py) gains `place=first`: the model's bodies placed from its joints' start
(`newton.eval_fk` on the model) before the solver is built. Run 054 found VBD captures its joints' rest angles when it
is built, and the rig, building it first, offset VBD's angle by the start angle (checked on the host before this run:
with `place=first` VBD holds a 2.5 rad target exactly); a play without the setting is unchanged.

## What is played

The record's arm, no gravity, a drive of 100 N m/rad and 10 N m s/rad, the arm at rest at its target, 0.1 ms, 1 s, at
2.5 rad (short of pi), 3.5 rad (past it) and 7.0 rad (past a full turn: [#4547](https://github.com/newton-physics/newton/issues/4547)'s
own case, its title saying past pi), on Featherstone, the MuJoCo solver, SemiImplicit, VBD, XPBD and XPBD with #4316,
each with `place=first`; SemiImplicit and VBD also built first, as before. Held: the last angle within 1 in 1,000 of the
target and the last speed within 0.01 rad/s of 0.

## Predictions, before any play

- VBD with its bodies placed first holds at all three (Newton 1.7.0's winding fix, #4470); built first, it is offset
  as in run 054.
- SemiImplicit holds at 2.5 and 3.5 (run 054) and not at 7.0, either way it is built (#4547).
- XPBD as released is thrown at 3.5 and 7.0 (run 054 at 3.5); with #4316 it holds at all three (its reference for an
  unlimited joint is the drive's target).
- Featherstone and the MuJoCo solver hold at all three.

## What was found

Played on the Newton host, 2026-10-19T13:39:30Z to 2026-10-19T13:48:20Z. Reading [`reading.txt`](reading.txt), checks
[`checks.txt`](checks.txt) (35 of 48 held; every failure read below).

| Target | Held at rest at the target's orientation | Not held |
|---|---|---|
| 2.5 rad | every solver with its bodies placed first; SemiImplicit built first | VBD built first (at 0: run 054's offset) |
| 3.5 rad | every solver placed first but XPBD as released; SemiImplicit built first | XPBD as released (thrown, 40 rad/s); VBD built first (at 2 pi) |
| 7.0 rad | Featherstone, the MuJoCo solver, SemiImplicit (both ways), VBD placed first, XPBD with #4316 | XPBD as released (thrown, 90 rad/s); VBD built first (at -2 pi) |

- **Read on another branch, not moved:** at 7.0 rad VBD placed first, XPBD with #4316 and SemiImplicit built first end
  at rest at -5,566,370 urad, which is 7 - 4 pi: the target's orientation. The rig's angle for these solvers is
  `newton.eval_ik`'s, twice the half-angle's atan2, which past a full turn can land a whole number of turns away; the
  check, against 7,000,000, failed on that alone (the speed held at 0 throughout).
- **The predictions:** VBD with its bodies placed first holds at all three (held); XPBD as released thrown past pi
  (held); #4316 holds at all three (held); Featherstone and the MuJoCo solver hold (held). **SemiImplicit holds at 7.0
  rad, against the prediction and #4547:** the report's scene is not this one (no joint attachment penalty, no angular
  damping, a unit inertia at the joint, a drive of 2 N m/rad, one 1 ms step, read against 1e-8 rad/s); not reproduced
  here, with Newton's own defaults.
- VBD's build order, run 054's finding, is confirmed: built before its bodies are placed, its drive takes the arm to a
  whole turn (0, 2 pi, -2 pi) at every target.

Every reading and check of this run was made again on the laptop, byte for byte, from its kept files, with a build of
[the measure](../../measure/README.md) (20 October 2026).
