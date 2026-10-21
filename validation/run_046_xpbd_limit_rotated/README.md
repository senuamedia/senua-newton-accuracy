# Run 046: XPBD's joint limit with the whole scene turned, before and past pi

15 October 2026, 11:15 to 11:16 UTC, on the Newton host, by [`play.sh`](play.sh), whose hypothesis and predictions
were pushed before the plays. Not registered: a trace. Newton 1.6.1 from PyPI (stock) and run 035's patched source
with `NEWTON_XPBD_JOINT_ANGLE_UNWRAP=1` (on). Reading `reading.txt`, made with Senua AI's `sx_contact` (`final`; the
turning points read with `swing`), re-made byte for byte on the laptop from the same files.

## The question

Study 5's R4 (run 037) asked an arm reaching a limit past pi to be held there; it failed because XPBD's limit throws
an arm back off a limit before pi too (F14). A later study can pose R4 against XPBD's own limit before pi. With no
gravity, turning the whole scene (the start and both limits by one angle) changes nothing in the physics, so the
hypothesis was that, with the patch, XPBD's limit plays the same wherever it lies; how close the plays come is what such
a rule's bound needs.

## What was played

Study 5's arm (1.5 kg, half-size 0.03 m, 0.3 m), no gravity, set turning at 3 rad/s from a0, limits a0 - 0.5 and
a0 + 2.5 rad, 1.4 s.

| Upper limit (start a0) | as released, 1.6 ms | with the patch, 1.6 ms | as released, 0.32 ms | with the patch, 0.32 ms |
|---|---|---|---|---|
| 1.5 rad (-1) | turned back at -2.62 rad/s, 27.7 mrad past | the same file | -2.66, 5.6 mrad past | the same file |
| 2.5 rad (0; Study 5's below) | -2.29, 18.5 mrad | the same | -2.39, 3.8 mrad | the same |
| 3.0 rad (0.5) | **-3.02**, chatters on the limit first | the same | -2.64, chatters first | the same |
| 3.5 rad (1), past pi | thrown, 2,025,196 rad/s | -2.35, 20.6 mrad | thrown | -2.38, 4.0 mrad |
| 4.5 rad (2), past pi | thrown | -2.57, 26.1 mrad | thrown | -2.61, 5.3 mrad |

(The speed is the arm's last; how far past the limit it turned is its first turning point less the limit.)

| Prediction | Result |
|---|---|
| P1: with the patch, every turned scene's last angle less its start within 0.01 rad of a0 = 0's, its last speed within 0.01 rad/s | **Failed**: the returns range from -2.29 to -3.02 rad/s at 1.6 ms, before pi as well as past it |
| P2: as released, the scenes past pi thrown (over 100 rad/s) | Held |
| Check: a0 = 0, run 037's below files, as released and with the patch | Held, 4 of 4 |

No play stopped being a number.

## What it shows

- **XPBD's limit is not the same when the scene is turned**, before pi as well as past it: an arm's return off its
  limit depends on the angle the limit lies at (2.62, 2.29 and 3.02 rad/s for limits at 1.5, 2.5 and 3.0 rad at
  1.6 ms, from 3 rad/s), and at 3.0 rad it chatters on the limit before it leaves faster than it came. Traced in
  run 048 to the limit's Jacobian.
- **With the patch, a limit past pi acts as XPBD's limits before pi do**: every arm turns back within 0.028 rad past
  its limit and leaves at 2.35 to 2.61 rad/s, inside the range of the same arm's returns before pi (2.29 to 3.02 at
  1.6 ms, 2.39 to 2.66 at 0.32 ms, where the limit at 3.5 rad, 2.38, is just under it); as released the arm is
  thrown. A study posing R4 against XPBD's own limit has to allow for the spread across limit angles.
