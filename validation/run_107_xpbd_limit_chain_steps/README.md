# Run 107: XPBD's joint limit on a chain as the step shrinks, and on one arm (issue 8)

Not registered: a design probe, its predictions pushed with [`play.sh`](play.sh) before any play. Newton 1.7.0 with the
XPBD joint-angle patch's fourth form in design first on the path
([`xpbd_joint_angle_v4_on_1.7.0.diff`](../../patches/in_design/xpbd_joint_angle_v4_on_1.7.0.diff),
`NEWTON_XPBD_JOINT_ANGLE_UNWRAP=4`).

## Why

[Run 106](../run_106_xpbd_limit_chain_forms/README.md) found that at XPBD's default relaxations and 16 iterations or
more the fourth form holds the chain's first joint dead on its limit after the strike, as run 105's converged reference
does, and leaves it 0.05 rad short of the reference at 2.5 s at 0.625 ms. XPBD is first order in the step; here the
same at four steps, and run 061's single arm (issue 8's own scene, which the fourth form held at two iterations) at the
iteration counts the chain needs.

## Predictions (pushed before the plays)

| Check | Prediction |
|---|---|
| P1 | At 64 iterations the chain's first joint on its limit within 1 mrad at 2.0 s at 0.625, 0.156 and 0.039 ms |
| P2 | At 64 iterations and 0.039 ms the first joint within 0.02 rad of run 105's reference at 2.5 s |
| P3 | At 64 iterations the arm held at its limit at both steps: within 1 in 50 of 2.5 rad and slower than 0.1 rad/s at the end |

Reported: every reading, 16 iterations, the arm at 2 and 16.

## What it found

Played 20 October 2026 on the second x86-64 host (`started.txt`, `finished.txt`); the readings in `measured.txt`, the
checks in [`checks.txt`](checks.txt). **4 of 4 checks held.**

| First joint at 2.5 s, rad (rad/s); reference 2.793 (-3.22) | 2.5 ms | 0.625 ms | 0.156 ms | 0.039 ms |
|---|---|---|---|---|
| 16 iterations | 2.959 (-2.00) | 2.882 (-2.52) | 2.860 (-2.69) | 2.817 (-3.04) |
| 64 iterations | 2.958 (-2.01) | 2.847 (-2.78) | 2.817 (-3.03) | 2.812 (-3.05) |

- **P1 held**: at 64 iterations the first joint at 3.299999, 3.299999 and 3.299998 rad at 2.0 s at 0.625, 0.156 and
  0.039 ms, dead on its limit as the reference is.
- **P2 held**: at 64 iterations and 0.039 ms the first joint 0.019 rad from the reference at 2.5 s. Its distance from
  the reference falls as the step shrinks: 0.166, 0.054, 0.025 and 0.019 rad.
- **P3 held**: at 64 iterations the arm at 2.4996 and 2.4978 rad at the end, turning at under 0.005 rad/s; at 2 and 16
  iterations it is held too, as run 061 found at 2.
- With the fourth form and enough iterations for XPBD's solve to converge, the chain does what a hard limit does: the
  first joint stops dead, stays while the reaction pushes, and leaves as the reference leaves, nearer it as the step
  shrinks. At XPBD's default two iterations it rattles on the limit (run 105).
