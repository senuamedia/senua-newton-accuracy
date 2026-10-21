# Study 31: the implicit MPM solver's thin colliders kept whole by a margin

**Outcome: 3 of 4 rule lines held; R2 failed, #4712's leak stays open.** Registered 21 October 2026
([`PREREGISTRATION_31.md`](../../preregistrations/PREREGISTRATION_31.md)); played once as
[run 134](../../validation/run_134_study_31/README.md). With no margin the cup leaks at every voxel size and step; a
margin of half a voxel keeps every particle in; a quarter voxel does not at an 8 mm voxel (54 and 5 particles out).

## The rules and the result

| Rule | Result |
|---|---|
| R1 the fault is there | held: 731, 169, 466 and 104 particles out with no margin |
| R2 a quarter voxel kept whole | **failed**: 54 and 5 out at the 8 mm voxel, 0 at 12 mm |
| R3 half a voxel kept whole | held: 0 at every voxel size and step |
| R4 a number | held |

## What it decides

The leak stays open by the registration; half a voxel is registered next, on new voxel sizes and steps (Study 32).
