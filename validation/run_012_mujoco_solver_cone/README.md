# Run 012: the MuJoCo solver's low-friction fault, traced to the pyramid

15 October 2026. Not registered: a design probe, by [`probe.sh`](probe.sh) (its prediction written into it and pushed
before the plays); reading `reading.txt`. Run 011 found Newton's MuJoCo solver stopping being a number at the first
contact of a shape with a friction of 0.001 or less. **Prediction**: the default friction cone is a pyramid whose
opposite edges are n + mu t and n - mu t; at a friction of 0.001 they differ in the third decimal place of a 32-bit
number, so the constraint's matrix is nearly singular in MuJoCo Warp's 32-bit arithmetic; if so, the elliptic cone,
which has no near-parallel edges, plays where the pyramid fails. The rig now passes a word as a solver option
(`opt.cone=elliptic`). Run 011's drop (2 kg, half-size 0.04 m, from 80 mm, 0.5 s) at 2.5 ms and 0.156 ms.

| Friction | Pyramidal cone (the default) | Elliptic cone |
|---|---|---|
| 0 | stops being a number at the first contact | **plays** |
| 1e-5 | stops being a number | **plays** |
| 1e-4 | stops being a number | **plays** |
| 1e-3 | stops being a number | **plays** |
| 0.01 | plays | plays |

The same at both steps. MuJoCo Warp warns only for a friction under 1e-5 ("may cause NaN"), on either cone.

**Check on the rig:** the pyramidal cone given explicitly at a friction of 0.01 is byte-identical to run 011's play
without it, at both steps.

## What it shows

**The prediction holds.** The MuJoCo solver's fault at low friction comes from the default pyramidal cone: with the
elliptic cone it plays every friction, 0 included. A user who needs a slippery contact on Newton's MuJoCo solver can
set `cone="elliptic"` today; the pyramid's failure is silent above 1e-5. MuJoCo's C engine, in 64-bit arithmetic,
plays the pyramid at every friction (the MuJoCo deep dive).

Added 15 October 2026, after [run 023](../run_023_mujoco_solver_regularization/README.md): the cause named above, the
pyramid's near-parallel edges, is corrected there. Within the pyramid the fault follows its regularization, which
MuJoCo Warp makes proportional to mu^2 / impratio: a friction of 0.1 (edges 0.2 rad apart) fails with impratio
10,000, and 1e-4 plays with impratio 1e-4. The finding of this run, that the elliptic cone plays every friction,
stands.
