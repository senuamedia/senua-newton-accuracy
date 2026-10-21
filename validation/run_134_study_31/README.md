# Run 134: Study 31, the implicit MPM solver's thin colliders kept whole by a margin (issue 21, #4712's leak)

The thirty-first registered study ([`PREREGISTRATION_31.md`](../../preregistrations/PREREGISTRATION_31.md)), played once
with [`play.sh`](play.sh) on Newton 1.7.0 as released, no patch: the cup of #4712 (walls 4 mm thick) at voxel sizes of 8
and 12 mm and 8 and 32 substeps, its colliders' margin (`ShapeConfig.margin`, which the solver takes as their thickness)
0, a quarter voxel and half a voxel.

## What it found

Played 20 October 2026 (UTC) on the Newton host (`started.txt`, `finished.txt`); the measured lines in `measured.txt`,
the rules in [`rules.txt`](rules.txt). **3 of 4 rule lines held; R2 failed.**

| Particles outside the walls after 1 s | voxel 8 mm, 8 substeps | 8 mm, 32 | 12 mm, 8 | 12 mm, 32 |
|---|---|---|---|---|
| No margin (as released) | 731 | 169 | 466 | 104 |
| A quarter voxel (2 and 3 mm) | **54** | **5** | 0 | 0 |
| Half a voxel (4 and 6 mm) | 0 | 0 | 0 | 0 |

- R1 held: with no margin the liquid leaves at every voxel size and step. **R2 failed: a quarter voxel, 2 mm at the 8
  mm voxel, lets 54 and 5 particles out** (run 120's 2.5 mm at a 10 mm voxel kept them all). R3 held: half a voxel keeps
  every particle in at every voxel size and step. R4 held.
- By the registration the leak stays open; half a voxel, which held here, is registered next (Study 32).
