# Study 21: nothing a solver ignores goes unsaid, and SemiImplicit plays a loop

**Outcome: 7 of 7 rule lines held; issue 19 fixed and validated** by Senua AI's joint-feature warnings patch with pull
request #3552, and SemiImplicit playing a loop-closing joint with Newton's own `joint_attach_kd=0`. Registered 21
October 2026 ([`PREREGISTRATION_21.md`](../../preregistrations/PREREGISTRATION_21.md), amended before the play); played
once as [run 110](../../validation/run_110_study_21/README.md).

## How it got here

| Run | What | Result |
|---|---|---|
| [056](../../validation/run_056_joint_velocity_effort_limits/README.md) | Velocity and effort limits on every solver | The velocity limit applied by none, the effort limit by the MuJoCo solver only; nothing said |
| [063](../../validation/run_063_loop_joint/README.md) | A loop-closing joint's limit and drive | Ignored by the MuJoCo solver and Featherstone; SemiImplicit cannot play the loop; nothing said |
| (this study's design) | Newton 1.7.0's docstrings; #2428's thread | The features are documented as unsupported; upstream's answer for the MuJoCo solver's loops is a warning, #3552 |

## The rules and the result

| Rule | Result |
|---|---|
| R1 every ignored feature named | held: 12 of 12 |
| R2 nothing said where nothing is ignored | held |
| R3 nothing new said off | held |
| R4 nothing else changes | held: 12 of 12 plays byte for byte |
| R5 SemiImplicit plays the loop, its drive applied | held |

## What it decides

**Issue 19, fixed and validated:** [`joint_feature_warnings.diff`](../../patches/newton-1.7.0/joint_feature_warnings.diff)
on [`pr_3552_on_1.7.0.diff`](../../patches/upstream/pr_3552_on_1.7.0.diff), switch
`NEWTON_WARN_IGNORED_JOINT_FEATURES=1`; for SemiImplicit's loops, `joint_attach_kd=0`.
