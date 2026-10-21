# Run 080: Study 13, played once

20 October 2026, 11:34 UTC, on the Newton host, by [`play.sh`](play.sh), under
[`PREREGISTRATION_13.md`](../../preregistrations/PREREGISTRATION_13.md), registered and pushed with the runner before
any play. The runner's dry run (`dry/`, throwaway parameters) ran to the end first; no rule was read from it. Played from
the record at its commit 13b55de, on Newton 1.7.0 and Study 12's engines. Measured by Senua AI's `sx_contact` (`final`)
and judged by its `rule` (`rules.txt`).

## The result: 16 of 16 rule lines held

| Rule | Measured | |
|---|---|---|
| R1 safe when off | 12 of 12 plays byte for byte the release's | held |
| R2 the fault is there (the drive) | As released the drive held at -7.6 rad turns at 100,521 and 12,566 urad/s (defaults) and 100,531 and 12,566 (the report's settings) after one step of 2 and 0.25 ms | held |
| R3 held past a full turn | With the patch its speed 0 to 5 urad/s after 1 and 1,200 steps, its reading (4,966,371 urad, the joint read through `eval_ik` at -7.6 + 4 pi) unchanged | held, 5 lines |
| R4 the fault is there (the D6) | As released the D6's first angle at the end: 1.022 and 0.558 rad (defaults, 1.5 s at 1 ms and 1 s at 0.5 ms), 1.044 and 0.564 rad (the report's settings) | held |
| R5 the D6 held | With the patch 0.200000 and 0.400000 rad, at both steps and settings | held, 8 lines |

## What it shows

**Issue 27 is fixed and validated on SemiImplicit** by Senua AI's joint patch, its angle half
(`NEWTON_SEMI_JOINT_ANGLE=1`): a drive holds its joint at rest past a full turn the negative way, where as released it
reads the joint two turns away and pulls it with 4 x 4 pi N m, and the two-axis D6 holds at its targets to the
microradian over 1 s and 1.5 s, where as released it drifts by 0.36 to 0.84 rad. With its switch unset Newton is the
release byte for byte. With Study 12's R1, R3 and R5, which held on other scenes, the fix holds at five steps from 2 to
0.25 ms.
