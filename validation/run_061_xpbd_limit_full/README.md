# Run 061: XPBD's joint limit sized with the anchor held and applied in full (the joint-angle patch's fourth form)

Not registered: a trace. Its play script [`play.sh`](play.sh), its patch and the hypothesis and predictions below were
pushed before its plays. Newton 1.7.0 with
[`patches/in_design/xpbd_joint_angle_v4_on_1.7.0.diff`](../../patches/in_design/xpbd_joint_angle_v4_on_1.7.0.diff),
the 1.7.0 rebase of the third form (`patches/newton-1.7.0/xpbd_joint_angle_v3.diff`) with five lines changed:
switch `NEWTON_XPBD_JOINT_ANGLE_UNWRAP=4` is the third form with the limit's correction applied in full.

## The hypothesis

Run 051: sized with the joint's anchor held, the limit no longer throws the arm back, and with a full correction holds
it at every lever and angle, past pi too (21 of 22); at XPBD's default angular relaxation of 0.4 it still lets the arm
go at about a sixth of its speed, the limit's own projection (two iterations of 0.4 leaving 36% of each step's
overshoot). XPBD relaxes a joint's corrections because each is sized alone and summed; the coupled limit is sized with
the anchor's rows eliminated, so its correction does not fight the anchor, and relaxing it only leaves overshoot. The
fourth form applies the coupled limit's correction in full and leaves every other row's relaxation as it is. If that
is right, the limit holds the arm at the default relaxation, and at a relaxation of 1 the fourth form is the third.

**Disclosed before the plays:** a design probe on the host played run 051's arm on its 0.3 m lever at the default
relaxation under switches 3 and 4, at 2.5, 3.3 and 4.5 rad and both steps: switch 3 turned back at 0.42 to 0.56 rad/s
(as run 051 on 1.6.1); switch 4 ended within 40 mrad of each limit, slower than 0.073 rad/s (2.5 rad: 0.8 mrad and
0.0007 rad/s at 1.6 ms).

## What is played

Run 051's grid with switch 4: the arm (1.5 kg, 0.03 m) turning at 3 rad/s onto an upper limit L from L - 2.5 (lower
limit L - 3), its centre 0.3 m from the joint unless named, no gravity, 1.4 s, at 1.6 and 0.32 ms: the eight limits
(2.7 to 4.5 rad, three past pi) at relaxations 0.4 and 1, three of them at 0.2, the three levers (0.3, 0.1, 0 m) at 0.4
and 1 on a limit at 2.5 rad, and the free arm. Then run 032's straight chain of two links turning at 2 rad/s about
its first joint, that joint's limits -1 and 3.3 rad (past pi), at 2.5 and 0.625 ms, 2.5 s, as released and under
switches 3 and 4. Held: within 0.05 rad of the limit and slower than 0.1 rad/s at the end (run 051's).

## Predictions, before the plays

- **P1.** At relaxation 0.4, switch 4 holds the arm at all eight limits at both steps (16 of 16).
- **P2.** At relaxation 0.2, switch 4 holds it at the three limits played, both steps (6 of 6).
- **P3.** At relaxation 0.4, switch 4 holds all three levers, both steps (6 of 6).
- **P4.** At relaxation 1, switch 4's plays are run 051's switch 3 plays byte for byte (the eight limits and the
  three levers, both steps: 22 of 22), and the free arm is run 051's free arm (2 of 2).
- **P5.** The chain: switch 4 holds its first joint at the 3.3 rad limit at both steps (within 0.05 rad, slower than
  0.1 rad/s, at the end); as released the chain is thrown past pi (run 032); switch 3 not predicted.

## What was found

Played on the Newton host, 2026-10-19T14:09:30Z to 2026-10-19T14:12:42Z. Reading [`reading.txt`](reading.txt), byte
checks [`checks.txt`](checks.txt). No play stopped being a number.

| Prediction | Result |
|---|---|
| P1: at relaxation 0.4 the arm held at all eight limits, both steps | **Held**, 16 of 16: within 40 mrad of each limit and slower than 0.073 rad/s (the largest, 3.3 rad at 1.6 ms); at 0.32 ms within 8.8 mrad and 0.015 rad/s |
| P2: at relaxation 0.2, the three limits played, both steps | **Held**, 6 of 6 |
| P3: at relaxation 0.4, the three levers on a 2.5 rad limit, both steps | **Held**, 6 of 6 (within 0.8 mrad and 0.0007 rad/s) |
| P4: at relaxation 1 the fourth form is run 051's third form, byte for byte, and the free arm run 051's | **Held**, 24 of 24 |
| P5: the chain's first joint held at its 3.3 rad limit by switch 4 | **Failed**: it leaves the limit turning back at 3.63 rad/s at both steps (2.38 and 2.51 rad at the end), its second link spinning at 12.3 rad/s; switch 3 turns back at 1.75 and 2.44 rad/s; as released the chain is thrown (7e6 and 5e5 rad/s) |

- **The fourth form holds one arm at XPBD's default relaxation, at every lever and limit, past pi too**, where the third
  form lets it go at about a sixth of its speed: the limit's own relaxation was the remainder, and with the coupled
  sizing it can be dropped. At a relaxation of 1 it is the third form exactly.
- **It does not hold a chain.** The limit is sized with its own joint's anchor held, which for one body on a fixed
  joint is the body's inertia about the joint; on a chain the links past the first carry momentum the limit's
  correction does not see, and the second joint's anchor hands it back: the arm is turned back harder than with the
  relaxed correction. Holding a chain needs the limit sized with the inertia of everything it turns (the subtree past
  the joint), which XPBD's per-joint projection does not have. Issues 7 and 8 stay open for chains; the next form is a
  thesis, not a tweak of this one.

Every reading and check of this run was made again on the laptop, byte for byte, from its kept files, with a build of
[the measure](../../measure/README.md) (20 October 2026).

## A correction (21 October 2026)

P5's right answer was wrong. A chain whose first joint strikes a hard limit without a rebound is not held there: the
second link turns on, and the limit, which only pushes, holds the first joint only while the second link turns its
first half turn, then lets it go from rest ([run 105](../run_105_xpbd_limit_chain_reference/README.md)). That the fourth
form's chain leaves the limit is not itself the fault; how it leaves is measured against a converged reference there.
