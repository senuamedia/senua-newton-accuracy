# Thirty-first pre-registration: the implicit MPM solver's thin colliders kept whole by a margin

Registered 21 October 2026, after run 120. Registered before any play of this registration existed. To be played once,
as run 134, on Newton 1.7.0.

## The question

Issue 21, #4712's leak (N13): liquid in a cup with thin walls leaves through them on the implicit MPM solver. Run 120
traced it: the solver's colliders take a shape's margin, 0 by default (`ShapeConfig.margin`), as their thickness, so a
wall thinner than the solver's voxel is missed; at a 10 mm voxel and 8 substeps 578 of the cup's 8,664 particles left
in 1 s with no margin, none with a margin of 2.5 mm (a quarter voxel) or more. Newton's own configuration, the
colliders' margin set to a quarter of the voxel, is the proposed fix. At voxel sizes and steps no run used: does it
keep the liquid in?

## The right answers

- A liquid in a closed cup stays in it: no particle crosses a wall.

## Engines and rigs

Newton 1.7.0 from PyPI (`newton==1.7.0`, Warp 1.18.0) as released, Study 7's environment; no patch. Rig as committed at
this registration: `tools/nwt_mpm_collider.py`, scene `cup` (its walls 4 mm thick, the particles 5 mm apart), its
`margin`, `voxel` and `substeps`. Warp's CPU device. Measured by Senua AI's `sx_contact` (`final`: the particles
outside the walls at the end) and judged by its `rule`.

## The scenes, registered parameters

None of these numbers was used in a run. The cup for 1 s, at voxel sizes of 8 mm and 12 mm, at 8 and 32 substeps of
the 1/24 s step, with the colliders' margin 0 (as released), a quarter of the voxel (2 and 3 mm), and half the voxel (4
and 6 mm).

## The rules

Each judged by `sx_contact rule`, from the measured lines, and nowhere else.

| Rule | Statement | Kind |
|---|---|---|
| R1 the fault is there | With no margin, particles leave the cup at every voxel size and step (1 or more) | all_ge |
| R2 kept whole | With a margin of a quarter voxel, no particle leaves at every voxel size and step | all_eq |
| R3 and beyond | With a margin of half a voxel, no particle leaves at every voxel size and step | all_eq |
| R4 a number | Every play on a number throughout | all_eq |

Reported, not ruled: every count.

## What it decides

When R1 to R4 hold, #4712's leak is fixed by Newton's own configuration: the implicit MPM solver's colliders given a
margin of a quarter voxel or more. #4712's slope (its friction falling as the step shrinks) is not decided here and
stays open. A rule that fails is reported as failed, and the leak stays open.
