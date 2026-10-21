# Run 048: XPBD's joint limit against the angle it lies at

15 October 2026, 11:21 to 11:22 UTC, on the Newton host, by [`play.sh`](play.sh), whose hypothesis and predictions
were pushed before the plays. Not registered: a trace. Newton 1.6.1 from PyPI (stock) and run 035's patched source
with `NEWTON_XPBD_JOINT_ANGLE_UNWRAP=1` (on). Reading `reading.txt`, made with Senua AI's `sx_contact` (`final`,
`swing`), re-made byte for byte on the laptop from the same files.

## The hypothesis, read in the source

Run 046 found XPBD's limit acts differently at different angles. In `solve_body_joints` (`xpbd/kernels.py`) a revolute
joint about z gets its angle from the swing part of the swing-twist split: the error is the angle exactly, but its
gradient is the quaternion component's gradient multiplied by the scale theta / sin(theta / 2), the scale's own
derivative left out. The constraint's angular Jacobian along the axis is then (theta / 2) cot(theta / 2), not 1: 0.80
at 1.5 rad, 0.42 at 2.5 rad, 0.11 at 3.0 rad, 0 at pi. Each iteration corrects the limit's overshoot by relaxation over
that, so with the default relaxation of 0.4 the limit's gain is 0.50 at 1.5 rad, 0.96 at 2.5 rad and 3.8 at 3.0 rad,
without bound toward pi. Where the gain passes 2 a correction overshoots by more than it corrects and the limit should
chatter: beyond 2.86 rad at relaxation 0.4, beyond 3.01 rad at 0.2. It also accounts for run 040, where relaxation 1
at 2.5 rad (a gain of 2.41) threw the arm. (The script's comment gives 1.07 at 2.5 rad, 2.67 for run 040 and 1.05 at
3.8 rad, slips of arithmetic: they are 0.96, 2.41 and 0.94; no prediction depends on them.)

## What was played

Run 046's arm (1.5 kg, half-size 0.03 m, 0.3 m), no gravity, set turning at 3 rad/s from L - 2.5 toward an upper limit
L (lower limit L - 3), 1.4 s, at 1.6 and 0.32 ms. A chatter is more than two turning points.

| Upper limit L, relaxation | Turning points, 1.6 ms | Turning points, 0.32 ms | Last speed, rad/s (1.6; 0.32 ms) |
|---|---|---|---|
| 2.7 rad, 0.4 (gain 1.32) | 1 | 1 | -2.18; -2.20 |
| 2.8 rad, 0.4 (1.66) | 1 | 1 | -2.37; -2.41 |
| 2.9 rad, 0.4 (2.27) | 17 | 19 | -2.44; -2.49 |
| 2.95 rad, 0.4 (2.82) | 21 | 17 | -2.93; -2.72 |
| 3.05 rad, 0.4 (5.7) | 24, **thrown**: 553,966 rad/s | 17 | thrown; -2.89 |
| 2.9 rad, 0.2 (1.14) | 1 | 1 | -2.39; -2.43 |
| 2.95 rad, 0.2 (1.41) | **3** | 1 | -2.43; -2.47 |
| 3.05 rad, 0.2 (2.86) | 15 | 23 | -3.25; -2.67 |
| 3.3 rad, 0.4, with the patch (wrapped -2.98: 3.4) | 17 | 21 | -2.42; -2.48 |
| 3.8 rad, 0.4, with the patch (wrapped -2.48: 0.94) | 1 | 1 | -2.46; -2.45 |
| 4.5 rad, 0.4, with the patch (wrapped -1.78: 0.56) | 1 | 1 | -2.57; -2.61 |

| Prediction | Result |
|---|---|
| P1: at relaxation 0.4, 2.7 and 2.8 rad turn the arm back once, 2.9, 2.95 and 3.05 rad chatter, both steps | Held |
| P2: at relaxation 0.2, 2.9 and 2.95 rad once, 3.05 rad chatters, both steps | **Failed** at one play: 2.95 rad at 1.6 ms has three turning points (swings of 1 and 9 per 10,000 after the first), not the 15 to 23 of a chatter; the rest held |
| P3: with the patch, 3.3 rad chatters, 3.8 and 4.5 rad once, both steps | Held |

No play stopped being a number; one arm was thrown (3.05 rad as released at 1.6 ms).

## What it shows

- **Traced: XPBD's limit acts with a gain of relaxation / ((theta / 2) cot(theta / 2)).** The chatter begins between
  2.8 and 2.9 rad at the default relaxation, as the gain predicts (2.86), and moves to about 3 rad when the relaxation
  is halved; with the joint-angle patch a limit past pi follows its wrapped angle, chattering at 3.3 rad (wrapped
  -2.98) and not at 3.8 or 4.5. The one play off by a little sits next to the predicted edge.
- **A limit before pi can throw the arm too**: at 3.05 rad, with no angle ever past pi, the arm is thrown at 1.6 ms.
  Near pi the limit's gain has no bound; this is a second cause of F13's throw, beside the angle's wrap.
- The return itself (F14) is there at every gain, 2.2 to 3.3 rad/s from 3: the gain sets how the limit acts, not
  whether it gives back the speed. For a user: keep a revolute joint's limits on XPBD well inside 2.8 rad of the
  joint's zero, or the limit chatters and may throw.
