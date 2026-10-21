# Twenty-sixth pre-registration: two shapes' frictions combined by one rule on every solver

Registered 21 October 2026, after run 059 and the design probe of run 127. Registered before any play of this
registration existed. To be played once, as run 128, on Newton 1.7.0.

## The question

Issue 18 (N3, discussion #2377): two shapes in contact each carry a friction coefficient, and Newton's solvers combine
them differently: XPBD, SemiImplicit and Featherstone the mean, VBD the geometric mean, the MuJoCo solver MuJoCo's rule,
the larger or, when MuJoCo's geom priority is registered and differs, the higher-priority shape's; so one model slides
differently by solver, and the priority is honoured by the MuJoCo solver alone (run 059). The MuJoCo solver can follow no
other rule. Senua AI's friction combination patch, with `NEWTON_FRICTION_COMBINE=1`, makes Newton's own solvers follow
MuJoCo's rule for body contacts; in run 127 every solver then slid a mixed scene as its own slide at the coefficient the
rule picks. On two pairings and steps no probe used: does it?

## The right answers

- One model plays one friction, whichever solver plays it: two shapes' coefficients combined by one rule, the geom
  priority, where the model gives one, honoured by every solver.
- The rule every solver can follow is MuJoCo's, the one the MuJoCo solver cannot leave.

## Engines and rigs

Newton 1.7.0 from PyPI (`newton==1.7.0`, Warp 1.18.0, MuJoCo Warp 3.15.0) as released, Study 7's environment, and one
engine made from it by this run's `setup_engine.sh`: the base environment's Newton with Senua AI's friction combination
patch applied (no fuzz), first on the path
([`friction_combine_on_1.7.0.diff`](../patches/in_design/friction_combine_on_1.7.0.diff), sha256 35c754f7077b0103...);
**on** sets `NEWTON_FRICTION_COMBINE=1`, **off** does not. Rig as committed at this registration: `tools/nwt_contact.py`
(its `groundmu`, `register`, `prio`, `groundprio`). Warp's CPU device. Measured by Senua AI's `sx_contact` (`stop`) and
judged by its `rule`.

## The scenes, registered parameters

None of these numbers was used in the probes. A 0.7 kg cube of half-size 0.04 m sent along the ground at 0.8 m/s, 0.7
s, at 1 ms, on XPBD, SemiImplicit, Featherstone, VBD and the MuJoCo solver:

- **A**: the cube's friction 0.35, the plane's 0.75; **B**: the cube's 0.6, the plane's 0.15.
- Each with the priority unregistered, registered and equal, the cube's higher, and the plane's higher; as released, off
  and on.
- Beside each, the same slide with one friction for both, at each of the four coefficients, as released.

## The rules

Each judged by `sx_contact rule`, from the measured lines, and nowhere else. "The rule's coefficient" is the larger of
the pair, or the cube's when its priority is higher, or the plane's when the plane's is.

| Rule | Statement | Kind |
|---|---|---|
| R1 safe when off | Off, every mixed play byte for byte the release's | eq (count) |
| R2 the fault is there | As released, on A, XPBD's and VBD's mixed slide (no priority) departs from their slide at the larger coefficient by 1 in 10 or more | all_ge |
| R3 one rule | On, every solver's mixed slide, in each pairing and each priority, within 1 in 100 of its own slide at the rule's coefficient | within |
| R4 the MuJoCo solver kept | On, the MuJoCo solver's mixed plays byte for byte its plays as released | eq (count) |
| R5 a number | Every play on a number throughout | all_eq |

Reported, not ruled: every distance.

## What it decides

When R1 to R5 hold, issue 18's combination part is fixed and validated: with the patch every solver combines two
shapes' frictions by MuJoCo's rule and honours MuJoCo's geom priority. Issue 18's other parts, a static coefficient and
its import, stay open until their own study. A rule that fails is reported as failed, and the part stays open.
