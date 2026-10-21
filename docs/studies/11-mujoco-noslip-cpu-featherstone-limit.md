# Study 11: MuJoCo's recommended configuration through Newton, the MuJoCo solver's CPU path, and Featherstone's limit kept from pulling

**Outcome: 21 of 21 rule lines held.** Issue 15 is fixed and validated on the MuJoCo solver's CPU path by Senua AI's
noslip patch, and the MuJoCo solver's part of issue 6 with it; issue 24's reported faults are not there on Newton
1.7.0; issue 16 is fixed and validated on Featherstone by Senua AI's limit patch, its first form. Registered 20
October 2026 ([`PREREGISTRATION_11.md`](../../preregistrations/PREREGISTRATION_11.md)); played once as
[run 072](../../validation/run_072_study_11/README.md).

## How it got here

| Run | What | Result |
|---|---|---|
| [013](../../validation/run_013_mujoco_solver_suite_elliptic/README.md) | The elliptic cone alone | A held cube creeps 765 um/s, as MuJoCo's C engine does |
| [066](../../validation/run_066_mujoco_cpu_path/README.md) | The CPU path beside the Warp path | 12 of 12: the same readings |
| [067](../../validation/run_067_mujoco_noslip/README.md), [069](../../validation/run_069_mujoco_noslip_v2/README.md) | The noslip patch, its two forms | The first never reached the C engine; the second holds the cube still |
| [068](../../validation/run_068_featherstone_limit/README.md), [070](../../validation/run_070_featherstone_limit_v3/README.md) | The Featherstone limit patch, its three forms | The first removes the pull; the implicit forms never diverge but rebound at large steps |

## The rules and the result

| Rule | Result |
|---|---|
| R1 safe when off (15): noslip unset gives the release's files | held |
| R2 the fault is there (15, 6): the elliptic cone alone creeps 100 um/s or more | held: 1,241 um/s at 1 and 4 ms |
| R3 held (15, 6): with noslip within 10 um/s of 0 | held: 0 at both steps |
| R4, R5 the slide and the weight kept, within 1 in 100 | held |
| R6 to R9 the CPU path (24): its contacts, forces and joint force give the Warp path's readings; every play a number | held |
| R10 safe when off (16) | held |
| R11 the fault is there (16): as released the arm turns back more than 0.01 rad below the closed form | held: 0.02 to 0.06 rad below |
| R12 kept from pulling (16): within 0.02 rad of the closed form | held: within 0.007 rad |

## What it decides

- **Issue 15, fixed and validated on the CPU path:** [`mujoco_noslip.diff`](../../patches/newton-1.7.0/mujoco_noslip.diff),
  `SolverMuJoCo(..., use_mujoco_cpu=True, cone="elliptic", noslip_iterations=5)`. On the Warp path it waits on MuJoCo
  Warp's noslip, which 3.15 does not implement.
- **Issue 6, the MuJoCo solver's part, fixed and validated** by the same configuration.
- **Issue 24, no departure found on 1.7.0:** the CPU path's contacts and forces are the Warp path's. It takes one world.
- **Issue 16, fixed and validated on Featherstone:**
  [`featherstone_limit.diff`](../../patches/newton-1.7.0/featherstone_limit.diff), `NEWTON_FEATHERSTONE_LIMIT=1`. Open on
  SemiImplicit.
