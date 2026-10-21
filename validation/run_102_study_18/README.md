# Run 102: Study 18, played once

20 October 2026, 14:18 to 14:29 UTC, on the second x86-64 host, by [`play.sh`](play.sh), under
[`PREREGISTRATION_18.md`](../../preregistrations/PREREGISTRATION_18.md), registered and pushed with the runner before
any play. The runner's dry run (`dry/`, throwaway parameters) ran to the end first. Played from the record at its commit
10a624c, on Newton 1.7.0 and the engine made by [`setup_engine.sh`](setup_engine.sh). Measured by Senua AI's
`sx_contact` (`creep`, `stop`; the suite's verdicts by the first deep dive's `sx_contact_suite.sh`) and judged by its
`rule` (`rules.txt`).

## The result: 19 of 19 rule lines held

| Rule | SemiImplicit | Featherstone | |
|---|---|---|---|
| R1 safe when off | 16 of 16 plays on both solvers byte for byte the release's | | held |
| R2 the fault is there | As released the hold creeps 368,204, 634 and 412 um/s at 1.5, 0.4 and 0.1 ms | 785,373, 783 and 412 um/s | held, both |
| R3 held | On, 0, 0 and 0 um/s | 0, 0 and 0 um/s | held, both |
| R4 issue 9's scene held | On, 1 and 1 um/s at 2 and 1.6 ms, turned 5.98 and 5.94 mrad | 0 and 0 um/s, 5.98 and 5.94 mrad | held, 4 lines |
| R5 Coulomb's slide | On, 81,267, 81,706 and 81,826 um for 81,633 | 81,269, 81,707 and 81,827 um | held, both |
| R6 Coulomb at impact | On, T05 3,999 to 4,000 and T10 3,999 from the suite's 1/2 step | T05 3,970 to 3,998 and T10 3,981 to 3,999 from its 1/4 step | held, 4 lines |
| R7 nothing lost | Every verdict passing as released passes on | the same | held, both |
| R8 a number | Every play on a number | the same | held, both |

Reported: as released, issue 9's small cube at its 2 ms step is thrown at 1,387,885 um/s on SemiImplicit and 1,064,993
um/s on Featherstone (397,387 and 434,703 at 1.6 ms), and the hold at 1.5 ms creeps 368 and 785 mm/s, both past the
explicit friction's limit; the slide as released runs 4.7 and 4.5 times Coulomb's distance at 1.5 ms and stops at 34%
and 37% of it at 0.4 ms, 29% at 0.1 ms. The suite passes 7 of 10 on SemiImplicit with the patches (4 as released): T02,
T05 and T10 now pass; on Featherstone 5 of 10 (4 as released): T10 passes, T05 is within 1 in 100 from the 1/4 step
but 3,792 at 1/2, and steady sliding (T02) is 4,000 at 1/16 and 4,146 at 10 ms, the suite's step past the normal
contact's limit, where T04, T06 and T07 fail as released and on alike.

## What it shows

**Issue 6 is fixed and validated on SemiImplicit and Featherstone, and issue 9 on both.** With their contact friction
taken out of the force pass and applied after the step's integration as the impulse that stops each contact's slip,
its total over the step within Coulomb's cone, the pass made 64 times a step (Senua AI's Coulomb friction patches, on
its contact damping patch), a cube pushed at 0.7 of what friction holds is still at every step, issue 9's small cube is
held at its own 2 ms step where as released it is thrown, a slide stops within 0.45% of Coulomb's distance at every
step where as released it is 4.7 times too long or a third of it, and the suite loses nothing. With Studies 11, 15, 17
and 19 issue 6 is fixed on every solver; with Study 9 issue 9 is fixed in both its parts.
