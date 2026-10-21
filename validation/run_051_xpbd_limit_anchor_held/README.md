# Run 051: XPBD's joint limit sized with the joint's anchor held

19 October 2026, 02:54 to 02:56 UTC, on the Newton host, by [`play.sh`](play.sh), whose hypothesis and predictions
were pushed before the plays (with the patch, commit `cfdf34d`). Not registered: a trace. Newton 1.6.1 with
[`patches/in_design/xpbd_joint_angle_v3.diff`](../../patches/in_design/xpbd_joint_angle_v3.diff) (sha256
c89335b616f1b628...), built on the host from the release and checked file for file against the laptop's patched copy
(881 files). Switch `NEWTON_XPBD_JOINT_ANGLE_UNWRAP`: unset as released; 1 run 035's patch; 2 run 050's (with the
swing's exact gradient); 3 this run's. Reading [`reading.txt`](reading.txt), made with Senua AI's `sx_contact`
(`final`, `swing`), and the checks [`checks.txt`](checks.txt), both re-made byte for byte on the laptop from the same
files (64 of 64 lines, 12 of 12).

## The hypothesis

Run 050 traced F14's return to the limit's coupling to the joint's anchor: XPBD sizes each of a joint's constraints
alone, from the same state, and sums the corrections, so the limit's correction rotates the arm about its own centre,
with its inertia there, and the anchor's correction turns most of it back. The third form sizes a revolute joint's
limit with the anchor's three rows eliminated: its effective inverse mass is the Schur complement
w = J M^-1 J^T - b^T K^-1 b (K the anchor's 3 x 3 inverse mass matrix, b = G M^-1 J^T its coupling to the limit), and
its correction is applied along M^-1 (J^T - G^T K^-1 b), which leaves the anchor in place to first order; for one body
on a fixed joint that is a rotation about the joint by the body's inertia there, I + m r^2, the parallel-axis theorem.
Every other constraint is the stock kernel's. If the coupling is the cause, a limit acts on an arm with a lever as on
an arm with none, at every angle, and what remains is the limit's own projection: the relaxation over the step's two
iterations.

## What was played

Run 050's arm (1.5 kg, half-size 0.03 m), no gravity, set turning at 3 rad/s from L - 2.5 toward an upper limit L
(lower limit L - 3), 1.4 s, at 1.6 and 0.32 ms; its centre 0.3 m from the joint unless named. The depth is the first
turning point's angle less L; held is within 0.05 rad of the limit and slower than 0.1 rad/s at the end. All with
switch 3 unless named.

| Limit L | Relaxation 0.4: depth, urad, 1.6; 0.32 ms | Relaxation 0.4: last speed, rad/s | Relaxation 1: last angle short of L, mrad | Relaxation 1: last speed, rad/s |
|---|---|---|---|---|
| 2.7 rad | 1,438; 279 | -0.447; -0.504 | 19.2; 3.8 | -0.036; -0.005 |
| 2.8 rad | 1,448; 280 | -0.431; -0.499 | 25.2; 5.3 | -0.048; -0.009 |
| 2.9 rad | 1,464; 281 | -0.421; -0.496 | 29.0; 6.8 | -0.054; -0.012 |
| 2.95 rad | 1,473; 280 | -0.422; -0.493 | 25.6; 4.3 | -0.048; -0.009 |
| 3.05 rad | 1,493; 281 | -0.436; -0.492 | 11.5; 4.3 | -0.021; -0.007 |
| 3.3 rad (past pi) | **1,576**; 284 | -0.557; -0.501 | **56.3**; 10.1 | **-0.102**; -0.016 |
| 3.8 rad (past pi) | 1,471; 281 | -0.469; -0.503 | 18.7; 2.6 | -0.035; -0.008 |
| 4.5 rad (past pi) | 1,470; 281 | -0.421; -0.494 | 27.0; 5.7 | -0.050; -0.010 |

With switch 2 (run 050) the same limits at relaxation 0.4 went 32,090 to 37,501 urad and 6,541 to 7,507 urad deep and
turned the arm back at 2.56 to 2.67 rad/s. At relaxation 0.2 with switch 3 the depths are 3,433 to 3,474 and 730 to
732 urad, the arm turning back at 0.94 to 0.99 rad/s.

The lever, a limit at 2.5 rad (lower -0.5):

| Arm's centre | Relaxation 0.4: depth, urad, 1.6; 0.32 ms | Relaxation 0.4: last speed, rad/s | Relaxation 1: last angle short of 2.5 rad, mrad | Relaxation 1: last speed, rad/s |
|---|---|---|---|---|
| 0.3 m | 1,427; 279 | -0.465; -0.506 | 4.1; 2.7 | -0.0088; -0.0041 |
| 0.1 m | 1,568; 338 | -0.515; -0.585 | 0.003; 0.001 | 0; 0 |
| 0 m | 1,632; 299 | -0.551; -0.472 | 0.093; 0.206 | -0.00015; -0.00043 |
| 0.3 m with switch 2 (run 050) | 36,191; 7,421 | -2.49; -2.57 | thrown | thrown |

| Prediction | Result |
|---|---|
| P1: at relaxation 0.4 and 2.5 rad, the 0.3 and 0.1 m arms end within 0.1 rad/s of the 0 m arm's speed and within 10% of its depth, at both steps | **Failed**, 5 of 8 lines: the 0.1 m arm turns back 0.113 rad/s faster than the 0 m arm at 0.32 ms; the 0.3 m arm goes 12.6% less deep at 1.6 ms and the 0.1 m arm 13.0% deeper at 0.32 ms. (With switch 2 the 0.3 m arm turned back about 2 rad/s faster and went 22 to 25 times as deep) |
| P2: at relaxation 1 the three arms at 2.5 rad are held, both steps | **Held**: 6 of 6 |
| P3: at relaxation 1 the arm is held at each of the eight limits, three past pi, both steps | **Failed**, 15 of 16: at 3.3 rad and 1.6 ms the arm ends 56.3 mrad short of the limit, drifting back at 0.102 rad/s |
| P4: at each step and relaxation the largest and smallest depths differ by at most 5% of the largest | **Failed**, 3 of 4 lines: at relaxation 0.4 and 1.6 ms they differ by 8.8%, 3.3 rad the deepest (3.7% without it); 1.8% at 0.32 ms, 1.2% and 0.3% at relaxation 0.2 |
| P5: at relaxation 0.4 each of the eight limits turns the arm back slower than 1 rad/s, both steps | **Held**: 16 of 16, 0.42 to 0.56 rad/s |

| Check | Result |
|---|---|
| C1: the free arm passing pi inside limits it never reaches, switch 3 as run 050's switch 2, byte for byte, both steps | Held, 2 of 2 |
| C2: the third form's source unset is run 048's release plays (4), at 1 run 048's patched 3.8 rad plays (2), at 2 run 050's plays (4), byte for byte | Held, 10 of 10 |

No play stopped being a number. Reported: the free arm at relaxation 1 with switch 3 plays (2.987 and 2.938 rad/s at the
end, against 2.988 and 2.938 at 0.4).

## What it shows

- **The coupling was the cause of F14's return, and holding the anchor removes it.** On its 0.3 m lever the arm now
  turns back at about 0.5 rad/s where it turned back at 2.5, goes as deep as the arm with no lever to within 13%, where
  it went 22 to 25 times as deep, and the eight limits from 2.7 to 4.5 rad act alike (all but one within 4%). P1's
  bounds of 0.1 rad/s and 10% were tighter than the arms agree; the change they test is about twenty times larger.
- **With a full correction the limit holds the arm, at every lever and every angle, past pi too**: 21 of 22 plays
  within 0.05 rad of the limit and slower than 0.1 rad/s, where with switch 2 the arm on its lever is thrown. That is
  Study 5's R4, a limit reached past pi holding the arm. The held arms drift back slowly, more at the coarse step (0.009
  to 0.10 rad/s at 1.6 ms, 0.004 to 0.016 at 0.32 ms) and more on the longer lever (the 0.1 m and 0 m arms do not
  drift); the one miss, 3.3 rad at 1.6 ms, is the largest drift. Not traced.
- **At the default relaxation of 0.4 the limit still lets the arm go at about a sixth of its speed** (0.42 to 0.56 rad/s
  of 3), as the arm with no lever did in run 050: the limit's own projection, two iterations of 0.4 leaving 36% of each
  step's overshoot. That part is the relaxation, not the coupling; at 0.2 the arm goes at a third (0.94 to 0.99).
- **A limit reached just after the arm passes pi goes slightly deeper at the coarse step** (3.3 rad: 1,576 urad against
  1,438 to 1,493 at 1.6 ms; 284 against 279 to 281 at 0.32 ms). Not traced.
- Next, for issues 7 and 8: whether the relaxation XPBD needs for a joint's other constraints can be left out of the
  limit now that its correction no longer fights the anchor, the held arm's slow drift, and the same on a chain of two
  links before a registered study.
