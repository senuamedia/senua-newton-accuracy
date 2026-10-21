# Run 050: XPBD's joint limit with the swing's gradient taken exactly

19 October 2026, 02:40 to 02:41 UTC, on the Newton host, by [`play.sh`](play.sh), whose hypothesis and predictions
were pushed before the plays (with the patch, commit `811bca9`). Not registered: a trace. Newton 1.6.1 with
[`patches/in_design/xpbd_joint_angle_v2.diff`](../../patches/in_design/xpbd_joint_angle_v2.diff) (sha256
b969131ba1f65879...), built on the host from the release and checked file for file against the laptop's patched copy
(881 files). Switch `NEWTON_XPBD_JOINT_ANGLE_UNWRAP`: unset is Newton as released, 1 is run 035's joint-angle patch
alone, 2 is that patch with the swing's exact gradient. Reading [`reading.txt`](reading.txt), made with Senua AI's
`sx_contact` (`final`, `swing`), and the checks [`checks.txt`](checks.txt), both re-made byte for byte on the laptop
from the same files (46 of 46 lines, 12 of 12).

## The hypothesis

Run 048 traced XPBD's limit gain to its source: the swing part of the swing-twist split gives the angle exactly,
e = f(|v|) v with f = theta / sin(theta / 2), but its gradient is v's gradient times f alone, leaving out f's own
derivative, so along the axis it is (theta / 2) cot(theta / 2) of the true one. The exact gradient is
de/dv = f I + (2 / w - f) a a^T, with w = cos(theta / 2) and a = v / |v| (the twist part already takes its exact
2 / |w|). With it the limit's gain should be the relaxation at every angle.

A second question, for F14 (the arm leaves a limit turning back at most of its speed, at every gain). Read in the
source: the limit's correction is sized by the arm's inertia about its own centre (9e-4 kg m^2 for this arm), while
the arm turns about the joint (0.136 kg m^2), and the joint's linear constraint, sized separately from the same state,
turns most of that correction back into the arm's turn. If so, the return falls as the arm's centre comes in toward
the joint, and with no lever at all a full correction holds the arm.

## What was played

Run 048's arm (1.5 kg, half-size 0.03 m, its centre 0.3 m from the joint), no gravity, set turning at 3 rad/s from
L - 2.5 toward an upper limit L (lower limit L - 3), 1.4 s, at 1.6 and 0.32 ms. A chatter is more than one turning
point; the depth is the first turning point's angle less L.

| Limit L, relaxation | Turning points as released (run 048), 1.6; 0.32 ms | With switch 2: turning points | Depth past the limit, urad, 1.6; 0.32 ms | Last speed, rad/s, 1.6; 0.32 ms |
|---|---|---|---|---|
| 2.7 rad, 0.4 | 1; 1 | 1; 1 | 32,090; 6,643 | -2.56; -2.60 |
| 2.8 rad, 0.4 | 1; 1 | 1; 1 | 32,629; 6,541 | -2.57; -2.62 |
| 2.9 rad, 0.4 | 17; 19 | 1; 1 | 33,666; 6,824 | -2.60; -2.64 |
| 2.95 rad, 0.4 | 21; 17 | 1; 1 | 32,979; 6,734 | -2.61; -2.65 |
| 3.05 rad, 0.4 | 24, thrown; 17 | 1; 1 | 33,000; 6,673 | -2.63; -2.67 |
| 3.3 rad, 0.4 (run 048 with switch 1) | 17; 21 | 1; 1 | 33,369; 6,681 | -2.62; -2.66 |
| 3.8 rad, 0.4 (switch 1) | 1; 1 | 1; 1 | **37,501; 7,507** | -2.59; -2.60 |
| 4.5 rad, 0.4 (switch 1) | 1; 1 | 1; 1 | 33,298; 6,789 | -2.61; -2.65 |
| 2.9 rad, 0.2 | 1; 1 | 1; 1 | 34,002; 6,885 | -2.59; -2.63 |
| 2.95 rad, 0.2 | 3; 1 | 1; 1 | 33,284; 6,801 | -2.60; -2.64 |
| 3.05 rad, 0.2 | 15; 23 | 1; 1 | 33,246; 6,724 | -2.62; -2.66 |

The return's cause, with switch 2, a limit at 2.5 rad (lower -0.5), the arm's centre at 0.3, 0.1 and 0 m from the
joint:

