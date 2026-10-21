# Run 101: Study 17, played once

20 October 2026, 14:02 to 14:06 UTC, on the Newton host, by [`play.sh`](play.sh), under
[`PREREGISTRATION_17.md`](../../preregistrations/PREREGISTRATION_17.md), registered and pushed with the runner before
any play. The runner's dry run (`dry/`, throwaway parameters) ran to the end first. Played from the record at its commit
791f0be, on Newton 1.7.0 as released. Measured by Senua AI's `sx_contact` (`creep`, `stop`) and judged by its `rule`
(`rules.txt`).

## The result: 8 of 11 rule lines held

| Rule | Measured | |
|---|---|---|
| R1 the fault is there | Cold, VBD's hold creeps 24,971, 133,865 and 400,648 um/s at 1.5, 0.3 and 0.08 ms; VBD-ALM's 308 um/s at 0.08 ms | held, both lines |
| R2 held | Carried, VBD's and VBD-ALM's holds 0, 0 and 0 um/s | held, both lines |
| R3 the slide kept | VBD-ALM's carried slide within 1 in 100 of its cold slide at every step (124,665 against 124,666 um at 1.5 ms); VBD's is not, at any step: 138,500, 96,788 and 93,308 um against 140,751, 154,235 and 208,432 | VBD-ALM held, 3 lines; **VBD failed**, 3 lines |
| R4 a number | Every play a number | held |

Reported: Coulomb's distance for the slide, v^2 / (2 mu g), is 91,837 um. Cold, VBD's slide runs 53%, 68% and 127% past
it at 1.5, 0.3 and 0.08 ms, longer as the step shrinks (VBD's slide loses its friction as the step shrinks, F2);
carried, 51%, 5.4% and 1.6% past it. VBD-ALM's slide runs 33% to 36% past it, cold and carried alike (run 098's
finding). No cube turned more than 22.5 mrad.

## What it shows

**Issue 6 is fixed and validated on VBD-ALM** by Newton's own configuration: with its contact history and the
collision pipeline's sticky contact matching, VBD-ALM holds a cube pushed at 0.65 of what friction holds still at every
step from 1.5 to 0.08 ms, where cold it creeps 308 um/s at 0.08 ms, and its slide is unchanged.

**On VBD's legacy path, the default in 1.7.0, the hold is held too**, still at every step where cold it creeps up to
401 mm/s, but R3 failed: carrying the contacts changes VBD's slide. It changes it toward the right answer: the cold
slide, which R3 took as the reference, is itself wrong, by more as the step shrinks, and the carried slide is nearer
Coulomb's distance at every step, within 1.6% at 0.08 ms. R3 as registered asked the wrong question of this path; the
part stays open, for a registration that judges the slide against Coulomb's distance.
