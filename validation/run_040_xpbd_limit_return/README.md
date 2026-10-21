# Run 040: XPBD throwing an arm back off a joint limit, against its relaxation and iterations (F14)

15 October 2026, 10:28 to 10:29 UTC, on the Newton host, by [`play.sh`](play.sh), whose hypothesis and predictions
were pushed before the plays. Not registered: a trace. Newton 1.6.1 from PyPI. Reading `reading.txt`, made with Senua
AI's `sx_contact` (`final`), re-made byte for byte on the laptop from the same files. In the logs the home folder is
written `~/`.

## The question

In Study 5 (run 037) an arm turning at 3 rad/s onto a joint limit at 2.5 rad on XPBD left it turning back at 2.29 and
2.39 rad/s, most of its speed (F14). XPBD's limit is a position correction of the angle past the limit, scaled each
iteration by `joint_angular_relaxation` (0.4 by default), 2 iterations, and XPBD moves a body's velocity by each
position correction. The hypothesis: the return is that correction left as speed, the joint's form of F5, and it
depends on how the correction is spread over the step's iterations.

## What was played

Study 5's arm (1.5 kg, half-size 0.03 m, 0.3 m), no gravity, turning at 3 rad/s onto limits -0.5 and 2.5 rad, 1.4 s,
on XPBD at 1.6 and 0.32 ms.

| The arm at the end: angle (rad), speed (rad/s) | 1.6 ms | 0.32 ms |
|---|---|---|
| As released (relaxation 0.4, 2 iterations; Study 5's files byte for byte) | 1.328, -2.29 | 1.170, -2.39 |
| 8 iterations | 1.416, -2.02 | 1.340, -2.07 |
| Relaxation 1 | thrown: 933,890 rad/s | thrown: 30,221,332 rad/s |
| Relaxation 1, 8 iterations | thrown: 3,344,188 rad/s | thrown: 64,697,024 rad/s |

| Prediction | Result |
|---|---|
| P1: as released, Study 5's plays byte for byte | Held |
| P2: with relaxation 1 and 8 iterations the arm turns back slower than as released | **Failed**: the arm is thrown at millions of radians a second |

No play stopped being a number.

## What it shows

- **The return is not the correction spread over the iterations.** Four times the iterations take only a tenth off the
  return speed (2.02 and 2.07 rad/s against 2.29 and 2.39).
- **XPBD's angular limit with its relaxation at 1 throws the arm**, alone or with 8 iterations: a full correction each
  iteration overshoots, so the default relaxation of 0.4 is keeping the limit stable rather than tuning it.
- F14's cause is not traced here. It stays a measured finding; a study of the joint-angle patch with its fourth rule
  posed against XPBD's own limit before pi waits on it.
