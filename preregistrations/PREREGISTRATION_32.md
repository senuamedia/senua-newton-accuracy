# Thirty-second pre-registration: the implicit MPM solver's thin colliders kept whole by a margin of half a voxel

Registered 21 October 2026, after Study 31 (run 134). Registered before any play of this registration existed. To be
played once, as run 135, on Newton 1.7.0.

## The question

Issue 21, #4712's leak (N13): liquid in a cup with thin walls leaves through them on the implicit MPM solver, whose
colliders take a shape's margin, 0 by default (`ShapeConfig.margin`), as their thickness (run 120). Study 31 found a
margin of half the voxel keeping the cup whole at voxels of 8 and 12 mm and 8 and 32 substeps, and a quarter voxel
not at 8 mm (54 and 5 particles out), so its rule for a quarter voxel failed. Newton's own configuration, the colliders'
margin set to half the voxel, is the proposed fix. At voxel sizes and steps no run used: does it keep the liquid in?

## The right answers

- A liquid in a closed cup stays in it: no particle crosses a wall.

## Engines and rigs

Newton 1.7.0 from PyPI (`newton==1.7.0`, Warp 1.18.0) as released, Study 7's environment; no patch. Rig as committed at
this registration: `tools/nwt_mpm_collider.py`, scene `cup` (its walls 4 mm thick, the particles 5 mm apart), its
`margin`, `voxel` and `substeps`. Warp's CPU device. Measured by Senua AI's `sx_contact` (`final`: the particles
outside the walls at the end) and judged by its `rule`.

## The scenes, registered parameters

None of these numbers was used in a run. The cup for 1 s, at voxel sizes of 7 mm and 14 mm, at 12 and 24 substeps of
the 1/24 s step, with the colliders' margin 0 (as released) and half the voxel (3.5 and 7 mm); and a quarter of the
voxel (1.75 and 3.5 mm), reported.

## The rules

Each judged by `sx_contact rule`, from the measured lines, and nowhere else.

| Rule | Statement | Kind |
|---|---|---|
| R1 the fault is there | With no margin, particles leave the cup at every voxel size and step (1 or more) | all_ge |
| R2 kept whole | With a margin of half a voxel, no particle leaves at every voxel size and step | all_eq |
| R3 a number | Every play on a number throughout | all_eq |

Reported, not ruled: every count, and the quarter voxel's.

## What it decides

When R1 to R3 hold, #4712's leak is fixed by Newton's own configuration: the implicit MPM solver's colliders given a
margin of half a voxel or more. #4712's slope (its friction falling as the step shrinks) is not decided here and
stays open. A rule that fails is reported as failed, and the leak stays open.
