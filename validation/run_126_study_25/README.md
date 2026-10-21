# Run 126: Study 25, played once

20 October 2026, 18:45 to 18:46 UTC, on the second x86-64 host, by [`play.sh`](play.sh), under
[`PREREGISTRATION_25.md`](../../preregistrations/PREREGISTRATION_25.md), registered and pushed with the runner before
any play. The runner's dry run (`dry/`, throwaway parameters) ran to the end first, and its rules section was run on
the dry run's lines to check it ran to the end too (not recorded). Played from the record at its commit d56d887, on
Newton 1.7.0 and the engine made by [`setup_engine.sh`](setup_engine.sh) (the record's Newton noslip patch and Senua
AI's MuJoCo Warp noslip patch, [`mujoco_warp_noslip_on_3.15.0.diff`](../../patches/in_design/mujoco_warp_noslip_on_3.15.0.diff)).
Read by Senua AI's `sx_contact` (`creep`, `stop`, `rest`) and judged by its `rule` (`rules.txt`).

## The result: 14 of 14 rule lines held

| Rule | Measured | |
|---|---|---|
| R1 safe when off | 6 of 6 Warp-path plays off byte for byte the release's | held |
| R2 the fault is there | As released the Warp path's hold creeps at 1,337 um/s at 2 and at 0.5 ms | held |
| R3 held | With noslip the Warp path's hold at 0 um/s at both steps | held |
| R4 as MuJoCo's C engine | The Warp path with noslip as the CPU path at both steps: the hold 0 and 0 um/s; the slide 122,621 and 123,419 um, the CPU path's to the micrometre; the weight 13,720 mN each | held, 6 lines |
| R5 the other plays kept | The slide with noslip 122,621 and 123,419 um against 122,628 and 123,427 off; the weight 13,720 mN each | held, 4 lines |
| R6 a number | Every play a number throughout | held |

| | as released (Warp) | off (Warp) | off (CPU) | noslip (Warp) | noslip (CPU) |
|---|---|---|---|---|---|
| Hold, 2 / 0.5 ms | 1,337 / 1,337 um/s | 1,337 / 1,337 | 1,337 / 1,337 | **0 / 0** | 0 / 0 |
| Slide | 122,628 / 123,427 um | the same | the same | 122,621 / 123,419 | 122,621 / 123,419 |
| Drop, the weight | 13,720 / 13,720 mN | the same | the same | 13,720 / 13,720 | 13,720 / 13,720 |

## What it shows

**Issue 15 is fixed and validated on the MuJoCo solver's Warp path** by Senua AI's MuJoCo Warp noslip patch with the
record's Newton noslip patch: MuJoCo's recommended configuration, its elliptic cone with the noslip solver, can be set
on the Warp path and holds a load still there, where as released the Warp path refuses noslip and the load creeps at
1.3 mm/s; the slide and the weight are MuJoCo's C engine's to the micrometre and the millinewton, and with noslip
unset every play is the release's byte for byte. With Study 11 on the CPU path, issue 15 is resolved.
