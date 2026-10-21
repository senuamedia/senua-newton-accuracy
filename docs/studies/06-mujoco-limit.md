# Study 6: the MuJoCo solver's joint limit with the stiffness and damping Newton gives it

**Outcome: 9 of 9 rule lines held; the patch validated** where the step is inside the limit spring's own range
(h sqrt(ke / I) at most 1). Registered 15 October 2026
([`PREREGISTRATION_06.md`](../../preregistrations/PREREGISTRATION_06.md)); played once as
[run 043](../../validation/run_043_study_06/README.md).

## The question

Newton converts a joint limit's `limit_ke` and `limit_kd` for the MuJoCo solver with a factor `dof_invweight0 *
(1 - dmax)`, but MuJoCo's soft limit already holds with d^2 k / invweight, leaving 0.05 of each by default (F15). The
patch converts by `dof_invweight0` alone. The right answer: the limit's spring and damper kept from pulling (Schwager
and Poeschel 2007), a limit being one-sided.

## How it got here

| Run | What | Result |
|---|---|---|
| [036](../../validation/run_036_limit_damping_inertia/README.md) | N5 measured | The MuJoCo solver's limit 15 to 20 times softer, damped at a fifth of the ratio |
| [039](../../validation/run_039_mujoco_limit_force_space/README.md) | F15 traced; the patch held to the five checks | The stiffness right, the light arms turning back higher than on Featherstone |
| [042](../../validation/run_042_mujoco_limit_damping_step/README.md) | That difference against the step | Not the step: Featherstone's limit pulls (F16); the patched limit is the no-tension form's to 0.011 rad |

## The rules and the result

| Rule | Result |
|---|---|
| R1 safe when off: 10 of 10 files | held |
| R2 the fault is there: the arm turns back 0.35 and 0.20 rad higher than the right answer | held |
| R3 the strike within 0.03 rad of the right answer, both masses and steps | held: within 0.022 |
| R4 no limit, no change: 4 of 4 files | held |
| R5 no play stops being a number or leaves the format's range | held |

## The patch

[`patches/mujoco_limit_force_space.diff`](../../patches/mujoco_limit_force_space.diff) (sha256 77925587f1591155...),
switch `NEWTON_MUJOCO_LIMIT_FORCE_SPACE=1`. See [the patches](../patches.md).
