# Thirty-seventh pre-registration: XPBD's joints solved colour by colour, at full relaxation

Registered 21 October 2026, after run 125's host checks of XPBD's joint solve. Registered before any play of this
registration existed. To be played once, as run 140, on Newton 1.7.0.

## The question

Issue 12, XPBD's part: a free two-link chain loses energy on XPBD (F9: 30% in 2 s at 10 ms; 8,447 to 12,466 ppm at
0.375 ms at its default relaxations). Run 125's notes trace it to the joint pass: every joint is solved from the same
state and two joints sharing a link each move it by its whole correction, so the pass is a Jacobi iteration that only
under-relaxation (0.7 linear, 0.4 angular) keeps stable; at full relaxation it diverges at every iteration count, and
the under-relaxation is where the energy goes. Averaging the corrections per body (Senua AI's joint averaging, the
contact pass's own remedy) kept it stable but gained 12% of the energy.

Senua AI's joint colours ([`xpbd_joint_colours_on_1.7.0.diff`](../patches/in_design/xpbd_joint_colours_on_1.7.0.diff),
switch `NEWTON_XPBD_JOINT_COLOURS=1` read once) make the joint pass a Gauss-Seidel sweep over colours: the joints are
coloured so that no two of one colour act on the same dynamic body, and each colour is solved and its corrections
applied before the next (graph colouring for position-based dynamics, Fratarcangeli, Tibaldo and Pellacini 2016). With
the switch unset the pass is the released one, one launch over every joint; a scene of one joint has one colour. On the
Newton host (run 125's chain, not registered): at full relaxation the chain stable at every iteration count, its
departure at 32 iterations 23,982, 11,076, 3,937, 1,265 and 389 ppm from 1.5 to 0.094 ms and 3,941 at 128; a chain
swinging under gravity departs by about half the released solver's, 57,009 ppm at 0.1 ms. On a chain and steps no run
used: does XPBD with its joints coloured and its own relaxation options at 1.0 keep a free chain's energy as the step
shrinks?

## The right answers

- A free chain's energy is constant; a consistent integrator's departure from it falls as the step shrinks, and an
  iterative solve converges as its iterations grow.
- A change to how several joints are solved together changes nothing for one joint.

## Engines and rigs

Newton 1.7.0 from PyPI (`newton==1.7.0`, Warp 1.18.0, MuJoCo Warp 3.15.0) as released (**stock**), Study 7's
environment, and the engine made from it by this run's `setup_engine.sh` with the joint colours patch, no fuzz, first
on the path: **off** without `NEWTON_XPBD_JOINT_COLOURS`, **on** with it set to 1. Rigs as committed at this
registration: `tools/nwt_chain.py` and `tools/nwt_joint.py`. Warp's CPU device. XPBD's relaxations set by its own
constructor options (`opt.joint_linear_relaxation`, `opt.joint_angular_relaxation`), its iterations by `iterations`.
Measured by Senua AI's `sx_contact` (`chain`, `swing`) and judged by its `rule`.

## The scenes, registered parameters

None of these numbers was used in a run.

- **C, a free chain**: links of 1.1 and 0.9 kg, radius 0.04 m, the first's centre 0.25 m from the base hinge, the second
  hinge 0.5 m out and the second's centre 0.22 m beyond it, released at 0 and 0.4 rad turning at 2.0 and -1.0 rad/s,
  no gravity, 2 s. Stock at its defaults (2 iterations, relaxations 0.7 and 0.4) at 1.6, 0.8, 0.4, 0.2 and 0.1 ms;
  stock at full relaxation (both 1.0) at 2, 8, 32 and 128 iterations, 0.4 ms; on at full relaxation, 32 iterations at
  the five steps and 2, 8 and 128 iterations at 0.4 ms; off as each stock play.
- **J, one arm**: a 1.2 kg arm of half-size 0.04 m, its centre 0.4 m from its hinge, released level under gravity, 2 s,
  at 1 and 0.25 ms; stock and on, both at XPBD's defaults.
- **G, a chain swinging under gravity** (reported): links of 1.0 and 0.8 kg, radius 0.04 m, arms 0.22, 0.45 and 0.2 m,
  released at rest at 0.3 and 0.5 rad, 2 s, at 1.6, 0.4 and 0.1 ms; stock at its defaults and on at full relaxation, 32
  iterations.

## The rules

Each judged by `sx_contact rule`, from the measured lines, and nowhere else. "The departure" is `chain`'s
`energy_largest_drift_ppm`.

| Rule | Statement | Kind |
|---|---|---|
| R1 safe when off | Off, every play byte for byte stock's | eq (count) |
| R2 the fault is there | Stock at full relaxation, at each of 2, 8, 32 and 128 iterations, the chain's largest kinetic energy at least ten times its start | all_ge |
| R3 falls with the step | On, full relaxation, 32 iterations: C's departure falls at each halving of the step from 1.6 to 0.1 ms | falls |
| R4 converged | On, full relaxation, 0.4 ms: the departure at 128 iterations within 1 in 10 of the departure at 32 | within |
| R5 better than released | At 0.4, 0.2 and 0.1 ms, on's departure (32 iterations, full relaxation) at most half of stock's at its defaults | le, a line a step |
| R6 one joint unchanged | J on, at both steps, byte for byte stock's | eq (count) |
| R7 a number | Every play on a number throughout | all_eq |

Reported, not ruled: every reading, momentum, on at 2 and 8 iterations, and G.

## What it decides

When R1 to R7 hold, issue 12's XPBD part is fixed for a free chain by Senua AI's joint colours patch with XPBD's own
relaxation options at 1.0 and 32 iterations: the chain's loss falls with the step, where as released it can only be
kept stable by the under-relaxation that takes it. G, a chain under gravity, is reported beside it. A rule that fails is
reported as failed, and XPBD's part stays open.
