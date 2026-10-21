# Study 12: SemiImplicit's joint angle, and Featherstone's limit integrated implicitly

**Outcome: 20 of 21 rule lines held; R4 failed.** Issue 28 is fixed and validated on Featherstone by Senua AI's limit
patch, its third form. Issue 27's fix, Senua AI's SemiImplicit joint patch, held every one of its rules, but the
registered fault rule for the D6 (R4) failed at 0.5 ms, so by the registration issue 27 stays open. Registered 20
October 2026 ([`PREREGISTRATION_12.md`](../../preregistrations/PREREGISTRATION_12.md)); played once as
[run 078](../../validation/run_078_study_12/README.md).

## How it got here

| Run | What | Result |
|---|---|---|
| [055](../../validation/run_055_featherstone_limit_light_link/README.md) | Featherstone's limit on a light link | The explicit bound, microseconds (F20) |
| [068](../../validation/run_068_featherstone_limit/README.md), [070](../../validation/run_070_featherstone_limit_v3/README.md), [076](../../validation/run_076_featherstone_limit_chain/README.md) | The limit integrated implicitly, three forms; a serial arm | The third holds a light arm and a serial arm at rest on the limit at every step |
| [062](../../validation/run_062_rest_reports_scenes/README.md), [077](../../validation/run_077_semi_joint/README.md) | Issue 27's report scenes; the SemiImplicit joint patch | The drive past a full turn and the D6 held exactly |

## The rules and the result

| Rule | Result |
|---|---|
| R1 safe when off (27) | held: 12 of 12 |
| R2 the fault is there (27): the drive at 8.1 rad turns at 10,000 urad/s or more after one step | held: 18,849 to 37,699 |
| R3 held past a full turn (27) | held: 0 or -1 urad/s, the reading unchanged |
| R4 the fault is there (27): the D6's first angle at 0.25 rad or more after 600 steps | **failed** at 0.5 ms: 0.2495 and 0.2498 rad (1.08 and 1.10 at 2 ms) |
| R5 the D6 held (27) | held: 0.200000 and 0.400000 rad |
| R6 safe when off (28) | held: 8 of 8 |
| R7 the fault is there (28): the light and serial arms stop being a number at every step | held |
| R8 a number (28): at `=3` every play | held |
| R9 at rest on the limit (28): within 1 in 100 of -0.6 rad, within 10,000 urad/s of still | held: within 2 urad, -28 to 560 urad/s |

## What it decides

- **Issue 28, fixed and validated:** [`featherstone_limit.diff`](../../patches/newton-1.7.0/featherstone_limit.diff),
  `NEWTON_FEATHERSTONE_LIMIT=3` (with `use_tile_gemm=False`, Featherstone's default).
- **Issue 27 stays open:** its fix held all its rules, the fault's rule for the D6 did not hold at the smaller step; a
  thirteenth study sizes it from this run's drift.
