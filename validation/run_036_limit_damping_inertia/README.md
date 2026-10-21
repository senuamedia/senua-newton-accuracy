# Run 036: a joint limit's strike against the arm's inertia (N5)

15 October 2026, 10:00 to 10:07 UTC, on the Newton host, by [`play.sh`](play.sh), whose predictions were pushed with
the new rig before the plays. Not registered: a probe of a reported issue. Newton 1.6.1 from PyPI. Reading
`reading.txt`, made with Senua AI's `sx_contact swing` and the rig's own statistics lines, re-made byte for byte on the
laptop from the same files. In the logs the home folder is written `~/`.

## The question

Users report that on Newton's MuJoCo path joint-limit damping depends on the body's inertia: four similar pendulums
got damping ratios 3.07, 0.31, 0.055 and 0.0097 (N5; [#4099](https://github.com/newton-physics/newton/issues/4099)).
Newton gives a limit a stiffness and a damping (`limit_ke` 1e4 N m/rad and `limit_kd` 10 N m s/rad by default); past
the limit the arm meets that spring and damper, whose damping ratio z = kd / (2 sqrt(ke I)) falls as 1 / sqrt(I).
Newton 1.6.1's MuJoCo solver now scales MuJoCo's limit reference so that its effective stiffness and damping are meant
to be Newton's (`update_jnt_solref_from_invweight0_kernel`).

## The rig

A new rig, [`tools/nwt_joint.py`](../../tools/nwt_joint.py), plays the first deep dive's one-arm scene (`sdx_joint`) on
Newton and writes its format: the joint's angle and speed every step, read by `sx_contact swing` at the arm's turning
points. Its check: with no limit, released level, the arm on the MuJoCo solver with RK4 comes up level on the other
side, 9,999 and then 10,000 per 10,000 of half a turn.

## What was played

An arm 0.4 m long (a cube of half-size 0.04 m at its end) released level with gravity onto its lower limit at -1 rad,
masses 0.1, 1, 10 and 100 kg (z = 0.39, 0.12, 0.039 and 0.012), 2 s, at 0.25 ms and 10 ms. A spring-damper strike
keeps e = exp(-z pi / sqrt(1 - z^2)) of the speed and the arm then turns at asin(-0.8415 (1 - e^2)) (gravity during the
strike neglected).

| Where the arm turns back after its first strike, rad (and how far it went past the limit), 0.25 ms | 0.1 kg | 1 kg | 10 kg | 100 kg |
|---|---|---|---|---|
| The spring-damper with Newton's ke and kd | -0.90 | -0.48 | -0.19 | -0.06 |
| **Featherstone** | **-0.890** (0.005) | **-0.484** (0.022) | **-0.191** (0.078) | **-0.069** (0.269) |
| VBD | -0.938 (0.005) | -0.553 (0.021) | -0.226 (0.076) | -0.085 (0.261) |
| **The MuJoCo solver** | **-0.351** (0.032) | **-0.135** (0.110) | **-0.045** (0.360) | **-0.014** (1.144) |
| XPBD (every mass alike) | -0.258 (0.011) | -0.258 | -0.258 | -0.258 |

At 10 ms: Featherstone leaves the format's range at the two lightest masses (steps 36 and 114: its explicit limit
spring, sqrt(ke / I) of 788 and 249 rad/s, is past its stability limit there) and plays the two heaviest as at
0.25 ms; the MuJoCo solver reads within 0.04 rad of its own 0.25 ms turns except at 0.1 kg (-0.842); XPBD turns at
-1.151 for every mass; VBD at 0.1 and 1 kg stays at the limit (it turns back by 0 and 22 per 10,000).

| Prediction | Result |
|---|---|
| P1: Featherstone at 0.25 ms within 0.05 rad of -0.90, -0.48, -0.19 and -0.06 | Held: within 0.01 rad at every mass |
| P2: the MuJoCo solver at 0.25 ms within 0.02 rad of Featherstone at each mass | **Failed** at every mass: it goes 6 to 4 times further past the limit and rebounds much higher |

No play stopped being a number.

## What it shows

- **Featherstone plays Newton's limit as the spring and damper it is given**, to 0.01 rad of the closed form, and VBD
  close to it.
- **The MuJoCo solver does not, in 1.6.1, despite the conversion.** Its limit is about 15 to 20 times softer than
  `limit_ke` (the 100 kg arm goes 1.14 rad past a limit Featherstone holds to 0.27) and damps far less: from the
  rebound, its damping ratio is about a fifth of Newton's at every mass. The ratio still falls as 1 / sqrt(I), as the
  spring-damper's does, so the report's inertia dependence is not reproduced as such; what is reproduced is a limit
  whose stiffness and damping are not the ones Newton was given. Not traced.
- **XPBD's limit takes no notice of `limit_ke` and `limit_kd`:** every mass turns back at the same angle (its own
  limit, which returns the arm, F14).
