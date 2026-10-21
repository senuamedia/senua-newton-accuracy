# Study 20: XPBD's joint limit holds an arm and stops a chain as a hard limit does

**Outcome: 13 of 13 rule lines held; issue 8 fixed and validated on XPBD** by Senua AI's joint-angle patch in its
fourth form at 64 iterations. Registered 21 October 2026
([`PREREGISTRATION_20.md`](../../preregistrations/PREREGISTRATION_20.md)); played once as
[run 109](../../validation/run_109_study_20/README.md).

## How it got here

| Run | What | Result |
|---|---|---|
| [048](../../validation/run_048_xpbd_limit_gain/README.md), [050](../../validation/run_050_xpbd_swing_gradient/README.md), [051](../../validation/run_051_xpbd_limit_anchor_held/README.md), [061](../../validation/run_061_xpbd_limit_full/README.md) | The limit's gain toward pi, its coupling to the anchor, the anchor held, the limit in full | One arm held at every lever and limit; a chain not held |
| [081](../../validation/run_081_xpbd_limit_chain_iterations/README.md) | The chain against the iterations | Not held at any count |
| [105](../../validation/run_105_xpbd_limit_chain_reference/README.md) | The chain's right answer, by MuJoCo's own engine with an ever stiffer limit | Not held: the first joint stays dead until half a turn of the second link, then leaves; run 061's prediction corrected |
| [106](../../validation/run_106_xpbd_limit_chain_forms/README.md), [107](../../validation/run_107_xpbd_limit_chain_steps/README.md) | The patch's forms, relaxations, iterations and steps against it | From 16 iterations the first joint dead on the limit; at 64 nearer the reference as the step shrinks |

## The rules and the result

| Rule | Result |
|---|---|
| R1 safe when off | held |
| R2 the fault: as released the arms turn back at 0.5 rad/s or more | held: 1.93 to 2.68 rad/s |
| R3 the arms held | held: within 2 mrad, under 0.005 rad/s |
| R4 the reference converged | held: within 0.035 mrad |
| R5 the reference stops the chain as the closed form has it | held |
| R6 the fault on the chain: as released 0.01 rad or more off the limit | held: 23 to 39 mrad |
| R7 on, the first joint on the limit | held: within 2 urad |
| R8 on, nearer the reference as the step shrinks | held: 0.140, 0.069 and 0.029 rad |
| R9 a number | held |

## What it decides

**Issue 8 on XPBD, fixed and validated:** [`xpbd_joint_angle_v4.diff`](../../patches/newton-1.7.0/xpbd_joint_angle_v4.diff),
switch `NEWTON_XPBD_JOINT_ANGLE_UNWRAP=4`, and `iterations=64`, XPBD's relaxations its defaults.
