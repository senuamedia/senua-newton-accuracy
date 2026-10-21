# Run 123: MuJoCo's noslip solver on MuJoCo Warp (issue 15)

Not registered: a design probe, its predictions pushed with [`play.sh`](play.sh) before any play. Newton 1.7.0 from PyPI
as released, and the same with the record's validated Newton noslip patch
([`mujoco_noslip.diff`](../../patches/newton-1.7.0/mujoco_noslip.diff), Study 11) and Senua AI's MuJoCo Warp noslip
patch in design ([`mujoco_warp_noslip_on_3.15.0.diff`](../../patches/in_design/mujoco_warp_noslip_on_3.15.0.diff)),
first on the path, made by [`setup_engine.sh`](setup_engine.sh).

## The patch

Issue 15: MuJoCo's recommended configuration for a load held by friction, its elliptic cone with the noslip solver,
cannot be set on the MuJoCo solver's Warp path: MuJoCo Warp 3.15 refuses `noslip_iterations` above 0 ("noslip solver
not implemented"), and its maintainers closed the request as not planned. Study 11 fixed it on the CPU path, where
MuJoCo's C engine runs the noslip solver. The patch ports MuJoCo's noslip solver (`solNoSlip` in engine_solver.c, with
its helpers and `mju_QCQP2`, `mju_QCQP3`, `mju_QCQP`) into MuJoCo Warp as a module run after the main solve, per world:
a projected Gauss-Seidel over the forces in friction dimensions (dry friction rows; each pyramidal contact's opposing
edges; each elliptic contact's friction block, its normal force held), on J M^-1 J' without the constraint
regularization, the residual J qacc - aref; then MuJoCo's finish (`dualFinish`: qfrc_constraint = J' f, qacc =
qacc_smooth + M^-1 qfrc_constraint) and M qacc, which MuJoCo Warp's implicit integrators read. M^-1 J' is made with
MuJoCo Warp's own mass solve. MuJoCo's `noslip_iterations` and `noslip_tolerance` are carried into MuJoCo Warp's
options; with MuJoCo's default 0 nothing of the patch runs. It refuses noslip with the discrete integrator or sleeping,
which it does not reach. On the host, checks of the code before this probe: a cube held below its friction limit, its
creep 765 um/s on the Warp path without noslip, held at 0 um/s with it, its play within 4 nm, 1 um/s and 1 mN of the
CPU path's at every step.

## What is played

Study 11's hold (a 1.5 kg cube pushed at 6.174 N, 70% of its friction's limit), slide (sent at 0.8 m/s) and drop (a
0.8 kg cube from 5 cm) on the MuJoCo solver at 1 and 4 ms: on the Warp path as released and with the patched tree,
noslip unset (elliptic cone); and with noslip at 5 iterations on the Warp path and on the CPU path, elliptic and
pyramidal. Read by Senua AI's `sx_contact` (`creep`, `stop`, `rest`).

## Predictions (pushed before the plays)

| Check | Prediction |
|---|---|
| C0 | Every play a number |
| P1 | With noslip unset, the patched tree's Warp path plays every scene byte for byte the release's |
| P2 | As released the Warp path's hold creeps at 100 um/s or more at both steps |
| P3 | With noslip the Warp path's hold within 10 um/s of still at both steps (elliptic) |
| P4 | With noslip the Warp path as the CPU path, at both steps (elliptic): the hold's speed within 10 um/s, the slide's distance and the weight within 1 in 100 |

Reported: the pyramidal cone's plays.

## What it found

Played 20 October 2026 on the second x86-64 host (`started.txt`, `finished.txt`); the measured lines in `measured.txt`,
the checks in [`checks.txt`](checks.txt). **10 of 10 checks held.**

| Check | Result |
|---|---|
| C0 | Held: every play a number |
| P1 | Held: with noslip unset the patched tree plays all 6 Warp-path plays byte for byte the release's |
| P2 | Held: as released the Warp path's hold creeps at 1,241 um/s at 1 and at 4 ms |
| P3 | Held: with noslip the Warp path's hold at 0 um/s at both steps (elliptic) |
| P4 | Held, 6 lines: the Warp path as the CPU path at both steps: the hold 0 and 0 um/s, the slide 54,488 and 53,077 um each the CPU path's to the micrometre, the weight 7,840 mN each |

| With noslip | Warp path | CPU path (MuJoCo's C engine) |
|---|---|---|
| Hold, elliptic, 1 / 4 ms | 0 / 0 um/s | 0 / 0 um/s |
| Slide, elliptic | 54,488 / 53,077 um | 54,488 / 53,077 um |
| Weight, elliptic | 7,840 / 7,840 mN | 7,840 / 7,840 mN |
| Hold, pyramidal | 2,320 / 2,320 um/s | 2,320 / 2,320 um/s |
| Slide, pyramidal | 54,531 / 53,260 um | 54,532 / 53,260 um |

- **The noslip solver runs on MuJoCo Warp and gives MuJoCo's C engine's plays**: with MuJoCo's recommended elliptic
  cone the held cube is still on the Warp path, where as released it creeps at 1.2 mm/s, and every reading is the CPU
  path's; with the patch and noslip unset the Warp path is the release's byte for byte.
- With the pyramidal cone the noslip solver does not hold the cube on either path, 2.3 mm/s on both: MuJoCo's own
  behaviour with that cone, which the port keeps, and the reason MuJoCo recommends the elliptic cone with noslip.
