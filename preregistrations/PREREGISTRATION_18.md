# Eighteenth pre-registration: SemiImplicit's and Featherstone's friction as Coulomb's law at the step's end

Registered 21 October 2026, after the design probes of runs 090, 092, 093, 094, 097 and 099. Registered before any play
of this registration existed. To be played once, as run 102, on Newton 1.7.0.

## The question

Two issues share one cause on SemiImplicit and Featherstone, whose contact friction is a force integrated explicitly:
below mu N / kf it is viscous, so a load inside the friction limit creeps (issue 6, F4: 735 um/s on run 001's hold),
and its kf settles only for steps under about 1.25 m / (10 kf), so a small cube at a 2 ms step is past it (issue 9,
F6: run 021; its normal part is fixed by Study 9). Senua AI's Coulomb friction patches take the friction out of the
force pass and, after the step's integration, give each contact the impulse that stops its slip, its total over the
step within Coulomb's cone, the pass made 64 times a step; on Featherstone the impulses reach the joints through the
joint-space inertia built where the step leaves them. Stacked on Senua AI's contact damping patch (Study 3, issue 4),
the probes held run 001's cube within 1 um/s at 2 to 0.125 ms on both solvers, slid it within 0.5% of Coulomb's
distance, and lost no suite verdict (runs 093, 097, 099). On cubes, loads and steps no probe used: does it hold?

## The right answers

- A body pushed with less force than its friction can hold does not move (Coulomb's law).
- A body sliding is slowed by friction at mu times the normal force: from v0 it stops in v0^2 / (2 mu g).
- At an impact the friction impulse is mu times the normal impulse while the contact slides.

## Engines and rigs

Newton 1.7.0 from PyPI (`newton==1.7.0`, Warp 1.18.0, MuJoCo Warp 3.15.0) as released, Study 7's environment, and one
engine made from it by this run's `setup_engine.sh`: the base environment's Newton with, in order and with no fuzz,
Senua AI's unit friction direction and contact damping patches as validated
([`patches/newton-1.7.0/`](../patches/newton-1.7.0/README.md)), its SemiImplicit Coulomb friction patch's third form
([`semi_coulomb_friction_v3_on_damping.diff`](../patches/in_design/semi_coulomb_friction_v3_on_damping.diff)) and its
Featherstone Coulomb friction patch's third form
([`featherstone_coulomb_friction_v3_on_semi_coulomb_v3.diff`](../patches/in_design/featherstone_coulomb_friction_v3_on_semi_coulomb_v3.diff)),
first on the path. **On** sets `NEWTON_CONTACT_DAMPING_NO_PULL=1` and, on SemiImplicit,
`NEWTON_SEMI_COULOMB_FRICTION=1` with `NEWTON_SEMI_COULOMB_FRICTION_ITERATIONS=64`, on Featherstone
`NEWTON_FEATHERSTONE_COULOMB_FRICTION=64`; **off** is the same engine with no switch set. Rigs as committed at this
registration: `tools/nwt_contact.py`, `tools/contact_suite.sh`. Warp's CPU device. Measured by Senua AI's `sx_contact`
(`creep`, `stop`, the first deep dive's suite runner for the verdicts) and judged by its `rule`.

## The scenes, registered parameters

None of these numbers was used in the probes. SemiImplicit and Featherstone in every scene, each with its own
defaults.

- **H, a hold** (6): a 0.6 kg cube of half-size 0.035 m on the ground, friction 0.4, pushed by 1.6464 N (0.7 of what
  friction holds) from 0.4 s, 1.6 s; at 1.5, 0.4 and 0.1 ms, within its normal contact's m / (4 kd) = 1.5 ms (Newton's
  default kd, 100 N s/m: Study 9's bound for issue 9's normal part); as released, off and on.
- **N, issue 9's scene, a small cube at a 2 ms step** (9): a 0.8 kg cube of half-size 0.04 m, friction 0.6, pushed by
  2.352 N (0.5 of what friction holds) from 0.5 s, 1.5 s; at 2 and 1.6 ms, within its m / (4 kd) = 2 ms; as released,
  off and on.
- **S, a slide** (6): the 0.6 kg cube from 0.8 m/s, friction 0.4, 0.6 s: Coulomb's distance 81,633 um; at 1.5, 0.4
  and 0.1 ms; as released, off and on.
- **T, the contact suite**, as released and on.

## The rules

Each judged by `sx_contact rule`, from the measured lines, and nowhere else.

| Rule | Statement | Kind |
|---|---|---|
| R1 safe when off | Off, every H, N and S play on both solvers byte for byte the release's | eq (count) |
| R2 the fault is there | As released H creeps 100 um/s or more at every step on both solvers | all_ge |
| R3 held | On, H within 10 um/s of still at every step on both solvers | all_in |
| R4 issue 9's scene held | On, N within 10 um/s of still at 2 and 1.6 ms on both solvers, and turned no more than 10 mrad from its start | all_in, all_le |
| R5 Coulomb's slide | On, S within 1 in 100 of 81,633 um at every step on both solvers | all_within |
| R6 Coulomb at impact | On, the suite's Coulomb at impact (T05) and friction over an impact (T10) within 1 in 100 of 4,000 at every step from its 1/2 on SemiImplicit and from its 1/4 on Featherstone | all_within |
| R7 nothing lost | On, every suite verdict that passes as released passes, on both solvers | eq (count) |
| R8 a number | Every play on a number throughout | all_eq |

R6 starts at the suite's 1/4 step on Featherstone: there the friction at impact converges to Coulomb's as the step
shrinks, first order, 0.75% short at 1/4 and 5% at 1/2 (runs 097, 099), the same with the inertia built at the step's
start or its end, where on SemiImplicit the same passes are exact at every step: Featherstone's own first-order
integration of a spinning body, not the friction.

Reported, not ruled: every reading as released, the suites' other readings, how far each cube turns.

## What it decides

When R1 to R8 hold, issue 6 is fixed and validated on SemiImplicit and Featherstone, and issue 9 is fixed on both, its
friction part by these patches and its normal part by Study 9. A rule that fails is reported as failed, and the part
stays open.
