# Twentieth pre-registration: XPBD's joint limit holds an arm and stops a chain as a hard limit does

Registered 21 October 2026, after the design probes of runs 048, 050, 051, 061, 081, 105, 106 and 107. Registered
before any play of this registration existed. To be played once, as run 109, on Newton 1.7.0.

## The question

Issue 8, F14: XPBD's joint limit throws an arm back. Its limit's correction is sized with the arm's inertia about its
own centre and the joint's anchor constraint turns it back into the arm's turn, and its gain grows without bound
toward pi; Senua AI's joint-angle patch in its fourth form reads the angle past pi, gives the swing its exact gradient
and sizes the limit with the anchor held, applied in full (runs 048 to 061). It held one arm at every lever and limit
(run 061). On a chain, the right answer is not that the joint stays: struck against a hard limit without a rebound, the
first joint stops dead, the second link turns on at H21 w / H22, and the limit, which only pushes, keeps the first
joint until the second has turned half a turn, then lets it go; MuJoCo's own engine with an ever stiffer, critically
damped limit converges on that (run 105). With the fourth form and 64 iterations XPBD held a chain's first joint dead
on its limit and converged on the reference as the step shrank (runs 106, 107). On arms and a chain no probe used: is
the fault there as released, and is the right answer given with the patch?

## The right answers

- One arm on a fixed joint, nothing else acting, struck against a hard limit without a rebound, stops and stays.
- A chain struck so: the first joint stops dead and stays while the limit's reaction pushes, the second link turning
  on at H21 w / H22 (H22 its inertia about its joint, H21 that plus m2 l1 lc2 at the straight chain); then the first
  joint leaves from rest. After that, the converged reference.

## Engines and rigs

Newton 1.7.0 from PyPI (`newton==1.7.0`, Warp 1.18.0, MuJoCo Warp 3.15.0) as released, Study 7's environment, and one
engine made from it by this run's `setup_engine.sh`: the base environment's Newton with Senua AI's XPBD joint-angle
patch applied (no fuzz), first on the path
([`xpbd_joint_angle_v4_on_1.7.0.diff`](../patches/in_design/xpbd_joint_angle_v4_on_1.7.0.diff)); **on** sets
`NEWTON_XPBD_JOINT_ANGLE_UNWRAP=4` and plays at 64 iterations, XPBD's relaxations its defaults; **off** is the same
engine with no switch set. The reference: MuJoCo 3.15's own C engine through its Python API. Rigs as
committed at this registration: `tools/nwt_joint.py`, `tools/nwt_chain.py`, `tools/mjc_limit_chain.py`. Warp's CPU
device. Measured by Senua AI's `sx_contact` (`final`), the chains read at fixed instants from their files, and judged by
its `rule`.

## The scenes, registered parameters

None of these numbers was used in the probes. XPBD in every play but the reference.

- **A, two arms** (8, F14): A1, 1.2 kg, half-size 0.035 m, its centre 0.25 m from the joint, turning at 2.5 rad/s from
  0 onto an upper limit at 2.2 rad (lower -0.6), no gravity, 1.6 s; A2, 0.8 kg, half-size 0.025 m, its centre 0.15 m
  out, turning at 3.5 rad/s from 0.4 rad onto an upper limit at 2.9 rad (lower -0.6), no gravity, 1.6 s; at 2 and 0.4
  ms; as released (at XPBD's default iterations), off and on.
- **C, a chain** (8): links of 0.9 and 0.5 kg, half-size 0.035 m, the first's centre 0.2 m from its joint, the second
  joint 0.42 m out, the second's centre 0.18 m beyond it, straight, turning at 1.6 rad/s about the first joint, its
  limits -1 and 2.4 rad, no gravity, 2.6 s; XPBD at 2.5, 0.625 and 0.156 ms as released, off and on; the reference on
  MuJoCo with solreflimit time constants 0.5 and 0.2 ms, dampratio 1, the step a twentieth of the time constant, RK4,
  solimplimit 0.99 0.999. By the closed form the first joint strikes at 1.5 s, the second link turns on at 5.24 rad/s,
  and the first joint stays on its limit until about 2.1 s.

## The rules

Each judged by `sx_contact rule`, from the measured lines, and nowhere else.

| Rule | Statement | Kind |
|---|---|---|
| R1 safe when off | Off, every A and C play byte for byte the release's | eq (count) |
| R2 the fault is there | As released each arm turns back at 0.5 rad/s or more at the end, at both steps | all_le |
| R3 the arms held | On, each arm within 0.05 rad of its limit and slower than 0.1 rad/s at the end, at both steps | all_within, all_in |
| R4 the reference converged | At 2.6 s the reference's first joint within 0.005 rad between the two time constants | near |
| R5 the reference stops the chain | The reference's first joint within 1 mrad of 2.4 rad at 1.7 and 1.9 s, its second link at 1.9 s within 1 in 100 of 5.24 rad/s | all_in, within |
| R6 the fault is there on the chain | As released the first joint 0.01 rad or more from its limit at 1.9 s at every step, or not a number | all_ge |
| R7 on the limit | On, the first joint within 1 mrad of 2.4 rad at 1.7 and 1.9 s at 0.625 and 0.156 ms | all_in |
| R8 nearer the reference as the step shrinks | On, the first joint's distance from the reference at 2.6 s no larger at each step than at the step before, and within 0.05 rad at 0.156 ms | all_ge, le |
| R9 a number | Every play on a number throughout | all_eq |

As released and off play at XPBD's default iterations, as users play it; on at 64.

Reported, not ruled: every reading at every instant, the chain's second joint, the release at 64 iterations.

## What it decides

When R1 to R9 hold, issue 8 is fixed and validated on XPBD by the joint-angle patch's fourth form with 64 iterations,
the iterations a configuration XPBD's solve needs to converge (as Study 15's). A rule that fails is reported as
failed, and the issue stays open.
