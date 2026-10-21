# Run 120: the implicit MPM solver's colliders, as released (issue 21, #4712)

Not registered: a design probe, its predictions pushed with [`play.sh`](play.sh) before any play. Newton 1.7.0 from PyPI
as released, by a rig new at this run, [`tools/nwt_mpm_collider.py`](../../tools/nwt_mpm_collider.py).

## Why

Issue 21's second report, newton-physics/newton #4712 (on 1.6.0, on a GPU): `SolverImplicitMPM` takes a collider's
thickness from its shapes' margin, Newton's default 0, so liquid leaks through a cup's walls thinner than a voxel, and
a cohesive slab on a 60 degree slope with friction 3, which Coulomb's law holds (tan 60 = 1.73 < 3), slides 0.84 m in
1 s; a margin of half a voxel keeps the liquid in, and of a voxel the slab slides 0.13 m. In 1.7.0's source the
solver's own default thickness is 1% of a voxel (`_DEFAULT_THICKNESS`), but a shape's margin, 0 by default, replaces
it. The rig plays #4712's two scenes as its script builds them, on the CPU, writing the slab's mean travel down the
slope (read by Senua AI's `stop`, its distance slid and its largest speed over the last third) and the cup's count of
particles outside its walls (read by `final`, its first column at the last step).

## Predictions (pushed before the plays)

| Check | Prediction |
|---|---|
| C0 | Every play a number |
| P1 | The slab at no margin slides 0.5 m or more in 1 s |
| P2 | The slab slides 1 cm or more at every margin up to a voxel, at 8 and at 32 substeps: a thickness alone does not hold it |
| P3 | The cup at no margin loses 100 particles or more through its walls |
| P4 | The cup at a margin of half a voxel (5 mm) loses none |

Reported: every reading.

## What it found

Played 20 October 2026 on the second x86-64 host (`started.txt`, `finished.txt`); the measured lines in `measured.txt`,
the checks in [`checks.txt`](checks.txt). **4 of 5 checks held; P2 failed.**

| Check | Result |
|---|---|
| C0 | Held: every play a number |
| P1 | Held: at no margin the slab slides 543 mm in 1 s, still moving at 1.1 m/s |
| P2 | Failed: at 8 substeps a margin of half a voxel holds the slab after 21 mm and a voxel's after 6 mm; but at 32 substeps a voxel's margin lets it slide 161 mm, still moving at 0.25 m/s |
| P3 | Held: at no margin 578 of the cup's 8,664 particles leave through its walls in 1 s |
| P4 | Held: at half a voxel (5 mm), none |

| The slab on the slope (friction 3, 60 degrees; Coulomb holds it) | 8 substeps | 32 substeps |
|---|---|---|
| No margin | 543 mm, moving at 1.13 m/s | 510 mm, moving at 0.95 m/s |
| 12.5 mm (a quarter voxel) | 287 mm, moving at 0.59 m/s | |
| 25 mm (half a voxel) | 21 mm, then still | |
| 50 mm (a voxel) | 6 mm, then still | 161 mm, moving at 0.25 m/s |

| The cup (walls 4 mm, voxel 10 mm) | 0 | 2.5 mm | 3 mm | 5 mm | 10 mm |
|---|---|---|---|---|---|
| Particles outside the walls after 1 s | 578 | 0 | 0 | 0 | 0 |

- **#4712's two departures are there on 1.7.0**, on the CPU as on its GPU: at Newton's default margin, liquid leaks
  through walls thinner than a voxel and the slab slides off a slope its friction should hold.
- **The leak is a thickness**: from a quarter of a voxel (2.5 mm), the cup's walls, 4 mm, keep every particle in. With
  the solver's default collider basis (S2), its nodes at the cells' corners and edges' midpoints, a node is held by a
  collider within a quarter of a voxel of its surface (half its basis's node spacing): at 2.5 mm the band a wall covers
  (its 4 mm, and a quarter voxel on each side) holds a layer of nodes across it.
- **The slope is not only a thickness**: at 8 substeps half a voxel holds it, but at 32 a whole voxel does not, so
  the step changes how much friction reaches the slab. The nodal friction itself is a Coulomb solve on each node's
  velocity, which holds friction 3 at 60 degrees at any step; run 122 tries the solver's own options for what the
  step changes.
