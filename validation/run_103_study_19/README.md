# Run 103: Study 19, played once

20 October 2026, 14:23 to 14:24 UTC, on the Newton host, by [`play.sh`](play.sh), under
[`PREREGISTRATION_19.md`](../../preregistrations/PREREGISTRATION_19.md), registered and pushed with the runner before
any play. The runner's dry run (`dry/`, throwaway parameters) ran to the end first. Played from the record at its commit
855fa41, on Newton 1.7.0 as released. Measured by Senua AI's `sx_contact` (`creep`, `stop`) and judged by its `rule`
(`rules.txt`).

## The result: 4 of 4 rule lines held

| Rule | Measured | |
|---|---|---|
| R1 the fault is there | Cold, the hold creeps 20,352, 99,763 and 353,588 um/s at 2.5, 0.6 and 0.15 ms | held |
| R2 held | Carried, 0, 0 and 1 um/s | held |
| R3 the slide no further from the right answer | Carried 70,724, 68,738 and 49,297 um against cold 71,822, 84,636 and 102,901, Coulomb's 45,455: nearer it by 1,098, 15,898 and 53,604 um | held |
| R4 a number | Every play a number | held |

Reported: cold, VBD's slide runs 58%, 86% and 126% past Coulomb's distance, longer as the step shrinks (F2); carried,
56%, 51% and 8.5% past it. No cube turned more than 20.5 mrad.

## What it shows

**Issue 6 is fixed and validated on VBD's legacy path** by Newton's own configuration: with its contact history and
the collision pipeline's sticky contact matching, `SolverVBD` with its defaults holds a cube pushed at 0.75 of what
friction holds within 1 um/s at every step from 2.5 to 0.15 ms, where cold it creeps up to 354 mm/s, and its slide comes
nearer Coulomb's distance at every step. With Study 17 on VBD-ALM, issue 6 is fixed on VBD. VBD's slide stays past
Coulomb's distance, by more at the larger steps, on both paths: a finding of its own, not this study's.
