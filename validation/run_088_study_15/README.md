# Run 088: Study 15, played once

20 October 2026, 12:27 to 12:30 UTC, on the second x86-64 host, by [`play.sh`](play.sh), under
[`PREREGISTRATION_15.md`](../../preregistrations/PREREGISTRATION_15.md), registered and pushed with the runner before
any play. The runner's dry run (`dry/`, throwaway parameters) ran to the end first. Played from the record at its commit
92bcb54, on Newton 1.7.0 and the engines made by [`setup_engine.sh`](setup_engine.sh). Measured by Senua AI's
`sx_contact` (`creep`, `stop`; the suite's verdicts by the first deep dive's `sx_contact_suite.sh`) and judged by its
`rule` (`rules.txt`).

## The result: 6 of 6 rule lines held

| Rule | Measured | |
|---|---|---|
| R1 safe when off | The stacked tree with both switches unset: both holds byte for byte the release's | held |
| R2 the fault is there | As released and with the floor patch alone the hold creeps 3,415 um/s (3 ms) and 854 um/s (0.75 ms) | held |
| R3 held | With both patches 0 and 4 um/s | held |
| R4 the slide kept | With both: 53,216 and 54,123 um against 53,228 and 54,122 as released | held, both lines |
| R5 nothing lost | The suite 6 of 10 as released and with both, every passing verdict kept | held |

The slide against Coulomb's distance (0.8 m/s, friction 0.6: 54,422 um), reported: 2.2% short at 3 ms, 0.6% at 0.75
ms, with and without the patches alike.

## What it shows

**Issue 6 is fixed and validated on XPBD**: with its contact friction bounded by mu times the normal correction summed
over the step's iterations (Senua AI's friction patch), the speed floor removed (Study 10's patch) and 64 iterations for
its solve to converge, XPBD holds a cube pushed at 0.7 of what friction holds within 4 um/s, where as released, and with
the floor patch alone, it creeps 3,415 and 854 um/s; a slide is unchanged to 0.02%, and the suite loses no verdict.
The 64 iterations are a configuration: XPBD's solve converges as one over its iteration count (run 083), and without
the patch no count passes the floor (run 085).
