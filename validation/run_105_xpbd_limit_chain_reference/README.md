# Run 105: the right answer for a chain struck against a hard joint limit, and XPBD against it (issue 8)

Not registered: a design probe, its predictions pushed with [`play.sh`](play.sh) before any play. Newton 1.7.0 from
PyPI as released, the same with the XPBD joint-angle patch's fourth form in design first on the path
([`xpbd_joint_angle_v4_on_1.7.0.diff`](../../patches/in_design/xpbd_joint_angle_v4_on_1.7.0.diff),
`NEWTON_XPBD_JOINT_ANGLE_UNWRAP=4`), and MuJoCo 3.15's own C engine through its Python API, by a rig new at this run,
[`tools/mjc_limit_chain.py`](../../tools/mjc_limit_chain.py).

## Why

Run 061 predicted that the fourth form would hold run 061's chain, two links turning about the first joint, at that
joint's limit, and run 081 found it leaving the limit at any iteration count. The prediction assumed the wrong right
answer. A hard limit struck without a rebound stops the first joint; the second link, on a free hinge, keeps its
generalized momentum and turns on at H21 w / H22 = 6.87 rad/s (for these links, H22 the second link's inertia about its
joint, 0.02464 kg m^2, and H21 that plus m2 l1 lc2, 0.08464, at the straight chain), and the limit must then push the
first joint with the torque m2 l1 lc2 sin(q2) q2'^2. A limit only pushes: the joint stays on it while the second link
turns its first half turn, about 0.46 s, then leaves it from rest. What it does after that has no closed form here;
MuJoCo's limit, a constraint of set time constant, critically damped, converges on that hard limit as its time constant
shrinks with the step.

## What is played

Run 061's chain (1.2 and 0.6 kg links, half-size 0.04 m, centres 0.25 and 0.2 m from their joints, the joints 0.5 m
apart, turning at 2 rad/s about the first, its limits -1 and 3.3 rad, no gravity, 2.5 s): on MuJoCo with solreflimit
time constants 2, 0.5 and 0.2 ms, dampratio 1, the step a twentieth of the time constant, RK4, solimplimit 0.99 0.999
(each file keeping the state every 0.1 ms); on XPBD as released and with the fourth form at 2.5, 0.625 and 0.156 ms at
Newton's defaults. Read at 1.7, 1.8, 2.0, 2.1, 2.2, 2.3 and 2.5 s.

## Predictions (pushed before the plays)

| Check | Prediction |
|---|---|
| P1 | The reference converges: at 2.5 s the first joint's angle at the two stiffest limits within 0.01 rad, its speed within 1 in 100 |
| P2 | The reference holds the first joint on its limit, within 1 mrad of 3.3 rad, at 1.8, 2.0 and 2.1 s |
| P3 | Its second link turns at the closed form's 6.87 rad/s after the strike, within 1 in 100, at 2.0 s |
| P4 | The fourth form at 0.156 ms within 0.05 rad of the reference's first joint at 2.5 s |

Reported: every reading at every instant, XPBD as released.

## What it found

Played 20 October 2026 on the second x86-64 host (`started.txt`, `finished.txt`); the readings in `measured.txt`, the
checks in [`checks.txt`](checks.txt). **4 of 5 checks held.**

| Check | Result |
|---|---|
| P1 | Held: at 2.5 s the first joint at 2.792553 and 2.792462 rad at the two stiffest limits, turning back at 3.219 and 3.220 rad/s |
| P2 | Held: the first joint at 3.300000 rad, speed 0, at 1.8, 2.0 and 2.1 s |
| P3 | Held: the second link at 6.833 rad/s after the strike, 0.54% under the closed form's 6.87 |
| P4 | **Failed**: the fourth form's first joint at 2.373 rad at 2.5 s (0.156 ms), 0.42 rad from the reference |

| First joint, rad (rad/s) | 1.8 s | 2.0 s | 2.1 s | 2.2 s | 2.5 s |
|---|---|---|---|---|---|
| Reference (0.2 ms limit) | 3.300 (0) | 3.300 (0) | 3.300 (0) | 3.279 (-0.58) | 2.793 (-3.22) |
| Fourth form, 2.5 ms | 3.267 (0.54) | 3.190 (0.20) | 3.299 (1.19) | 3.213 (-1.23) | 2.513 (-3.63) |
| Fourth form, 0.156 ms | 3.271 (0.73) | 3.227 (1.05) | 3.247 (-1.10) | 3.118 (-1.49) | 2.373 (-3.91) |

- **The right answer, converged**: struck against a hard limit without a rebound, the first joint stops dead at 3.3
  rad and stays there, the second link turning on at a steady 6.83 rad/s, until about 2.1 s, half a turn of the second
  link after the strike; then it leaves the limit from rest and is at 2.79 rad, turning back at 3.22 rad/s, at 2.5 s.
  The two stiffest limits agree to 0.1 mrad and 0.02%. A chain leaving its limit is the physics, not the fault.
- **XPBD with the fourth form rattles on the limit instead**: after the strike its first joint bounces between 3.19
  and 3.30 rad at about 1 rad/s and its second link's speed swings between 5.3 and 8.9 rad/s; it leaves the limit
  sooner and faster than it should. The error is the same at 2.5 and 0.156 ms: not the step but how the limit is
  sized on a chain. As released XPBD throws the chain (its gain toward pi, F14).
- XPBD reads the second joint through `newton.eval_ik`, which wraps it: its -6.04 rad at 2.5 s is 0.24 rad, against
  the reference's 5.84 (-0.44), 0.68 rad apart.
- The reference files keep the state every 0.1 ms (`every=` in the rig), so `sx_contact chain` is not used on them.
