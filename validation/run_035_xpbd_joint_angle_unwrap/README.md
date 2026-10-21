# Run 035: a patch in design, XPBD's joint angle tracked continuously past pi

15 October 2026, 09:54 to 10:00 UTC. Not registered: a patch in design, held to the five checks. Played on the Newton
host by [`play.sh`](play.sh), whose predictions were pushed with the patch before the plays; reading `reading.txt`,
made with Senua AI's `sx_contact` (`chain`) and byte comparisons, re-made byte for byte on the laptop from the same
files. In the logs the home folder is written `~/`.

## The finding it answers

F13 (run 032): XPBD throws a joint that turns past pi inside limits it never reaches. Its joint solve
(`kernels.solve_body_joints`) takes the angle from the swing-twist split of the joint's relative rotation after putting
the two quaternions in the same hemisphere, so the angle it compares with the limits lies in [-pi, pi]: past pi it
reads about -pi, below a lower limit of -1 rad, and the solve pulls the joint back across the circle.

## The patch

[`patches/in_design/xpbd_joint_angle_unwrap.diff`](../../patches/in_design/xpbd_joint_angle_unwrap.diff) (sha256
ce0fe02dcf4b2ebe...), against Newton v1.6.1. A new module, `xpbd/joint_angle_unwrap_kernels.py`, holds a copy of the
joint kernel that keeps each revolute joint's last angle, unwrapped, and adds to the measured angle the whole turns
2 pi k, k = round((last - measured) / 2 pi), that bring it nearest the last: the standard unwrapping of a periodic
reading, nothing fitted. Where k is 0 the solve is the stock kernel's to the bit. The last angles start from the
state's joint coordinates. `NEWTON_XPBD_JOINT_ANGLE_UNWRAP=1`, read once when `solver_xpbd` is imported, launches the
copy in its place.

## The five checks

| Check | Measured | |
|---|---|---|
| **1. Required** | Run 032: a chain joint turning at 2 rad/s past pi inside limits of -1 and 4 rad is thrown (327,786 rad/s at 2.5 ms) | Held |
| **2. Correct** | With the switch, the chain with limits -1 and 4 rad is its play with no limits byte for byte, at 2.5 and 0.625 ms. With limits -1 and 3.5 rad, which it reaches past pi, the first joint ends at 3.470 and 3.466 rad (as released it is thrown, at 327,786 and 3,052,985 rad/s); at the end it turns at 0.04 and 0.62 rad/s | Held on the angle; the predicted speed bound failed at 0.625 ms (below) |
| **3. Nothing else gets worse** | With the switch, run 014's eight XPBD chain files (free and swinging, 10 ms to 0.156 ms) byte-identical, and the ten-test suite's 39 files byte-identical to run 007's XPBD suite | Held |
| **4. Safe when off** | No switch: run 032's four XPBD files byte-identical | Held |
| **5. The solver keeps converging** (here: no play stops being a number) | None did | Held |

| Prediction | Result |
|---|---|
| S: off, run 032's files | Held, 4 of 4 |
| C1: on, limits -1 and 4 rad plays as with none, byte for byte | Held at both steps |
| C2: on, limits -1 and 3.5 rad: the first joint within 0.05 rad of 3.5 and slower than 0.1 rad/s at the end, at both steps; off, thrown | Within 0.05 rad and off thrown: held. **Slower than 0.1 rad/s: failed** at 0.625 ms (0.62 rad/s) |
| N: on, run 014's XPBD chains and the suite byte for byte | Held, 8 of 8 and 39 of 39 |
| K: no play stops being a number | Held |

**Why the speed bound failed.** On this chain the second arm goes on swinging once the first joint stops at its limit,
and a limit only keeps a joint from passing it: the second arm can pull the first joint back inside its range. The
speed bound did not allow for that. A single arm on one joint has no such second body; Study 5 is registered on it.

## What it shows

- **The patch removes F13 on XPBD:** past pi, a joint inside its limits plays as with no limits, byte for byte, and a
  joint that reaches a limit beyond pi is held at it, where as released it is thrown.
- **It touches nothing else:** every play in which no joint passes pi is the release's byte for byte, the chains and
  the ten-test suite included, and with the switch unset it is the release.
