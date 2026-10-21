# Run 112: a light cloth coupled to a rigid box through SolverCoupledProxy (issue 21, #4698)

Not registered: a design probe, its predictions pushed with [`play.sh`](play.sh) before any play. Newton 1.7.0 from
PyPI as released, by a rig new at this run, [`tools/nwt_cloth_proxy.py`](../../tools/nwt_cloth_proxy.py).

## Why

Issue 21 (N13) brings the record's first deformable: newton-physics/newton #4698 reports that a 45 g VBD cloth resting
on a box coupled to the MuJoCo solver through `SolverCoupledProxy` feeds the box about 49 N, 110 times its weight
(VBD's explicit harvest reads the contact penalty of an unconverged iterate), and that the generic lagged-feedback
rewind, applied to VBD's harvest, which is not cumulative, turns the feedback into a divergent loop (on 1.6.1, the box
driven through the ground at 80 m/s). The rig plays #4698's scene: a 0.5 kg box, 0.2 x 0.2 x 0.05 m, on the ground on
the MuJoCo solver's CPU path with its own contacts, a 0.3 m square cloth of 21 x 21 vertices, 45 g, dropped from 5 cm,
VBD at `rigid_compliant_alm=True`, two 2 ms substeps on each side of a 4 ms coupled step, the proxy's collision pipeline
`nxn` with a soft contact gap of 0.01, soft contact stiffness 1e4, damping 0, friction 0.5. A one-method subclass of
`SolverVBD` records the wrench it harvests for the box; the force the cloth receives is its momentum change over the
step plus its weight.

## Predictions (pushed before the plays)

| Check | Prediction |
|---|---|
| P1 | One-way, the cloth at rest receives its weight, 441 mN, within 1 in 20, at every iteration count |
| P2 | One-way at 10 iterations, the wrench harvested for the box at rest at least ten times that, 4,410 mN or more |
| P3 | The harvested wrench falls as the iterations grow (#4698: 48.6, 14.0 and 3.8 N at 10, 40 and 100) |

Reported: the two-way plays, the box's largest speed (the physical bound 2 M_cloth v_land / M_box, 0.18 m/s).

## What it found

Played 20 October 2026 on the second x86-64 host (`started.txt`, `finished.txt`); the measured lines in
`measured.txt`, the checks in [`checks.txt`](checks.txt). **3 of 3 checks held.**

| Check | Result |
|---|---|
| P1 | Held: one-way, the cloth at rest receives 441, 442 and 440 mN at 10, 40 and 100 iterations, its weight |
| P2 | Held: one-way at 10 iterations the harvested wrench is 74,077 mN, 168 times the force the cloth exerts |
| P3 | Held: it falls as the iterations grow, 74.1, 18.3 and 5.6 N |

Over the last third of the play (the cloth at rest on the box from about step 25, 0.1 s):

| | 10 | 40 | 100 iterations |
|---|---|---|---|
| Force the cloth receives, one-way | 441 | 442 | 440 mN |
| Wrench harvested for the box, one-way (z) | -74,077 | -18,300 | -5,593 mN |
| The same, two-way | -45,996 | -17,060 | -3,223 mN |
| The box's speed, one-way | 0 | 0 | 0 um/s |
| The box's speed, two-way (mean; largest after the landing) | 2,885 (47,202) | 607 (5,210) | 9 (1,103) um/s |
| The box pressed into the ground, two-way (below its one-way rest) | 128 to 228 | 65 to 77 | 13 to 14 um |

- **#4698's fault is there on 1.7.0**: the wrench VBD harvests for the box is the contact penalty of its last iterate,
  not the force the cloth exerts, 168, 41 and 13 times the cloth's weight at 10, 40 and 100 iterations (#4698, on
  1.6.1: 110, 32 and 9 times), while the cloth itself, in the same steps, receives its weight to 1 in 400. The
  harvest's error falls as the iterate converges and is still 13 times too large at 100 iterations.
- **Fed back, it presses the box into the ground and shakes it**: two-way, the box sinks under a force up to 300 N
  (step 30 at 10 iterations), 0.2 mm below its rest, and moves at 2.9 mm/s on average, up to 47 mm/s, where one-way it
  rests still. It does not diverge in 0.6 s on 1.7.0: #4698's divergence (the box through the ground at 80 m/s) was on
  1.6.1 with the generic rewind, and was not reached here.
- Every play's first steps are the box settling onto the MuJoCo solver's ground (15.9 mm/s at step 0, still by step
  20), before the cloth lands; the column `box_top_speed_ums` in `measured.txt` is that settle, not the cloth.
- The right harvest is the force the cloth receives, momentum for momentum: what VBD's step gave the cloth's momentum
  less its weight, over the step, shared among the bodies it touches. That is the design question for issue 21's fix.
