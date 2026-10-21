# Run 044: the floor of XPBD's creep at rest, against its friction limit

15 October 2026, 11:00 to 11:03 UTC, on the Newton host, by [`play.sh`](play.sh), whose hypothesis and predictions
were pushed before the plays. Not registered: a trace. Newton 1.6.1 from PyPI. Reading `reading.txt`, made with Senua
AI's `sx_contact` (`creep`), re-made byte for byte on the laptop from the same files.

## The question

Run 027 found most of XPBD's creep at rest is its solve left unconverged, but a floor proportional to the step
remains at 16 and 32 iterations: 1,531 um/s at 2 ms and 380 um/s at 0.5 ms on run 001's hold, a quarter of the push's
speed gain a step. Read in the source (`xpbd/kernels.py`, `solve_body_contact_positions`): each iteration a corner's
friction correction is limited by mu times that same iteration's normal correction at that corner (`lambda_fr =
max(lambda_fr, -lambda_n * mu)`, commented "limit friction based on incremental normal force, good approximation to
limiting on total force"). At rest the normal corrections of a step add up only to that step's sink, g h^2, and they
shrink from iteration to iteration as the penetration is undone. The hypothesis: the floor is that limit, the
friction running out of normal correction before the slip is undone.

## What was played

Run 001's hold (1 kg, half-size 0.05 m, a push along x from 0.5 s, 2 s) on XPBD at 32 iterations unless stated.

| XPBD's hold, mean speed, um/s (right answer 0) | 2 ms | 0.5 ms |
|---|---|---|
| Friction 0.5, push 2.94 N (0.6 of the limit; run 027's files byte for byte) | 1,531 | 380 |
| The same at 64 iterations | 1,531 | |
| Friction 1, the same push (0.3 of the limit) | 0 | |
| Friction 5, the same push (0.06 of the limit) | **0** | **0** |
| Friction 0.5, push halved to 1.47 N (0.3 of the limit) | **401** | 0 |
| A plate that cannot tip (half-height 0.005 m), friction 0.5, push 2.94 N | 0 | |
| `rigid_contact_relaxation` 0.5 | 1,457 | |
| `rigid_contact_relaxation` 1 | 1,592 | |

At 0.125 ms, friction 0.5 and the full push, the hold reads 0.

| Prediction | Result |
|---|---|
| P1: with friction 5, under a tenth of the floor: under 153 um/s at 2 ms and 38 um/s at 0.5 ms | Held: 0 at both |
| P2: with the push halved, under half the floor: under 765 um/s at 2 ms and 190 um/s at 0.5 ms | Held: 401 and 0 |
| P3: at 64 iterations, within 5 in 100 of 1,531 um/s | Held: 1,531 (the files differ, the reading is the same) |
| Check: friction 0.5 at 32 iterations, run 027's files | Held at both steps |

No play stopped being a number; the cube's largest turn reads 0 in every play.

## What it shows

- **XPBD's creep floor is its friction limit.** With the limit made ten or two times wider at the same push (friction
  5 or 1), the cube holds still; halving the push takes the floor to a quarter, not a half, as a limit that binds
  does; more iterations change nothing (converged). A plate that cannot tip, whose friction moves its centre rather
  than turning it, holds at 32 iterations (it crept at 2, run 027). Traced: each iteration's friction is limited by
  that iteration's normal correction, not by the normal force the contact carries, so at rest, where the normal
  corrections of a step are only its sink, a load well inside Coulomb's limit (0.6 of it) is not held.
- **It is not the load's share of the limit alone.** At 0.3 of the limit the cube holds with friction 1 and the full
  push but creeps 401 um/s with friction 0.5 and half the push; the turn the friction gives the cube, undone by the
  normal correction, is the likely reason, not traced here.
- **A zero near 0.1 mm/s is XPBD's own floor, not a hold.** Read in the source (`apply_body_deltas`): after every
  correction XPBD sets a body's speed to zero when it is under 1e-4 m/s ("this improves gradient stability"), and its
  turning speed when under 1e-4 rad/s. The floor proportional to the step predicts about 95 um/s at 0.125 ms and
  about 100 um/s for the half push at 0.5 ms; both read 0. The zeros of P1 are not that: at 2 ms the floor would be
  15 times above it.
- A correction grounded in the method XPBD comes from (Mueller et al., Detailed rigid body simulation with extended
  position based dynamics, 2020: static friction holds while the tangential multiplier is under mu times the normal
  one, there the step's whole normal multiplier) would limit each contact's friction by its normal correction
  accumulated over the step's iterations. Not attempted here.
