# Run 122: #4712's slab on its slope, with the implicit MPM solver's own options (issue 21)

Not registered: a design probe, its predictions pushed with [`play.sh`](play.sh) before any play. Newton 1.7.0 from PyPI
as released, by the rig [`tools/nwt_mpm_collider.py`](../../tools/nwt_mpm_collider.py).

## Why

Run 120: #4712's slab on a 60 degree slope with friction 3, which Coulomb's law holds, slides 0.54 m in 1 s at no
collider margin; at 8 substeps a margin of half a voxel (25 mm) holds it after 21 mm, but at 32 substeps even a voxel's
margin (50 mm) lets it slide 0.16 m, still moving at the end. The solver's nodal friction is a Coulomb solve on each
node's velocity, which holds friction 3 on 60 degrees at any step; what the step changes is elsewhere: in how far the
rheology solve converges, how the collider is sampled on the grid, how particles carry momentum to the grid, or how
the collider's velocity is read. This probe tries the solver's own options for each, at 8 and 32 substeps, at the
margin of half a voxel.

## Predictions (pushed before the plays)

| Check | Prediction |
|---|---|
| C0 | Every play a number; at the defaults and 8 substeps, run 120's file byte for byte |
| P1 | At the defaults the slab slides 1 cm or more at 32 substeps |
| P2 | Reported per option: whether the slab slides less than 1 cm at both 8 and 32 substeps (a check each, not a prediction that any option does) |

Reported: every reading.

## What it found

Played 20 October 2026 on the second x86-64 host (`started.txt`, `finished.txt`); the measured lines in `measured.txt`,
the checks in [`checks.txt`](checks.txt). **2 of 9 check lines held; two instrument faults.**

**Two instrument faults:**

- **The rig took an option's value as a number only**: `tools/nwt_mpm_collider.py` read `opt.collider_basis=Q1`,
  `opt.integration_scheme=gimp`, `opt.transfer_scheme=pic` and `opt.collider_velocity_mode=backward` as numbers and
  stopped at once (`could not convert string to float`, in each play's error stream), so those eight plays left no
  reading and their four check lines did not read (`rule: unknown kind`). The rig takes a word since this run; run 124
  plays them.
- **C0's comparison file was not in the host's copy of the record**: the runner compared the default play at 8
  substeps with run 120's file, which was committed after the host's copy was made; the check failed for that. The two
  files are the same, byte for byte (compared here, after the fetch).

| The slab at half a voxel's margin | 8 substeps | 32 substeps |
|---|---|---|
| The solver's defaults | 21.4 mm, then still | 282 mm, moving at 0.45 m/s |
| The rheology solve's tolerance 1e-6 | 20.9 mm, then still | 281 mm, moving |
| 1,000 iterations | 21.6 mm, then still | 280 mm, moving |

- P1 held: at 32 substeps the slab slides 282 mm (run 120 at a voxel's margin, 161 mm).
- **The slab's slide at the smaller step is not the rheology solve's convergence**: a tolerance 100 times tighter or
  four times the iterations moves it by under 1%.
