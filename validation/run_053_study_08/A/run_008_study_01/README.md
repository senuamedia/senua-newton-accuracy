# Run 008: the first registered study, played once

Played 15 October 2026 (01:20 UTC, `played_at.txt`) on run 001's machine, by [`play.sh`](play.sh), under
[`preregistrations/PREREGISTRATION_01.md`](../../preregistrations/PREREGISTRATION_01.md), pushed before any play.
Three arms (`stock/`, `off/`, `on/`): Newton 1.6.1 from PyPI, the patched source with the switch unset, and with
`NEWTON_UNIT_FRICTION_DIRECTION=1`; every play at 0.25 ms. Every number a rule reads is in `measured.txt`; every
rule's line, as `sx_contact rule` judged it, in `rules.txt`.

**The result: all 11 rule lines held.** The unit friction direction is validated on this registration's scenes.

| Rule | Numbers | |
|---|---|---|
| R1 safe when off | 28 of 28 files byte-identical to stock | held |
| R2 the defect is there | Stock: the cube's slide stops at 84,061 um (SemiImplicit) and 83,859 um (Featherstone), under 60% of Coulomb's 191,610; the plate decelerates at 15,198 and 15,210 mm/s2 from 260 to 300 ms, 5.2 times Coulomb's 2,940 | held |
| R3 the slide | On: the cube 191,783 um on both solvers (0.09% long); the plate 83,230 um at both widths on both (0.12% short) | held |
| R4 the impact | On: friction over the impact 2,500 per 10,000 on both, Coulomb's exactly | held |
| R5 the width does not matter | On: the plate's file at width 0.05 byte-identical to its file at 1.0, on each solver | held |
| R6 the cube does not tip | On: at most 7,994 urad, against 327,354 for stock | held |
| R7 nothing else changes | On: the set-down and the drop on both solvers, the slides on XPBD and the MuJoCo solver: 6 of 6 byte-identical to stock | held |
| R8 nothing blows up | No play's state stopped being a number | held |

Stock, for the record of the defect on these scenes: the plate stops at 19,374 um at the default width and at
2,943 um at a width of 0.05 (Coulomb's 83,333); the impact takes 4,381 per 10,000 for 2,500 (75% over).

The dry run (`dry/`, stock only, throwaway parameters) ran to the end and wrote every measured line; no rule was read
from it. Its plate was kicked at 0.3 s, after the 260 to 300 ms window, so its deceleration line reads 0 there; the
registered plate is kicked at 0.25 s.

## What it shows

On a cube, a plate, frictions, speeds and a step the probes did not use, Newton's SemiImplicit and Featherstone as
released give friction far above Coulomb's (a slide stops at 44% of its distance, a plate at 23%, or 3.5% with a
narrower smoothing; an impact takes 75% too much), and the patch gives Coulomb's friction on both, whatever the
smoothing width, with nothing else changed and Newton byte for byte as released when it is off.
