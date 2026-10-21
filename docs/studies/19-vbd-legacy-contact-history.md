# Study 19: VBD's legacy path holds a load at rest with its contacts carried

**Outcome: 4 of 4 rule lines held; issue 6 fixed and validated on VBD's legacy path** (`SolverVBD`'s default in 1.7.0)
by Newton's own configuration, its contact history with the collision pipeline's sticky contact matching, the slide
judged against Coulomb's distance. Registered 21 October 2026
([`PREREGISTRATION_19.md`](../../preregistrations/PREREGISTRATION_19.md)); played once as
[run 103](../../validation/run_103_study_19/README.md).

## How it got here

[Study 17](17-vbd-contact-history.md) held the load still on both VBD paths with this configuration, but on the legacy
path its rule for the slide took the cold slide as the reference, and the cold slide is itself wrong (F2): carrying the
contacts moved it toward Coulomb's distance and the rule failed. This study judges the slide against the right answer.

## The rules and the result

| Rule | Result |
|---|---|
| R1 the fault is there, cold: 1,000 um/s or more | held: 20,352 to 353,588 um/s |
| R2 held, carried | held: within 1 um/s |
| R3 the slide no further from Coulomb's distance than cold | held, nearer at every step |
| R4 a number | held |

## What it decides

**Issue 6 on VBD's legacy path, fixed and validated** by `SolverVBD(rigid_contact_history=True)` with
`CollisionPipeline(contact_matching="sticky")`. With Study 17 (VBD-ALM), issue 6 is fixed on VBD.
