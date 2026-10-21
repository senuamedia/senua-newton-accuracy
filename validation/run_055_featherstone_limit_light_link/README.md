# Run 055: Featherstone's joint limit on a light link, either side of its explicit bound (issue 28)

Not registered: a trace. Its play script [`play.sh`](play.sh) and the predictions below were pushed before any play.
Newton 1.7.0 as released.

## The hypothesis

Issue 28 (N19, [#4269](https://github.com/newton-physics/newton/issues/4269)): Featherstone stops being a number within
0.1 s on 6-axis arms and humanoids that the MuJoCo solver plays; a sixteenth of the step does not help, gravity off or
the joint limits widened stops it or delays it tenfold, and an armature of 0.1 on every joint stops it. Read in 1.7.0's
source: Featherstone's joint limit is Newton's `joint_force` (`solvers/semi_implicit/kernels_body.py`), a spring
`limit_ke (limit - q)` and a damper `-limit_kd qd` once past the limit, Newton's defaults 1e4 N m/rad and 10 N m s/rad,
evaluated at the step's start, and its joints are integrated by semi-implicit Euler (`jcalc_integrate`:
`qd_new = qd + qdd dt`, `q_new = q + qd_new dt`). On a joint of inertia I that is stable only while
w^2 dt^2 + 2 g dt < 4 (w^2 = ke / I, g = kd / I), that is for dt < (-g + sqrt(g^2 + 4 w^2)) / w^2 (computed with `bc`).
The issue's links weigh 1e-6 to 1.6e-4 kg m2: the bound is 0.2 to 31.5 us, under every step it tried (1/240 to
1/4000 s); with the armature, 5.4 ms, over 1/240 s. Gravity presses a fixed arm's links on their limits; a free
quadruped's fall presses none. If this is the cause, a single light link resting on its limit under gravity diverges
at every step above the bound and is held at every step below it, with no other ingredient of the issue's robots.

## What is played

One arm on one hinge, released level under gravity (the rig's 9.8 m/s2) onto its lower limit, -0.5 rad (upper 0.5):

| Arm | Mass, half-size, centre's distance | I about the joint | Limit | Bound |
|---|---|---|---|---|
| light | 0.05 kg, 0.01 m, 0.02 m | 2.333e-5 kg m2 | Newton's default | **4.66 us** |
| light, no damper | the same | the same | `limitd=0` | **96.6 us** |
| the record's | 1 kg, 0.05 m, 0.5 m | 0.2517 kg m2 | Newton's default | **9.08 ms** |

Steps: the light arm at 1/240 s, 1 ms, 250, 100, 20, 10, 5 and 2 us, 0.15 s (it reaches its limit at about 0.049 s);
without the damper at 250, 100, 50 and 20 us; the record's arm at 1/240 s and 1 ms, 0.5 s. Each on Featherstone and
on the MuJoCo solver. Held: a number throughout, the last angle within 1 in 100 of -0.5 rad and the last speed within
0.01 rad/s of 0.

## Predictions, before any play

- Featherstone's light arm is not held at any step above 4.66 us (1/240 s to 5 us: it stops being a number, leaves
  the format's range or is thrown off the limit) and is held at 2 us.
- Without the damper it is not held at 250 or 100 us (the bound 96.6 us) and is held at 50 and 20 us.
- The record's arm is held at 1/240 s and 1 ms (its bound 9.08 ms).
- The MuJoCo solver holds every play.

## What was found

Played on the Newton host, 2026-10-19T13:09:06Z to 2026-10-19T13:28:20Z (a second play: the first, from 1a3d5fa, lost its
play files when the host's disk filled, and is not kept; this one from f864db7, whose rig change does not touch these
plays). Reading [`reading.txt`](reading.txt), checks [`checks.txt`](checks.txt) (36 of 84 held).

- **The bound holds: Featherstone's light arm diverges above it and stays bounded below it.** With Newton's default
  limit (bound 4.66 us) it stops being a number at every step from 1/240 s to 10 us (at steps 14, 53, 202, 508, 2,839
  and 7,218); at 5 us, just above the bound, it is thrown off the limit (last speed 18.8 rad/s); at 2 us it rests on
  the limit (15 urad past it, its last speed 0.014 rad/s, narrowly over the 0.01 check). With no damper (bound 96.6
  us) it stops being a number at 250 us, is thrown at 100 us, and at 50 and 20 us stays bounded, bouncing.
- **This is issue 28's mechanism.** Newton's limit is an explicit spring and damper; on a link of inertia I it is stable
  only for steps under (-g + sqrt(g^2 + 4 w^2)) / w^2, 0.2 to 31.5 us for the reported robots' links (1e-6 to 1.6e-4
  kg m2), under every step the report tried; their armature of 0.1 raises it to 5.4 ms, over 1/240 s, which is why it
  stopped the divergence. Gravity presses a fixed arm's links on their limits; a free quadruped's fall presses none.
- **Two predictions were wrong as written:** without the damper the arm cannot come to rest on a spring alone, so
  "held" was the wrong reading there (it bounces, bounded, as the bound says); and the record's arm, with Newton's
  limit damped at a ratio of 0.1, is still bouncing at 0.5 s at both steps (bounded, a number throughout), not held.
- **The MuJoCo solver** is stable in every play; it holds the light arm at every step but 1/240 s (24.5 mrad past the
  limit), and without the damper rests about 20 mrad past it, turning at 0.5 rad/s.

Every reading and check of this run was made again on the laptop, byte for byte, from its kept files, with a build of
[the measure](../../measure/README.md) (20 October 2026).
