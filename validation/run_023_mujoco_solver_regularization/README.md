# Run 023: the MuJoCo solver's low-friction fault, against the pyramid's regularization

15 October 2026, on the Newton host, by [`play.sh`](play.sh), whose hypothesis and predictions were pushed before
the plays. Not registered: a trace. Newton 1.6.1 from PyPI. Reading `reading.txt`, the rig's own statistics lines
(`nan_at_step`, as in runs 011 and 012) and byte comparisons, re-made byte for byte on the laptop from the kept files.

## The question

Newton's MuJoCo solver stops being a number at a cube's first contact when its friction is 0.001 or less (F3, run
011), and the elliptic cone plays every friction (run 012). Run 012 named the pyramid's near-parallel edges,
n + mu t and n - mu t, as the cause. Read since in MuJoCo Warp (`constraint.py`, the contact rows and `_efc_row`):
each pyramid edge's regularization is R = 2 mu^2 (1 + mu^2) invweight / impratio x (1 - imp) / imp, and the solver
weighs the row by D = 1 / R. D grows as 1 / mu^2: about 1e7 for this cube at a friction of 0.001, 1e5 at 0.01. The
elliptic cone's friction rows have R = invweight / impratio x (1 - imp) / imp, with no mu^2. Is the cause the size of
the regularization, which impratio scales without touching the edges, or the edges' angle?

## What was played

Run 011's drop (2 kg, half-size 0.04 m, from 80 mm, 0.5 s) at 2.5 ms and 0.156 ms, on the MuJoCo solver, every option
at its default but the cone, impratio and, once, the solver.

| Cone, friction, impratio | mu^2 / impratio | Edges' angle, rad | 2.5 ms | 0.156 ms | Prediction |
|---|---|---|---|---|---|
| Pyramid, 0.001, 1 (run 012's) | 1e-6 | 0.002 | stops at step 51 | stops at step 818 | P5: run 012's files, byte for byte: held |
| Pyramid, 0.01, 1 (run 012's) | 1e-4 | 0.02 | plays | plays | P5: held |
| Pyramid, 0.001, 0.01 | 1e-4 | 0.002 | **plays** | **plays** | P1: plays. Held |
| Pyramid, 1e-4, 1e-4 | 1e-4 | 0.0002 | **plays** | **plays** | P2: plays. Held |
| Pyramid, 0.01, 100 | 1e-6 | 0.02 | **stops at step 51** | **stops at step 818** | P3: stops. Held |
| Pyramid, 0.1, 10,000 | 1e-6 | 0.2 | **stops at step 53** | **stops at step 818** | P3: stops. Held |
| Elliptic, 0.01, 1e6 | | | plays | plays | P4: stops. **Failed** |
| Pyramid, 0.001, 1, MuJoCo's CG solver | 1e-6 | 0.002 | plays | plays | Reported, not predicted |

Each stop is the cube's first contact with the ground (step 51 at 2.5 ms and 818 at 0.156 ms are 0.128 s, the fall
from 80 mm).

## What it shows

- **The pyramid's fault follows its regularization, mu^2 / impratio, not the angle between its edges.** At a friction
  of 0.1, edges 0.2 rad apart, the pyramid fails when impratio is 10,000; at 1e-4, edges 0.0002 rad apart, it plays
  when impratio is 1e-4. At the same mu^2 / impratio it fails at the same contact step whatever the friction. Run
  012's named cause, the near-parallel edges, is corrected: it is the size of the edges' D = 1 / R.
- **It is not the size of D alone.** The elliptic cone plays with its friction rows' D as large as the failing
  pyramid's (P4 failed). The account the data fit, not traced in the solver: each pyramid edge carries the normal
  (n + mu t and n - mu t), so the edges' D stiffens the normal direction itself, about impratio / mu^2 times the
  elliptic cone's normal row; on the elliptic cone the large D lies along the friction rows only.
- **The fault is in MuJoCo Warp's default solver.** Its CG solver plays the pyramid at a friction of 0.001 at both
  steps; its Newton solver, the default, does not.
- **What plays a slippery contact on Newton's MuJoCo solver:** the elliptic cone (run 012), the CG solver, or an
  impratio scaled with mu^2. The last two change other things (impratio sets friction's own softness, and the solver
  its convergence) and were not held to anything else here.
