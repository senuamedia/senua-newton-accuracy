# Run 128: Study 26, played once

20 October 2026, 19:14 to 19:16 UTC, on the second x86-64 host, by [`play.sh`](play.sh), under
[`PREREGISTRATION_26.md`](../../preregistrations/PREREGISTRATION_26.md), registered and pushed with the runner before
any play. The runner's dry run (`dry/`, throwaway parameters) ran to the end first, and its rules section was run on
the dry run's lines to check it ran to the end too (not recorded). Played from the record at its commit 6610b30, on
Newton 1.7.0 and the engine made by [`setup_engine.sh`](setup_engine.sh) (Senua AI's friction combination patch,
[`friction_combine_on_1.7.0.diff`](../../patches/in_design/friction_combine_on_1.7.0.diff)). Read by Senua AI's
`sx_contact` (`stop`) and judged by its `rule` (`rules.txt`).

## The result: 44 of 44 rule lines held

| Rule | Measured | |
|---|---|---|
| R1 safe when off | 40 of 40 mixed plays off byte for byte the release's | held |
| R2 the fault is there | As released, on pairing A, XPBD's mixed slide 58,990 um against its 43,202 at 0.75, VBD's 106,414 against 81,153: 37% and 31% longer | held |
| R3 one rule | With the switch, every solver's mixed slide, in both pairings and all four priorities, byte for byte its slide at the rule's coefficient | held, 40 lines |
| R4 the MuJoCo solver kept | 8 of 8 of its mixed plays with the switch byte for byte its plays as released | held |
| R5 a number | Every play a number throughout | held |

| Slide, um | one friction 0.35 / 0.75 / 0.6 / 0.15 | A (0.35, 0.75), as released | A, on: none, the cube's priority, the plane's | B (0.6, 0.15), as released | B, on: none, the cube's priority, the plane's |
|---|---|---|---|---|---|
| XPBD | 92,906 / 43,202 / 54,046 / 217,291 | 58,990 | 43,202 / 92,906 / 43,202 | 86,687 | 54,046 / 54,046 / 217,291 |
| SemiImplicit | 42,882 / 68,157 / 123,259 / 57,003 | 53,567 | 68,157 / 42,882 / 68,157 | 27,398 | 123,259 / 123,259 / 57,003 |
| Featherstone | 41,967 / 100,036 / 66,289 / 58,281 | 71,752 | 100,036 / 41,967 / 100,036 | 60,337 | 66,289 / 66,289 / 58,281 |
| VBD | 140,626 / 81,153 / 95,030 / 272,562 | 106,414 | 81,153 / 140,626 / 81,153 | 157,880 | 95,030 / 95,030 / 272,562 |
| The MuJoCo solver | 93,063 / 43,779 / 54,534 / 217,387 | 43,779 | 43,779 / 93,063 / 43,779 | 54,534 | 54,534 / 54,534 / 217,387 |

## What it shows

**Issue 18's combination part is fixed and validated** by Senua AI's friction combination patch: with
`NEWTON_FRICTION_COMBINE=1` every solver combines two shapes' frictions by MuJoCo's rule, the larger coefficient or the
higher-priority shape's, and honours MuJoCo's geom priority, so one model plays one friction whichever solver plays it;
as released XPBD, SemiImplicit and Featherstone take the mean, VBD the geometric mean, and only the MuJoCo solver reads
the priority. With the switch unset every play is the release's, and the MuJoCo solver's plays are unchanged by it.
Issue 18's other parts, a static coefficient and its import, are their own study.

- Reported, not ruled: SemiImplicit's and Featherstone's slides at one friction do not shorten as the friction grows
  (SemiImplicit's at 0.6 is 1.8 times its slide at 0.75): their explicit penalty friction, the departure of issues 1
  and 6, which Study 18's Coulomb friction patches fix and this patch leaves as it is.
