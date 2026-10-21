# Run 027: XPBD's creep at rest, against its iterations

15 October 2026, 08:52 to 08:54 UTC, on the Newton host, by [`play.sh`](play.sh), whose hypothesis and predictions
were pushed before the plays. Not registered: a trace. Newton 1.6.1 from PyPI. Reading `reading.txt`, made with Senua
AI's `sx_contact` (`creep`), re-made byte for byte on the laptop from the same files.

## The question

XPBD's hold creeps in proportion to the step (F4; run 001: 10.9 mm/s at 2 ms to 0.17 mm/s at 0.031 ms, a 1 kg cube
pushed at 0.6 of the friction limit). In the source (`xpbd/kernels.py`), each iteration a contact's friction undoes the
slip its points have made since the step began, scaled by `rigid_contact_relaxation` (0.8), and the four corners'
corrections are averaged; XPBD makes 2 iterations by default and reads its velocity back from the poses. A cube's
friction acts a half-size below its centre, so only 40% of a corner's correction moves the centre. The hypothesis: the
creep is the step's solve left unconverged, what is left of the slip becoming the next step's speed.

## What was played

Run 001's hold (1 kg, half-size 0.05 m, friction 0.5, 2.94 N from 0.5 s, 2 s) on XPBD at 2 ms and 0.5 ms, at 2 to 32
iterations, with a relaxation of 1, and on a plate that cannot tip (half-height 0.005 m).

| XPBD's hold, mean speed, um/s (right answer 0) | 2 ms | 0.5 ms |
|---|---|---|
| Cube, 2 iterations (the default; run 001's files byte for byte) | 10,862 | 2,715 |
| 4 iterations | 4,951 | 1,237 |
| 8 iterations | 2,507 | 626 |
| 16 iterations | 1,581 | 393 |
| 32 iterations | **1,531** | **380** |
| Cube, 2 iterations, `rigid_contact_relaxation` 1 | 8,174 | 2,043 |
| Plate that cannot tip, 2 iterations | 5,176 | 1,296 |

| Prediction | Result |
|---|---|
| P1: the creep falls at every doubling of iterations, and at 32 it is under a tenth of its value at 2 | Falls at every doubling: held. **Under a tenth: failed**, 1,531 against 10,862 (14%) |
| P2: on the plate the creep is under the cube's | Held (5,176 against 10,862) |
| P3: with a relaxation of 1 the cube's creep is under its creep at 0.8 | Held (8,174) |

No play stopped being a number; the cube's largest turn reads 0 in every play.

## What it shows

- **Most of XPBD's creep at rest is its solve left unconverged within the step.** Going from 2 iterations to 32 takes
  it from 10.9 mm/s to 1.5 mm/s at 2 ms, and from 2.7 mm/s to 0.38 mm/s at 0.5 ms; undoing the whole slip each
  iteration (a relaxation of 1) and a body that cannot tip both lower it too.
- **A floor remains, proportional to the step:** 1,531 um/s at 2 ms and 380 um/s at 0.5 ms (a ratio of 4.03 for a step
  4 times smaller), about a quarter of the push's speed gain a step, (F / m) h. Iterations do not remove it, so it is
  not the solve's convergence; its cause is not traced here.
- For a user: XPBD holds a load far better with more iterations (a seventh of the creep at 16 or 32), at their cost,
  but it does not hold it still at any count played.
