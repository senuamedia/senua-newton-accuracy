# Sixteenth pre-registration: Featherstone's step as the classic Runge-Kutta scheme

Registered 21 October 2026, after the design probe of run 096. Registered before any play of this registration
existed. To be played once, as run 100, on Newton 1.7.0.

## The question

Issue 11, Featherstone's part: a joint chain with nothing acting on it gains energy on Featherstone, in proportion to
the step (F8: 9.7% in 2 s at 10 ms, run 014), as on the MuJoCo solver under Euler, which its own RK4 fixes (Study 9).
Featherstone has no other integrator. Senua AI's Featherstone RK4 patch makes Featherstone's step in four stages as
MuJoCo makes its RK4, each stage's accelerations the stock step's own; on Study 9's free chain it held the energy
within 14 ppm and the angular momentum within 2 ppm from 10 to 0.125 ms, and a swinging chain within 7 ppm at 2.5 ms
(run 096). On chains and steps no probe used: is the fault there as released, and gone with the patch?

## The right answers

- A chain with nothing acting on it keeps its kinetic energy and its angular momentum about its fixed joint.
- A chain swinging under gravity keeps its total energy, kinetic and potential.
- The classic Runge-Kutta scheme's error falls as the fourth power of the step; a free fall, whose acceleration is
  constant, it integrates exactly.

## Engines and rigs

Newton 1.7.0 from PyPI (`newton==1.7.0`, Warp 1.18.0, MuJoCo Warp 3.15.0) as released, Study 7's environment, and one
engine made from it by this run's `setup_engine.sh`: the base environment's Newton with Senua AI's Featherstone RK4
patch applied (no fuzz), first on the path
([`featherstone_rk4_on_1.7.0.diff`](../patches/in_design/featherstone_rk4_on_1.7.0.diff), switch
`NEWTON_FEATHERSTONE_RK4=1`). Rigs as committed at this registration: `tools/nwt_chain.py`, `tools/contact_suite.sh`.
Warp's CPU device. Featherstone with its own defaults in every play. Measured by Senua AI's `sx_contact` (`chain`, `gap`,
the first deep dive's suite runner for the verdicts) and judged by its `rule`.

## The scenes, registered parameters

None of these numbers was used in the probe.

- **F, a free chain** (no gravity): links of 1.1 and 0.5 kg, half-size 0.035 m, the first's centre 0.22 m from its
  joint, the second joint 0.45 m out, the second's centre 0.2 m beyond it, at 0 and 0.6 rad turning at 1.8 and -0.7
  rad/s, 2 s; at 6, 3, 1 and 0.25 ms; as released, with the switch unset, and set.
- **W, a swinging chain** under gravity: links of 0.7 and 0.9 kg, half-size 0.035 m, the first's centre 0.18 m from its
  joint, the second joint 0.4 m out, the second's centre 0.22 m beyond it, released at rest at -0.5 and 1.0 rad, 2 s;
  at 5, 2 and 0.5 ms; the same three settings.
- **T, the contact suite** on Featherstone, as released and with the switch set.

## The rules

Each judged by `sx_contact rule`, from the measured lines, and nowhere else.

| Rule | Statement | Kind |
|---|---|---|
| R1 safe when off | With the switch unset every F and W play byte for byte the release's | eq (count) |
| R2 the fault is there | As released F's energy departs 100 ppm or more at every step | all_ge |
| R3 the free chain kept | With RK4 F's energy and angular momentum within 20 ppm of their start at every step | all_le |
| R4 the swinging chain kept | With RK4 W's energy within 100 ppm at 2 and 0.5 ms, and within 1,000 ppm at 5 ms | all_le, le |
| R5 a number | Every play with RK4 a number throughout | all_eq |
| R6 nothing lost | Every suite verdict that passes as released passes with RK4, but T01 and T08 | eq (count) |
| R7 T01 and T08 no worse | For T01 (a free fall) and T08 (the refinement chain), each of RK4's gaps between successive steps no larger than the release's at the same halving | all_ge (the release's gap less RK4's) |

T01 and T08 ask that the gap between successive steps halve, or fall, at every halving: a first-order scheme's
convergence. RK4 integrates T01's free fall exactly, leaving rounding (run 096: gaps of 88 to 6,285 um summed over the
instants compared, the largest 2 um, against the release's 1,237,356 halving), and T08's chain, which strikes the ground,
converges faster but not at every halving (run 096). R7 asks of them what holds for any scheme that improves on the
release: at no halving is RK4 further from its next step than the release is.

Reported, not ruled: every drift at its end and its largest, W as released, every verdict.

## What it decides

When R1 to R7 hold, issue 11 is fixed and validated on Featherstone by the RK4 patch. A rule that fails is reported as
failed, and the issue stays open there.
