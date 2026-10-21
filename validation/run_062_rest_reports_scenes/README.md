# Run 062: a driven joint at rest in issue 27's own scenes

Not registered: a trace. Its play script [`play.sh`](play.sh), its rig and the predictions below were pushed before
its plays. Newton 1.7.0 as released. The rig [`tools/nwt_rest.py`](../../tools/nwt_rest.py) builds the two reports'
scenes as they wrote them ([#4547](https://github.com/newton-physics/newton/issues/4547): a revolute about z;
[#4540](https://github.com/newton-physics/newton/issues/4540): a D6 with angular axes y and z, targets 0.2 and 0.4 rad):
one body of 1 kg and unit inertia at the joint, no gravity, the drives at 2 N m/rad with no damping, the joint started
at rest at its targets.

Run 058 found SemiImplicit holding a driven arm at rest at 7.0 rad with Newton's defaults on this record's arm (1 kg,
its centre 0.5 m from the joint, a drive of 100 N m/rad and 10 N m s/rad). This run plays the reports' scenes, which
differ in the body, the drive and SemiImplicit's settings.

## What is played

The revolute at 2.5, 3.5 and 7.0 rad and the D6, one step and a thousand at 1 ms, on Featherstone, the MuJoCo solver
(MuJoCo Warp, this record's path; the reports' tests ran `use_mujoco_cpu`), XPBD, SemiImplicit with its defaults, and
SemiImplicit as the reports set it (`angular_damping=0`, `joint_attach_ke=0`, `joint_attach_kd=0`). Held: the last
speed 0 at the format's resolution (under 0.5 urad/s; the reports test 1e-8 rad/s after one step).

**Disclosed before the plays:** the rig was checked on the host by four plays of three steps with Newton's defaults:
Featherstone held both scenes; SemiImplicit's revolute at 7.0 rad read -5,566,220 urad (7 - 4 pi) turning at 0.075
rad/s, and its D6 0.200003 rad turning at 0.0013 rad/s. 0.075 rad/s is 2 N m/rad times 4 pi over the unit inertia for
3 ms: a drive working from the angle read two turns away (7 - 4 pi) against its target of 7.0.

## Predictions, before the plays

- SemiImplicit, both ways, is not held at 7.0 rad: its drive's error is 4 pi, so one step leaves it turning at
  2 x 4 pi x 0.001 = 0.0251 rad/s (25,133 urad/s), and it is held at 2.5 and 3.5 rad; its D6 is not held (#4540).
- Featherstone and the MuJoCo solver hold every play.
- XPBD is not held at 3.5 or 7.0 rad (runs 054 and 058), held at 2.5; its D6 not predicted.

## What was found

Played on the Newton host, 2026-10-19T14:14:57Z to 2026-10-19T14:17:26Z. Reading [`reading.txt`](reading.txt), checks
[`checks.txt`](checks.txt) (30 of 50 held: every failure is a play predicted not held, or XPBD's D6).

| Scene | Featherstone, the MuJoCo solver | SemiImplicit (both ways) | XPBD |
|---|---|---|---|
| revolute at 2.5 rad | held | held | held |
| revolute at 3.5 rad | held | held | not held: 2,534 urad/s after one step; thrown by 1 s |
| revolute at 7.0 rad | held | **not held: 25,131 and 25,133 urad/s after one step** (predicted 25,133); thrown by 1 s | not held: thrown |
| the D6 at 0.2 and 0.4 rad | held | **not held**: 434 and 392 urad/s after one step; at 0.43 and 0.56 rad by 1 s | not held: 5.3 rad/s after one step |

- **Both reports reproduced in their own scenes.** SemiImplicit's drive at 7.0 rad works from the angle read two
  turns away (7 - 4 pi): one step leaves it turning at k 4 pi dt / I, to the microradian a second; its two-axis D6
  drifts from its targets. Its own settings (the reports' or Newton's defaults) change neither.
- **Run 058's arm, held by SemiImplicit at 7.0 rad, differs from these scenes** in its body (1 kg, its centre 0.5 m from
  the joint, not a unit inertia at it), its drive (100 N m/rad and 10 N m s/rad, not 2 and 0) and its settings; which
  of these keeps that drive from the wrapped angle was not traced.
- XPBD's D6 is not held either (not predicted), at 5.3 rad/s after one step.
- Featherstone and the MuJoCo solver hold every play, as predicted.

Every reading and check of this run was made again on the laptop, byte for byte, from its kept files, with a build of
[the measure](../../measure/README.md) (20 October 2026).
