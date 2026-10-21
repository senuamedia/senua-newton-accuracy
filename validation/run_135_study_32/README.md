# Run 135: Study 32, the implicit MPM solver's thin colliders kept whole by a margin of half a voxel (issue 21, #4712's leak)

The thirty-second registered study ([`PREREGISTRATION_32.md`](../../preregistrations/PREREGISTRATION_32.md)), played once
with [`play.sh`](play.sh) on Newton 1.7.0 as released, no patch: the cup of #4712 (walls 4 mm thick) at voxel sizes of 7
and 14 mm and 12 and 24 substeps, its colliders' margin (`ShapeConfig.margin`, which the solver takes as their
thickness) 0 and half a voxel, and a quarter voxel reported. After Study 31, whose quarter-voxel rule failed at an 8 mm
voxel and whose half-voxel rule held.

## What it found

Played 20 October 2026 (UTC) on the Newton host (`started.txt`, `finished.txt`); the measured lines in `measured.txt`,
the rules in [`rules.txt`](rules.txt). **2 of 3 rule lines held; R2 failed.**

| Particles outside the walls after 1 s | voxel 7 mm, 12 substeps | 7 mm, 24 | 14 mm, 12 | 14 mm, 24 |
|---|---|---|---|---|
| No margin (as released) | 134 | 68 | 706 | 219 |
| Half a voxel (3.5 and 7 mm) | 0 | 0 | **9** | 0 |
| A quarter voxel (reported) | 9 | 4 | 31 | 2 |

- R1 held: with no margin the liquid leaves at every voxel size and step. **R2 failed: at the 14 mm voxel and 12
  substeps half a voxel lets 9 particles out**, the first at step 8 (the liquid's first splash against the walls), the
  count rising to 9 by the end; at 24 substeps none. R3 held.
- With Study 31: a margin closes the leak at most settings and more of it as the margin grows (a quarter voxel 0 to 54
  out, half a voxel 0 to 9), but not at a coarse voxel with a large step: what crosses a wall depends on how far a step
  carries a particle against the wall's collider thickness, not on the margin alone. #4712's leak stays open; a margin
  is not the fix.
- After the run (21 October 2026, the arm64 host, not registered; counts read from the play files' last line): at the 14
  mm voxel and 12 substeps, the solver's own options change the leak and close it under none (no margin: 706 by
  default, 314 with PIC transfers, 849 GIMP, 1,843 with the Q1 collider basis, 676 without warm start, 693 at 1,000
  iterations; half a voxel: 9 by default, 3 GIMP, 4 PIC, 5 without warm start, 1 at 1,000 and at 4,000 iterations, 9 at
  4,000 iterations and a 1e-6 tolerance); half a voxel at 1,000 iterations keeps the cup whole at 7, 8 and 12 mm and at
  14 mm with 24 substeps. The count moves with the solve's settings without falling as the solve converges: the leak
  is not the solve stopping short.
- And a fix in design (the arm64 host, 21 October 2026, not registered): Senua AI's swept projection
  ([`mpm_swept_projection_on_1.7.0.diff`](../../patches/in_design/mpm_swept_projection_on_1.7.0.diff), switch
  `NEWTON_MPM_SWEPT_PROJECTION=1`) tests each particle's step from its start against the collider seen from there, so a
  particle a step carries past a wall it set out outside of is stopped at that wall; only the step's end was tested.
  On this study's grid, from one environment: with the switch unset every count is this study's (no margin 134, 68,
  706 and 219; half a voxel 0, 0, 9 and 0; a quarter 9, 4, 31 and 2: safe when off); set, no margin 102, 58, 459 and
  210, half a voxel 0, 0, 3 and 0, a quarter 7, 5, 25 and 2. It narrows the leak and closes it nowhere it was open;
  #4712's other scene, the slab on the slope, plays byte for byte with it unset and set (8 and 32 substeps, margins
  of 25 and 50 mm). What a step carries across a wall is part of the leak, not all of it. Not registered.
