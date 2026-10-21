# Study 25: MuJoCo's recommended configuration on the MuJoCo solver's Warp path

**Outcome: 14 of 14 rule lines held; issue 15 fixed and validated on the Warp path** by Senua AI's MuJoCo Warp noslip
patch with the record's Newton noslip patch, and with Study 11 on the CPU path, issue 15 resolved. Registered 21
October 2026 ([`PREREGISTRATION_25.md`](../../preregistrations/PREREGISTRATION_25.md)); played once as
[run 126](../../validation/run_126_study_25/README.md).

## How it got here

| Run | What | Result |
|---|---|---|
| [067](../../validation/run_067_mujoco_noslip/README.md), [069](../../validation/run_069_mujoco_noslip_v2/README.md), Study 11 | Noslip through Newton | Fixed on the CPU path, where MuJoCo's C engine runs it; MuJoCo Warp 3.15 refuses it |
| (upstream) | MuJoCo Warp's noslip request | Closed as not planned |
| [123](../../validation/run_123_mujoco_warp_noslip/README.md) | MuJoCo's noslip solver ported into MuJoCo Warp | The Warp path holds the cube still and plays as MuJoCo's C engine to the micrometre, elliptic and pyramidal |

## The rules and the result

| Rule | Result |
|---|---|
| R1 safe when off | held: 6 of 6 plays byte for byte |
| R2 the fault is there as released | held: 1,337 um/s at both steps |
| R3 held | held: 0 um/s at both steps |
| R4 as MuJoCo's C engine | held, 6 lines: the hold, the slide and the weight the CPU path's |
| R5 the other plays kept | held, 4 lines |
| R6 a number | held |

## What it decides

**Issue 15, fixed and validated on the Warp path:** [`noslip.diff`](../../patches/mujoco-warp-3.15.0/noslip.diff) to
MuJoCo Warp 3.15.0, with [`mujoco_noslip.diff`](../../patches/newton-1.7.0/mujoco_noslip.diff) to Newton:
`SolverMuJoCo(..., cone="elliptic", noslip_iterations=5)`. With Study 11 on the CPU path, issue 15 is resolved.
