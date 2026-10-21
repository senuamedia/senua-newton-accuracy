# Run 119: Study 24, played once

20 October 2026, 17:53 to 18:00 UTC, on the second x86-64 host, by [`play.sh`](play.sh), under
[`PREREGISTRATION_24.md`](../../preregistrations/PREREGISTRATION_24.md), registered and pushed with the runner before
any play. The runner's dry run (`dry/`, throwaway parameters) ran to the end first, and its rules section was run on
the dry run's lines to check it ran to the end too (not recorded). Played from the record at its commit 03ccadb, on
Newton 1.7.0 and the engine made by [`setup_engine.sh`](setup_engine.sh) (Senua AI's VBD proxy coupling patch, its
third form, [`vbd_proxy_coupling_v3_on_1.7.0.diff`](../../patches/in_design/vbd_proxy_coupling_v3_on_1.7.0.diff)). Read
by Senua AI's `sx_contact` (`rest`, `stop`, `pairg`) on the rig's CONTACT files and judged by its `rule` (`rules.txt`).

## The result: 14 of 14 rule lines held

| Rule | Measured | |
|---|---|---|
| R1 safe when off | 10 of 10 plays off byte for byte the release's | held |
| R2 the fault is there | As released, the tall box's feedback 82,196 and 11,392 mN against the 590 the cloth receives (139 and 19 times); the throw's momentum at the end 10.9 and 3.5 times the cloth's at the start | held, 4 lines |
| R3 the feedback the cloth's force | At 2, the tall box one-way: 590 and 590 mN against the cloth's 590 | held, 2 lines |
| R4 the box at rest | At 2, the box under the cloth and the tall box two-way: 0, 1, 1 and 0 um/s over the last third | held |
| R5 momentum kept | At 2, the throw's momentum at the end within 1 in 430 and 1 in 2,900 of the cloth's at the start | held, 2 lines |
| R6 the held cloth | At 2, the box no faster than 27 and 131 mm/s over the last third, under its landing's 767; the feedback 3,977 and 3,945 mN against its weight, 3,983 | held, 3 lines |
| R7 a number | Every play a number throughout | held |

| | 15 / 50 iterations, as released | at 1, the rewind alone | at 2 |
|---|---|---|---|
| Cloth on a box, two-way: feedback (the cloth receives 590 to 595 mN) | -63,437 / -15,886 mN | -90,923 / -15,721 | -571 / -581 |
| The box's speed over the last third | 127,770 / 3,924 um/s | 171 / 89 | 0 / 1 |
| Tall box, one-way: feedback (the cloth receives 590) | -82,196 / -11,392 mN | the same | -590 / -590 |
| Tall box, two-way: the box's speed | 150,557 / 337 um/s | 45 / 20 | 1 / 0 |
| Throw: momentum at the end, times the cloth's at the start | 10.9 / 3.5 | 9.9 / 2.8 | 0.998 / 1.000 |
| Held cloth: the box's feedback over the second half (its weight 3,983 mN) | 0 / 0, through the cloth to the ground | 4,607 / 1,574, thrown at 1.2 and 2.4 m/s | 3,977 / 3,945 |

## What it shows

**#4698's two faults are fixed and validated on 1.7.0** by Senua AI's VBD proxy coupling patch at 2: the feedback VBD
hands the MuJoCo solver for a box is the force the light cloth exerts on it, where as released it is 19 to 139 times
too large; a box held by the ground under the cloth stays at rest, where as released it is shaken at up to 0.15 m/s; a
cloth thrown at a free box gives it the momentum it loses, where as released the pair gains 3.5 to 10.9 times what it
had; and a box dropped onto a held cloth is carried at its weight, where as released it goes through the cloth, and
with the rewind alone it is thrown. Issue 21 is fixed in its #4698 part; its other report, #4712, is its own question.
