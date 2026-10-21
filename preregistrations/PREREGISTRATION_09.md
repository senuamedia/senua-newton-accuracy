# Ninth pre-registration: five issues answered by Newton's own options

Registered 20 October 2026, after design probes (runs 012, 014, 021, 023, 024, 030 and 031). Registered before any play
of this registration existed. To be played once, as run 064, on Newton 1.7.0 as released.

## The question

Five of the record's open issues each have a remedy that is one of Newton's own options, measured in a design probe
but never held to rules registered in advance. On scenes and steps no probe used: is each fault there as released,
and does the option remove it, every rule decided by the measure?

| Issue | The fault | The option | Measured in |
|---|---|---|---|
| 11, the MuJoCo solver's half | A free chain gains energy | `integrator=rk4`, the MuJoCo solver's own RK4 | run 014 |
| 13, the MuJoCo solver's half | A spinning body's centre of mass moves | `integrator=rk4` | runs 030, 031 |
| 14 | The state stops being a number at a friction of 0.001 or less | `cone=elliptic`, the MuJoCo solver's elliptic cone | runs 012, 023 |
| 9 | A small cube launched at a step Newton's explicit contact damper cannot carry | a step at most m / (4 kd), with the normal contact of Study 3 | run 021 |
| 10 | SemiImplicit cannot play a joint chain | `joint_attach_kd=0`, the joint penalty's spring alone | run 024 |

Issues 11 and 13 also name another solver (Featherstone; VBD-ALM): this study decides the MuJoCo solver's half only, and
those halves stay open.

## The right answers

- **A free chain** (nothing acts on it) keeps its kinetic energy and its angular momentum about its first joint
  (Landau and Lifshitz, *Mechanics*).
- **A free body spinning about its centre of mass** keeps that centre at rest.
- **A cube dropped onto the ground** comes to rest on it, the ground carrying its weight.
- **A cube dropped with a restitution of 0** does not rebound (Study 3's rule).
- Every play's state is a number throughout.

## Engines and arms

Newton 1.7.0 from PyPI (`newton==1.7.0`, Warp 1.18.0, MuJoCo Warp 3.15.0) as released, Study 7's environment; for C4's
second arm, the same with Study 3's normal contact rebased onto 1.7.0
(`patches/newton-1.7.0/contact_damping_no_pull.diff` with `unit_friction_direction.diff`, Study 7's `normal`
environment, switches `NEWTON_UNIT_FRICTION_DIRECTION=1` and `NEWTON_CONTACT_DAMPING_NO_PULL=1`). Rigs as committed at
this registration: `tools/nwt_chain.py`, `tools/nwt_contact.py`. Warp's CPU device. Measured by Senua AI's `sx_contact`
(`chain`, `creep`, `stop`, `bounce`, `rest`, and each play's statistics line) and judged by its `rule`.

## The scenes, registered parameters

None of these numbers was used in the probes.

- **C1, a free chain** (issue 11): arms of 0.7 kg and 1.3 kg, half-size 0.04 m, the first arm's centre 0.25 m from its
  joint, the joints 0.5 m apart, the second arm's centre 0.22 m from its joint, started at 0 and -0.4 rad turning at 2.2
  and -1.1 rad/s, no gravity, 2 s; the MuJoCo solver as released and with `opt.integrator=rk4`; at 8, 2, 0.5 and 0.125
  ms.
- **C2, a spinning body** (issue 13): a 1.5 kg cube of half-size 0.04 m, its centre of mass 0.03 m along its x from its
  origin, spinning at 4 rad/s about it, 1 m above the ground, no gravity, 2 s; the MuJoCo solver as released and with
  `opt.integrator=rk4`; at 8, 2 and 0.5 ms. The scale of its motion: 4 rad/s x 0.03 m = 120 mm/s.
- **C3, a slippery drop** (issue 14): a 1.5 kg cube of half-size 0.035 m dropped from 60 mm, friction 0, 0.0001 and
  0.001, 0.5 s; the MuJoCo solver with its default (pyramidal) cone and with `opt.cone=elliptic`; at 2 and 0.25 ms.
- **C4, a small cube's drop** (issue 9): a 0.5 kg cube of half-size 0.035 m dropped from 70 mm, friction 0, 0.5 s, on
  SemiImplicit and Featherstone, Newton's default contact (kd 100 N s/m), m / (4 kd) = 1.25 ms; at 5 ms (4 kd h / m = 4)
  as released, and at 1.25 and 0.3125 ms (1 and 0.25) as released and with Study 3's normal contact.
- **C5, the chain on SemiImplicit** (issue 10): C1's chain on SemiImplicit as released and with
  `opt.joint_attach_kd=0`, at 1, 0.5 and 0.25 ms.

## The rules

Each judged by `sx_contact rule`, from the measured lines, and nowhere else.

| Rule | Statement | Kind |
|---|---|---|
| R1 the fault is there (11) | C1, the MuJoCo solver as released: the energy drifts by at least 1,000 ppm at 8 ms | all_ge |
| R2 kept (11) | C1 with RK4: the energy drift and the angular momentum's drift each within 100 ppm, at every step | all_within |
| R3 the fault is there (13) | C2 as released: the centre's mean speed at least 1,000 um/s at 8 ms | all_ge |
| R4 at rest (13) | C2 with RK4: the centre's largest speed in the last third within 120 um/s, 1 in 1,000 of the motion's scale, at every step | all_le |
| R5 the fault is there (14) | C3 with the default cone: the state stops being a number at every friction and step | all (nan_at_step) |
| R6 played (14) | C3 with the elliptic cone: a number throughout, and the ground carrying the cube's weight at the end within 1 in 100 (14,700 mN), at every friction and step | all_within |
| R7 the fault is there (9) | C4 at 5 ms, as released: the cube rebounds at least 1,000 per 10,000 of the drop, on both solvers | all_ge |
| R8 carried (9) | C4 at 1.25 and 0.3125 ms with Study 3's normal contact: no rebound (0 per 10,000) and a number throughout, on both solvers | all_eq |
| R9 the fault is there (10) | C5 as released: the state stops being a number at 1 ms | all (nan_at_step) |
| R10 played (10) | C5 with `joint_attach_kd=0`: a number throughout at every step, its kinetic energy after 2 s within 1 in 100 of its start | all_within |

Reported, not ruled: C4 as released at 1.25 and 0.3125 ms (issue 4's rebound, which Study 3 fixes), and every reading's
numbers at every step.

## What it decides

An issue is fixed by configuration when its "fault is there" rule holds and its option's rules hold. A rule that
fails is reported as failed, and its issue stays open.

## A correction before any registered play (20 October 2026)

The runner's dry run (throwaway parameters, `validation/run_064_study_09/dry/`) found that a SemiImplicit chain that
blows up is stopped by the rig as leaving its range (`out_of_range_at_step`), not as a value that is not a number
(`nan_at_step`), so the runner read such a play as played. "Stops being a number" in R5, R6, R8, R9 and R10 is the
rig's either: a value that is not a number, or one past the rig's range, as Study 6's runner counted them. No rule,
scene or bound changes.
