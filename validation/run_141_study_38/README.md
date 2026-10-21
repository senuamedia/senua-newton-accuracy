# Run 141: Study 38, XPBD's joints solved colour by colour, at full relaxation, at two iteration counts (issue 12)

The thirty-eighth registered study ([`PREREGISTRATION_38.md`](../../preregistrations/PREREGISTRATION_38.md)), played once
with [`play.sh`](play.sh) on the engines made by [`setup_engine.sh`](setup_engine.sh): Newton 1.7.0 as released
(`stock`), and with Senua AI's XPBD joint colours ([`xpbd_joint_colours_on_1.7.0.diff`](../../patches/in_design/xpbd_joint_colours_on_1.7.0.diff)),
its switch unset (`off`) and set (`on`).

## What it found

Played 21 October 2026 (UTC) on the Newton host (`started.txt`, `finished.txt`); the measured lines in `measured.txt`,
the rules in [`rules.txt`](rules.txt). **12 of 12 rule lines held.**

The free chain's largest energy departure, ppm:

| | 1.6 ms | 0.8 ms | 0.4 ms | 0.2 ms | 0.1 ms |
|---|---|---|---|---|---|
| Stock at its defaults (2 iterations, relaxations 0.7 and 0.4) | 22,039 | 14,634 | 11,912 | 10,457 | 9,587 |
| On, full relaxation, 8 iterations | 21,486 | 11,052 | 5,014 | 1,784 | 552 |
| On, full relaxation, 32 iterations | 21,341 | 9,770 | 3,332 | 1,144 | 489 |

- R1 held: with the switch unset all 7 chain plays byte for byte stock's.
- R2 held: stock at full relaxation diverges at 8 and 32 iterations (its largest kinetic energy 0.47 J at the start
  against 64 and 694 J).
- R3 held: on, the departure falls at every halving of the step at 8 and at 32 iterations.
- R4 held: at 0.4, 0.2 and 0.1 ms on's departure at either count is at most half of stock's at its defaults; at 0.1 ms
  552 and 489 ppm against 9,587, where stock's barely falls as the step shrinks.
- R5 held: one arm with the switch set byte for byte stock's at both steps.
- R6 held: every play a number throughout.

Reported: momentum, on at 32 iterations, within 59 ppm at 0.1 ms; the chain swinging under gravity departs by 627,298,
204,771 and 59,756 ppm (stock) and 675,057, 184,438 and 46,882 ppm (on) at 1.6, 0.4 and 0.1 ms: the colours lower it at
the two finer steps but do not keep a swinging chain's energy.

## What it decides

**Issue 12's XPBD part is fixed for a free chain** by Senua AI's joint colours patch with XPBD's own relaxation options
at 1.0: the loss falls with the step at either iteration count, twenty times below the released solver's at 0.1 ms. The
patch is validated into [`patches/newton-1.7.0/xpbd_joint_colours.diff`](../../patches/newton-1.7.0/xpbd_joint_colours.diff)
(the same file as its registration names). A chain swinging under gravity still loses energy on XPBD (reported).