| Arm's centre, relaxation | Depth past the limit, urad, 1.6; 0.32 ms | Last angle, rad, 1.6; 0.32 ms | Last speed, rad/s, 1.6; 0.32 ms |
|---|---|---|---|
| 0.3 m, 0.4 | 36,191; 7,421 | 1.266; 1.080 | -2.49; -2.57 |
| 0.1 m, 0.4 | 11,236; 2,278 | 1.418; 1.358 | -2.00; -2.03 |
| 0 m, 0.4 | 1,632; 299 | 2.190; 2.233 | -0.55; -0.47 |
| 0 m, 1 | 0; 0 | 2.49991; 2.49979 | -0.00015; -0.00043 |
| 0.3 m, 1 (reported) | thrown at both steps: 1.8e5 and 1.7e6 rad/s | | |

| Prediction | Result |
|---|---|
| P1: with switch 2, the eleven limits each turn the arm back once and none is thrown, at both steps | **Held**: 22 of 22 |
| P2: with switch 2, at each step and relaxation the first turning point lies the same distance past its limit at every limit, within 500 urad | **Failed**, 3 of 4 lines: at relaxation 0.4 the depths span 966 urad at 0.32 ms and 5,411 at 1.6 ms, 3.8 rad 12% and 14% deeper than the rest (without it, 283 and 1,576); at 0.2, 161 urad at 0.32 ms (held) and 756 at 1.6 ms |
| P3: with switch 2 the return stays: each of the 22 arms ends turning back at between 1 and 3 rad/s | **Held**: 2.56 to 2.67 rad/s |
| P4: with switch 2 at 2.5 rad and relaxation 0.4, the return is lower at 0.1 m than at 0.3 m, and lower at 0 m than at 0.1 m, at both steps | **Held**: 2.49, 2.00, 0.55 rad/s at 1.6 ms; 2.57, 2.03, 0.47 at 0.32 ms |
| P5: with switch 2 and relaxation 1, the arm with its centre at the joint is held: within 0.05 rad of 2.5 rad and slower than 0.1 rad/s, both steps | **Held**: within 93 and 206 urad, at 0.15 and 0.43 mrad/s |

| Check | Result |
|---|---|
| C1: unset on the patched source is run 048's release plays byte for byte (2.7 and 3.05 rad, both steps) | Held, 4 of 4 |
| C2: switch 1 is run 048's patched plays byte for byte (3.3, 3.8 and 4.5 rad, both steps) | Held, 6 of 6 |
| C3: an arm turning from 0.2 to 4.4 rad, past pi, inside limits it never reaches: switches 1 and 2 byte for byte, both steps | Held, 2 of 2 |

No play stopped being a number; the two thrown were the reported 0.3 m arm at relaxation 1.

## What it shows

- **The exact swing gradient removes the limit's unbounded gain (F14's angle dependence, and F13's second cause).**
  Every limit from 2.7 to 4.5 rad, at both relaxations, turns the arm back once: no chatter at 2.9 to 3.05 rad, where
  XPBD as released chatters, no throw at 3.05 rad, where it throws the arm, and none at 3.3 rad past pi, where run
  035's patch alone chatters. With the switch unset or at 1 nothing changes, and inside the limits it changes nothing.
- **A second angle dependence remains** (P2 failed): with the gain the same everywhere, a limit at 3.8 rad still lets
  the arm 12% to 14% deeper than the others, and the rest spread 4 to 5%. As released it is there too (a limit at 2.7 rad and
  gain 1.32 lets the arm 5,066 urad past at 0.32 ms, one at 2.9 rad and relaxation 0.2, gain 1.14, only 1,482). Read in
  the source, not yet tested: the joint's linear constraint is sized axis by axis along the world's x, y and z, each
  from the same state, and the three summed; for an anchor error that lies between the axes the sum depends on the
  arm's orientation to them. A probe that turns the joint's parent frame, keeping the joint angle, will tell.
- **F14's return is the limit's coupling to the joint's anchor, not its gain.** The exact gradient leaves it (2.56 to
  2.67 rad/s from 3); it falls as the arm's centre comes in toward the joint (2.57, 2.03, 0.47 rad/s at 0.32 ms), and
  with the centre on the joint a full correction holds the arm, within 0.21 mrad of its limit. This is what the source reading
  predicted: the limit's correction rotates the arm about its own centre, and the anchor's correction, sized from the
  same state, turns most of it back into the arm's turn. With no lever the remaining return at relaxation 0.4 (0.47
  to 0.55 rad/s) is consistent with the under-relaxed projection alone, two iterations of 0.4 leaving 36% of each
  step's overshoot.
- **With the arm on its lever, a full correction throws it** even with the exact gradient (reported): the limit's
  correction and the anchor's, each sized alone and summed, over-correct together. XPBD's default angular relaxation
  of 0.4, which also scales the anchor constraint's angular part, is what keeps its joints stable.
- Next, for issue 8: a limit solved with the joint's anchor held, its correction a rotation about the joint sized by
  the arm's inertia there (the limit's effective mass with the anchor constraint eliminated), and the probe of the
  linear constraint's orientation. The exact gradient goes forward as the first part of the patch.
