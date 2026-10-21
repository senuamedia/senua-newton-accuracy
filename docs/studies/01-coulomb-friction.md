# Study 1: Coulomb's friction for SemiImplicit and Featherstone

| | |
|---|---|
| Question | Does Newton as released still give friction above Coulomb's on scenes the probes did not use, and does the unit friction direction give Coulomb's, whatever the smoothing, with nothing else changed and Newton unchanged when it is off? |
| Outcome | **11 of 11 rule lines held.** The patch is validated |
| Registered | [`PREREGISTRATION_01.md`](../../preregistrations/PREREGISTRATION_01.md), 15 October 2026, pushed before any play |
| Played | Once, as [run 008](../../validation/run_008_study_01/README.md), 15 October 2026 01:20 UTC, on Linux (EC2 c7i.xlarge), Warp's CPU device, at 0.25 ms |
| Arms | Newton 1.6.1 from PyPI; the patched source with the switch unset; with it set |
| Measured by | The Senua AI Robotics Core's measuring programs (`stop`, `accel`, `impact`), judged by their `rule` command |

## The scenes

None of these numbers used in the probes: a cube of 0.8 kg, half-size 0.045 m, friction 0.45, set sliding at 1.3 m/s
(Coulomb's distance 191,610 um); a plate of 0.6 kg, 12 cm square, friction 0.3, kicked from rest to 0.7 m/s, at
smoothing widths 1.0 and 0.05 (Coulomb's 83,333 um); the cube landing from 40 mm at 1.5 m/s, friction 0.25 (Coulomb's
2,500 per 10,000); the cube set down and dropped; and the slide on XPBD and the MuJoCo solver.

## The result

| Rule | Measured | |
|---|---|---|
| R1 safe when off | 28 of 28 files byte-identical | held |
| R2 the defect is there | Released: the slide 84,061 um, the plate decelerating at 15,198 mm/s2 (5.2 times Coulomb's) | held |
| R3 the slide | Patched: the cube 191,783 um, the plate 83,230 um at both widths | held |
| R4 the impact | Patched: 2,500 per 10,000 | held |
| R5 the width does not matter | Patched: the plate's files identical at both widths | held |
| R6 no tipping | Patched: at most 7,994 urad, against 327,354 and 330,993 released | held |
| R7 nothing else changes | 6 of 6 files byte-identical | held |
| R8 nothing blows up | No play's state stopped being a number | held |
