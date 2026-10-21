# Run 032: a joint turning past pi inside its limits (N6)

15 October 2026, 09:30 to 09:31 UTC, on the Newton host, by [`play.sh`](play.sh), whose predictions were pushed with
the rig's new settings before the plays. Not registered: a probe of a reported issue. Newton 1.6.1 from PyPI. Reading
`reading.txt`, made with Senua AI's `sx_contact chain` and the rig's own statistics lines, re-made byte for byte on
the laptop from the same files. In the logs the home folder is written `~/`.

## The question

Users report that XPBD's joint limits beyond plus or minus pi blow up, energy growing by orders of magnitude, because
it reads joint angles in (-pi, pi] (N6; [#4313](https://github.com/newton-physics/newton/issues/4313)). In the source,
XPBD's revolute limit (`xpbd/kernels.py`, `solve_body_joints`) measures the angle with an arcsine and wraps it into
(-pi, pi] before clamping it to the limits.

## The rig

[`tools/nwt_chain.py`](../../tools/nwt_chain.py) gains `lo1` and `hi1`, the first joint's limits, passed to Newton's
`add_joint_revolute` with its own limit stiffness and damping. With neither given the rig is as before: run 014's free
chain on XPBD at 2.5 ms, made again, is its kept file byte for byte.

## What was played

Run 014's two-link chain, straight, no gravity, turning as one body at 2 rad/s about the first joint for 1.9 s: the
joint goes from 0 to 3.8 rad, passing pi at 1.57 s. With limits of -1 and 4 rad it never reaches them, so nothing
should act: each play with the limits must be its play without them. XPBD, Featherstone, the MuJoCo solver and VBD at
2.5 and 0.625 ms; SemiImplicit at 0.078 ms (run 024: its joints need a step under 0.17 ms on this chain).

| The first joint at the end of 1.9 s (it turns at 2 rad/s and should be at 3.8 rad) | Without limits: angle, speed | With limits -1 and 4 rad: angle, speed | The two plays |
|---|---|---|---|
| **XPBD**, 2.5 ms | 3.76 rad, 1.97 rad/s | 5.95 rad, **327,786 rad/s** | differ |
| **XPBD**, 0.625 ms | 3.79 rad, 1.99 rad/s | -5.17 rad, **3,052,985 rad/s** | differ |
| **VBD**, 2.5 ms | 3.76 rad, 1.96 rad/s | 0.27 rad, 4.3 rad/s | differ |
| **VBD**, 0.625 ms | 3.79 rad, 1.99 rad/s | 0.48 rad, -491 rad/s | differ |
| Featherstone, 2.5 and 0.625 ms | 3.80 rad, 2.00 rad/s | the same | byte-identical |
| The MuJoCo solver, 2.5 and 0.625 ms | 3.80 rad, 2.00 rad/s | the same | byte-identical |
| SemiImplicit, 0.078 ms | 3.79 rad, 1.99 rad/s | the same | byte-identical |

(The speeds without limits are a little under 2 rad/s on XPBD and VBD: their joints' own loss, F9.) In the rig's
file, the limited XPBD and VBD plays at 2.5 ms first turn faster than 3 rad/s at step 633, five steps after the joint
passes pi. Neither play stopped being a number or left the format's range.

**A limit of the measure, found here.** On the limited XPBD and VBD plays the chain measure's energy fields are not
readings: the arms move at up to millions of radians a second, the kinetic energy's arithmetic passes its range, and
the fields come out wrapped (negative energies and ratios). Only the measure's angle and speed fields, read from the
last line as written, are used above.

| Prediction | Result |
|---|---|
| P1: XPBD's kinetic energy at the end with the limits departs from its value without them by more than 1 part in 10, at both steps | Held, read through the joint's speed: 327,786 and 3,052,985 rad/s against 1.97 and 1.99 |
| P2: SemiImplicit's the same | **Failed**: its plays with and without the limits are byte-identical |
| P3: Featherstone and the MuJoCo solver read the same with and without the limits, to the part per million | Held: byte-identical plays |
| Check: the changed rig with no limits gives run 014's file | Held |

## What it shows

- **The reported XPBD fault is there in Newton 1.6.1.** A joint that turns past pi inside limits of -1 and 4 rad, never
  reaching them, is thrown: within a few steps of passing pi its arms spin at hundreds of thousands of radians a second.
- **VBD does it too**: with the same limits its joint is dragged back to 0.3 to 0.5 rad and set spinning the wrong
  way.
- **SemiImplicit, Featherstone and the MuJoCo solver do not**: with the limits each plays byte for byte as without
  them. SemiImplicit's limit takes its angle from a quaternion's twist, which evidently does not wrap at pi (the
  prediction from the source was wrong).
