# Study 26: two shapes' frictions combined by one rule on every solver

**Outcome: 44 of 44 rule lines held; issue 18's combination part fixed and validated** by Senua AI's friction
combination patch. Registered 21 October 2026 ([`PREREGISTRATION_26.md`](../../preregistrations/PREREGISTRATION_26.md));
played once as [run 128](../../validation/run_128_study_26/README.md). Issue 18's other parts, a static coefficient and
its import, stay open.

## How it got here

| Run | What | Result |
|---|---|---|
| [059](../../validation/run_059_friction_combination/README.md) | Two frictions in one contact, and MuJoCo's geom priority | The mean on Newton's own contact, MuJoCo's rule on the MuJoCo solver: 92.5 mm against 56.9 mm |
| (the source, 1.7.0) | Each solver's combination | XPBD, SemiImplicit, Featherstone the mean; VBD the geometric mean; the MuJoCo solver MuJoCo's rule, which it cannot leave |
| [127](../../validation/run_127_friction_combine/README.md) | MuJoCo's rule on Newton's own solvers | Every solver's mixed slide its own slide at the rule's coefficient, the priority honoured |

## The rules and the result

| Rule | Result |
|---|---|
| R1 safe when off | held: 40 of 40 plays byte for byte |
| R2 the fault is there as released | held: XPBD and VBD 37% and 31% from the larger coefficient's slide |
| R3 one rule | held, 40 lines: five solvers, two pairings, four priorities, each byte for byte its slide at the rule's coefficient |
| R4 the MuJoCo solver kept | held: 8 of 8 plays byte for byte |
| R5 a number | held |

## What it decides

**Issue 18, its combination part, fixed and validated:** [`friction_combine.diff`](../../patches/newton-1.7.0/friction_combine.diff),
switch `NEWTON_FRICTION_COMBINE=1`. The static coefficient (#3560; pull request #4306's data model) and its USD import
stay open.
