# Run 117: Study 23, played once

20 October 2026, 17:07 to 17:13 UTC, on the second x86-64 host, by [`play.sh`](play.sh), under
[`PREREGISTRATION_23.md`](../../preregistrations/PREREGISTRATION_23.md), registered and pushed with the runner before
any play. The runner's dry run (`dry/`, throwaway parameters) ran to the end first, and its rules section was run on
the dry run's lines to check it ran to the end too (not recorded). Played from the record at its commit b1e68eb, on
Newton 1.7.0 and the engine made by [`setup_engine.sh`](setup_engine.sh) (Senua AI's VBD displacement patch,
[`vbd_displacement_on_1.7.0.diff`](../../patches/in_design/vbd_displacement_on_1.7.0.diff)). Read by Senua AI's
`sx_contact` (`creep`, `stop`) and judged by its `rule` (`rules.txt`).

## The result: 7 of 7 rule lines held

| Rule | Measured | |
|---|---|---|
| R1 safe when off | 16 of 16 plays off byte for byte the release's | held |
| R2 the fault is there | As released the spinning body's centre at 8,249 um/s at 0.06 ms on VBD-ALM (and on VBD) | held |
| R3 the centre still | With the patch 0 um/s at every step on VBD and VBD-ALM | held |
| R4 the slides settle | With the patch the first slide 165,018 and 165,123 um at 0.24 and 0.06 ms against 165,141 at 0.03 ms; the second 54,228 and 54,306 against 54,319 | held, 2 lines |
| R5 the hold kept | 0 and 0 um/s with the contact history | held |
| R6 a number | Every play a number throughout | held |

| | 1.2 ms | 0.24 ms | 0.06 ms | 0.03 ms |
|---|---|---|---|---|
| Spinning body's centre, as released (VBD and VBD-ALM alike) | 13 | -3 | 8,249 um/s | |
| With the patch | 0 | 0 | 0 | |
| First slide (0.8 kg, 1.0 m/s, friction 0.4), as released | 164,439 | 164,602 | 154,957 | 511,230 um |
| With the patch | 164,432 | 165,018 | 165,123 | 165,141 |
| Second slide (1.5 kg, 0.6 m/s, friction 0.55), as released | 53,817 | 54,109 | 55,376 | 59,887 |
| With the patch | 53,816 | 54,228 | 54,306 | 54,319 |

## What it shows

**Issue 13 is fixed and validated on VBD-ALM and on VBD** by Senua AI's VBD displacement patch: a body spinning about
a centre of mass off its origin keeps that centre still at every step, where as released it drifts at 8.2 mm/s at
0.06 ms, and the slides and the hold keep their play, the slides settling as the step shrinks (within 0.1% from
0.24 ms down), where as released the first slides 3.1 times as far at 0.03 ms, its friction lost (F2). With Study 9
on the MuJoCo solver, issue 13 is resolved.
