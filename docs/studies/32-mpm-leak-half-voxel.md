# Study 32: the implicit MPM solver's thin colliders kept whole by a margin of half a voxel

**Outcome: 2 of 3 rule lines held; R2 failed, #4712's leak stays open.** Registered 21 October 2026
([`PREREGISTRATION_32.md`](../../preregistrations/PREREGISTRATION_32.md)); played once as
[run 135](../../validation/run_135_study_32/README.md). Half a voxel kept the cup whole at a 7 mm voxel at 12 and 24
substeps and at 14 mm at 24, and let 9 particles out at 14 mm and 12 substeps.

## The rules and the result

| Rule | Result |
|---|---|
| R1 the fault is there | held: 134, 68, 706 and 219 particles out with no margin |
| R2 half a voxel kept whole | **failed**: 9 out at the 14 mm voxel and 12 substeps, 0 elsewhere |
| R3 a number | held |

## What it decides

With Study 31, a margin is not the fix: what crosses a wall depends on how far a step carries a particle against the
collider's thickness. #4712's leak stays open, for a fix to the collider that takes the step into account.
