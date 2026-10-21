# Run 124: #4712's slab on its slope, with the implicit MPM solver's word-valued options (issue 21)

Not registered: a design probe, its predictions pushed with [`play.sh`](play.sh) before any play. Newton 1.7.0 from PyPI
as released, by the rig [`tools/nwt_mpm_collider.py`](../../tools/nwt_mpm_collider.py), which takes a word as an
option's value since run 122.

## Why

Run 122 found that the slab's slide at the smaller step is not the rheology solve's convergence (its tolerance and
iterations move it by under 1%), and its four word-valued options did not play (the rig's fault). This probe plays
them, with two more of the solver's own options that bear on the grid's momentum: the collider sampled on the Q1 basis
(the grid's corners) in place of S2; GIMP integration; PIC transfers in place of APIC; the collider's velocity read
backward; no numerical air drag (default 1.0); no warm start. And the defaults at 16 substeps, between run 122's 8 and
32. All at half a voxel's margin (25 mm), at 8 and 32 substeps.

## Predictions (pushed before the plays)

| Check | Prediction |
|---|---|
| C0 | Every play a number |
| P1 | At the defaults the slab slides 1 cm or more at 16 substeps |
| P2 | Reported per option: whether the slab slides less than 1 cm at both 8 and 32 substeps (a check each, not a prediction that any option does) |

Reported: every reading.

## What it found

Played 20 October 2026 on the Newton host (`started.txt`, `finished.txt`); the measured lines in `measured.txt`, the
checks in [`checks.txt`](checks.txt). **1 of 8 checks held.**

| The slab at half a voxel's margin | 8 substeps | 16 substeps | 32 substeps |
|---|---|---|---|
| The solver's defaults (run 122 at 8 and 32) | 21.4 mm, then still | 210 mm, moving | 282 mm, moving |
| Collider basis Q1 | 97 mm, moving | | 281 mm, moving |
| GIMP integration | 14.9 mm, then still | | 262 mm, moving |
| PIC transfers | 13.8 mm, then still | | 109 mm, moving |
| Collider velocity read backward | 21.4 mm, then still | | 282 mm, moving |
| No air drag | 21.4 mm, then still | | 207 mm, stopped being a number at step 632 |
| No warm start | 21.3 mm, then still | | 288 mm, moving |

- C0 failed: with no air drag at 32 substeps the play stopped being a number at step 632 of its 768 (at
  0.82 s), its reading taken over the steps it played. P1 held: at 16 substeps the slab slides 210 mm. P2 failed for
  every option.
- **No option of the solver's own holds the slab at the smaller step**: at 32 substeps it slides 109 to 288 mm with each
  of them, where at 8 it holds after 14 to 21 mm with all but the Q1 basis (97 mm, moving). The fall of the slope's
  friction as the step shrinks is in the solver's contact, not in an option: #4712's slope is a fix to make in the
  collider's friction, which run 120's margin alone does not make.
