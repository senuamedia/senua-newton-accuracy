# Run 031: the spinning body's drift, against the MuJoCo solver's integrator

15 October 2026, 09:28 to 09:30 UTC, on the Newton host, by [`play.sh`](play.sh), whose hypothesis and predictions
were pushed before the plays. Not registered: a trace. Newton 1.6.1 from PyPI for the MuJoCo solver; run 026's patched
source for VBD-ALM. Reading `reading.txt`, made with Senua AI's `sx_contact` (`creep`, `stop`), re-made byte for byte
on the laptop from the same files. In the logs the home folder is written `~/`.

## The question

In run 030 (F12) the MuJoCo solver moved the centre of mass of a body spinning about it off its origin, at a speed
proportional to the step, and VBD-ALM moved it more as the step shrank. The hypothesis: the MuJoCo solver's drift is
its integrator's first-order error. Newton's MuJoCo solver integrates with implicitfast by default; on the two-link
chain (run 014) MuJoCo's Euler was the same to the byte and its RK4 kept the energy to 5 ppm.

## What was played

Run 030's scene (a 1 kg cube spinning at 5 rad/s about a centre of mass 5 cm off its origin, no gravity, 2 s) on the
MuJoCo solver with `opt.integrator=rk4` and `=euler`, and on VBD-ALM with the carried velocity's second form (run 026)
and with no switch.

| The centre of mass's speed, um/s: mean over the second half, and the largest in the last third | 10 ms | 2.5 ms | 0.625 ms | 0.156 ms |
|---|---|---|---|---|
| The MuJoCo solver, implicitfast (run 030) | 5,754 and 12,498 | 1,431 and 3,117 | 336 and 734 | |
| The MuJoCo solver, Euler (the same files as implicitfast) | 5,754 and 12,498 | 1,431 and 3,117 | 336 and 734 | |
| **The MuJoCo solver, RK4** | **-1 and 3** | **-6 and 12** | **-19 and 45** | |
| VBD-ALM as released | | | -201 and 352 | **-4,562 and 7,129** |
| VBD-ALM with the carried velocity, second form | | | 56 and 95 | 656 and 787 |

| Prediction | Result |
|---|---|
| P1: with RK4 the largest speed is at most a hundredth of implicitfast's at each step (125, 31 and 7 um/s) | Held at 10 and 2.5 ms (3 and 12); **failed** at 0.625 ms (45) |
| P2: with Euler it reads as with implicitfast within 1 in 100 | Held: the same files, byte for byte |
| Check: VBD-ALM with no switch at 0.625 ms is run 030's file | Held |

No play stopped being a number.

## What it shows

- **The MuJoCo solver's drift is its integrator's first-order error.** Euler and implicitfast give the same plays; RK4
  takes the drift from 12.5 mm/s to 3 um/s at 10 ms. What RK4 leaves grows as the step shrinks (3, 12 and 45 um/s),
  the way rounding builds up over more steps in 32-bit arithmetic, not as an integrator's error does: the prediction's
  bound at 0.625 ms did not allow for it.
- **VBD-ALM's drift grows fast as the step shrinks** (7.1 mm/s at 0.156 ms, 20 times its 0.625 ms value). Carrying
  its velocity cuts it by 4 to 9 times but does not stop it; its cause is not traced.
