# Thirty-eighth pre-registration: XPBD's joints solved colour by colour, at full relaxation, at two iteration counts

Registered 21 October 2026, after Study 37 (run 140) and the host check that followed it. Registered before any play of
this registration existed. To be played once, as run 141, on Newton 1.7.0.

## The question

Issue 12, XPBD's part: a free chain loses energy on XPBD because its joint pass is a Jacobi iteration that only
under-relaxation keeps stable (run 125's notes). Senua AI's joint colours
([`xpbd_joint_colours_on_1.7.0.diff`](../patches/in_design/xpbd_joint_colours_on_1.7.0.diff), switch
`NEWTON_XPBD_JOINT_COLOURS=1`) make it a Gauss-Seidel sweep over colours of joints sharing no dynamic body. Study 37
(8 of 9): at XPBD's own full relaxation the free chain is stable, its loss falls with every halving of the step and is
seven times below the released solver's at 0.1 ms; its R4 failed, the departure at 0.4 ms 4,178 ppm at 32 iterations
against 3,615 at 128. The host check after it (on Study 37's chain at 0.4 ms, not registered): 4,119 ppm at 256
iterations and 6,300 at 512. The departure does not settle as the iterations grow: XPBD's iteration in 32 bits has no
single answer to converge to, so convergence in the iterations is not asked here. What is asked is the issue's own
right answer, a loss that falls as the step shrinks, at two iteration counts, and better than the release at each.

## The right answers

- A free chain's energy is constant; a consistent integrator's departure from it falls as the step shrinks.
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

- **C, a free chain**: links of 0.95 and 1.05 kg, radius 0.04 m, the first's centre 0.23 m from the base hinge, the
  second hinge 0.46 m out and the second's centre 0.24 m beyond it, released at 0 and 0.55 rad turning at 1.7 and -1.3
  rad/s, no gravity, 2 s. Stock at its defaults (2 iterations, relaxations 0.7 and 0.4) at 1.6, 0.8, 0.4, 0.2 and
  0.1 ms; stock at full relaxation (both 1.0) at 8 and 32 iterations, 0.4 ms; on at full relaxation, at 8 and at 32
  iterations, at the five steps; off as each stock play.
- **J, one arm**: a 0.9 kg arm of half-size 0.035 m, its centre 0.35 m from its hinge, released level under gravity,
  2 s, at 1 and 0.25 ms; stock and on, both at XPBD's defaults.
- **G, a chain swinging under gravity** (reported): links of 1.2 and 0.7 kg, radius 0.04 m, arms 0.2, 0.42 and 0.21 m,
  released at rest at 0.35 and 0.6 rad, 2 s, at 1.6, 0.4 and 0.1 ms; stock at its defaults and on at full relaxation,
  32 iterations.

## The rules

Each judged by `sx_contact rule`, from the measured lines, and nowhere else. "The departure" is `chain`'s
`energy_largest_drift_ppm`.

| Rule | Statement | Kind |
|---|---|---|
| R1 safe when off | Off, every play byte for byte stock's | eq (count) |
| R2 the fault is there | Stock at full relaxation, at 8 and at 32 iterations, the chain's largest kinetic energy at least ten times its start | all_ge |
| R3 falls with the step | On, full relaxation: C's departure falls at each halving of the step from 1.6 to 0.1 ms, at 8 iterations and at 32 | falls, a line each |
| R4 better than released | At 0.4, 0.2 and 0.1 ms, on's departure at 8 and at 32 iterations each at most half of stock's at its defaults | le, a line a step and count |
| R5 one joint unchanged | J on, at both steps, byte for byte stock's | eq (count) |
| R6 a number | Every play on a number throughout | all_eq |

Reported, not ruled: every reading, momentum, and G.

## What it decides

When R1 to R6 hold, issue 12's XPBD part is fixed for a free chain by Senua AI's joint colours patch with XPBD's own
relaxation options at 1.0: the chain's loss falls with the step at either iteration count, where as released it can only
be kept stable by the under-relaxation that takes it. G, a chain under gravity, is reported beside it. A rule that fails
is reported as failed, and XPBD's part stays open.
