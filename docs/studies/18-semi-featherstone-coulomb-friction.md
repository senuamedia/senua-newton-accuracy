# Study 18: SemiImplicit's and Featherstone's friction as Coulomb's law at the step's end

**Outcome: 19 of 19 rule lines held; issue 6 fixed and validated on SemiImplicit and Featherstone, and issue 9 on both**
by Senua AI's Coulomb friction patches on its contact damping patch. Registered 21 October 2026
([`PREREGISTRATION_18.md`](../../preregistrations/PREREGISTRATION_18.md)); played once as
[run 102](../../validation/run_102_study_18/README.md).

## How it got here

| Run | What | Result |
|---|---|---|
| [090](../../validation/run_090_semi_coulomb_friction/README.md) | SemiImplicit's friction taken out of the force pass and applied after the step as the impulse that stops each contact's slip | The slide Coulomb's at every step; the hold still creeping in proportion to the step |
| [092](../../validation/run_092_semi_coulomb_sweeps/README.md) | The pass made 1 to 64 times a step, the friction bounded on the step's total | Still from 16 sweeps; the suite's refinement chain lost to the bounce (issue 4) |
| [093](../../validation/run_093_semi_coulomb_damping/README.md) | The same on the contact damping patch | The suite 7 of 10, nothing lost |
| [094](../../validation/run_094_featherstone_coulomb/README.md), [097](../../validation/run_097_featherstone_coulomb_v2/README.md), [099](../../validation/run_099_featherstone_coulomb_v3/README.md) | The pass for Featherstone, its impulses through the joint-space inertia | Still at every step; sliding, the impulse first mapped about where the step began, then about where it ends; what is left at impact is Featherstone's first-order integration of a spinning body |

## The rules and the result

| Rule | Result |
|---|---|
| R1 safe when off | held |
| R2 the fault is there: as released 100 um/s or more | held: up to 368 mm/s (SemiImplicit) and 785 mm/s (Featherstone) |
| R3 held within 10 um/s | held: 0 at every step on both |
| R4 issue 9's small cube at its 2 ms step held and level | held: within 1 um/s, 6 mrad (as released thrown at over 1 m/s) |
| R5 the slide within 1 in 100 of Coulomb's distance | held: within 0.45% at every step on both |
| R6 Coulomb at impact within 1 in 100 | held: from the suite's 1/2 step on SemiImplicit, its 1/4 on Featherstone |
| R7 no suite verdict lost | held |
| R8 a number | held |

## What it decides

**Issue 6 on SemiImplicit and Featherstone, fixed and validated:** [`semi_coulomb_friction.diff`](../../patches/newton-1.7.0/semi_coulomb_friction.diff)
and [`featherstone_coulomb_friction.diff`](../../patches/newton-1.7.0/featherstone_coulomb_friction.diff), on
[`unit_friction_direction.diff`](../../patches/newton-1.7.0/unit_friction_direction.diff) and
[`contact_damping_no_pull.diff`](../../patches/newton-1.7.0/contact_damping_no_pull.diff); switches
`NEWTON_CONTACT_DAMPING_NO_PULL=1` and, on SemiImplicit, `NEWTON_SEMI_COULOMB_FRICTION=1` with
`NEWTON_SEMI_COULOMB_FRICTION_ITERATIONS=64`, on Featherstone `NEWTON_FEATHERSTONE_COULOMB_FRICTION=64`. With Studies
11, 15, 17 and 19, issue 6 is fixed on every solver. **Issue 9, fixed on both its solvers**: its friction part here, its
normal part by Study 9.
