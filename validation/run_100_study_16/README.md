# Run 100: Study 16, played once

20 October 2026, 13:55 to 14:00 UTC, on the Newton host, by [`play.sh`](play.sh), under
[`PREREGISTRATION_16.md`](../../preregistrations/PREREGISTRATION_16.md), registered and pushed with the runner before
any play. The runner's dry run (`dry/`, throwaway parameters) ran to the end first. Played from the record at its commit
690b893, on Newton 1.7.0 and the engine made by [`setup_engine.sh`](setup_engine.sh). Measured by Senua AI's
`sx_contact` (`chain`, `gap`; the suite's verdicts by the first deep dive's `sx_contact_suite.sh`) and judged by its
`rule` (`rules.txt`).

## The result: 9 of 9 rule lines held

| Rule | Measured | |
|---|---|---|
| R1 safe when off | With the switch unset all 7 F and W plays byte for byte the release's | held |
| R2 the fault is there | As released F's energy departs 9,934, 5,000, 1,675 and 416 ppm at 6, 3, 1 and 0.25 ms | held |
| R3 the free chain kept | With RK4 F's energy within 2, 1, 3 and 7 ppm; its angular momentum within 0, 0, 0 and 2 ppm | held, both lines |
| R4 the swinging chain kept | With RK4 W's energy within 3 and 7 ppm at 2 and 0.5 ms, 20 ppm at 5 ms | held, both lines |
| R5 a number | Every RK4 play a number throughout | held |
| R6 nothing lost | Every suite verdict that passes as released, T01 and T08 aside, passes with RK4 (T03, T09); RK4 also passes T04 | held |
| R7 T01 and T08 no worse | At each of the six halvings RK4's gap is below the release's: the free fall's 88 to 6,285 um against 1,237,356 to 37,935, the chain's 288,007 to 543 against 7,734,224 to 20,620 | held |

Reported: the swinging chain as released departs 58,886, 23,606 and 6,029 ppm at 5, 2 and 0.5 ms; the suite passes 4
of 10 as released (T01, T03, T08, T09) and 3 with RK4 (T03, T04, T09), T01 and T08 failing it for the reasons R7 was
written for: RK4's free fall is exact and its gaps rounding (the largest difference 2 um), its chain falls at every
halving but the fourth.

## What it shows

**Issue 11 is fixed and validated on Featherstone**: with its step made as the classic fourth-order Runge-Kutta scheme
(Senua AI's patch, each stage's accelerations Featherstone's own), a chain with nothing acting on it keeps its energy
within 7 ppm and its angular momentum within 2 ppm at every step from 6 to 0.25 ms, where as released it gains 0.04% to
1%, and a chain swinging under gravity keeps its total energy within 20 ppm at 5 ms and 7 ppm at 0.5 ms, where as
released it departs 0.6% to 5.9%. With the switch unset nothing changes.
