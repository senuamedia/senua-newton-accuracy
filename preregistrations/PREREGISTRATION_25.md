# Twenty-fifth pre-registration: MuJoCo's recommended configuration on the MuJoCo solver's Warp path

Registered 21 October 2026, after the design probe of run 123. Registered before any play of this registration
existed. To be played once, as run 126, on Newton 1.7.0.

## The question

Issue 15 (F7): MuJoCo's recommended configuration for a load held by friction, its elliptic cone with the noslip
solver, cannot be set on the MuJoCo solver's Warp path: MuJoCo Warp 3.15 refuses `noslip_iterations` above 0. Study 11
fixed it on the CPU path, where MuJoCo's C engine runs noslip, with the record's Newton noslip patch, which passes the
option through. Senua AI's MuJoCo Warp noslip patch ports MuJoCo's noslip solver into MuJoCo Warp after its main
solve; in run 123 the Warp path with it held a cube still and gave MuJoCo's C engine's plays to the micrometre. On a
hold, a slide, a drop and a cube held between two pushes, none of whose numbers a probe used: does it?

## The right answers

- A body pushed with less than friction can hold stays still.
- A body slid along the ground slides as far as friction stops it: the configuration's other plays are not changed by
  it.
- With MuJoCo's own configuration, MuJoCo Warp plays as MuJoCo's C engine does: the reference is the C engine, through
  the CPU path, with the same configuration.

## Engines and rigs

Newton 1.7.0 from PyPI (`newton==1.7.0`, Warp 1.18.0, MuJoCo Warp 3.15.0, MuJoCo 3.15) as released, Study 7's
environment, and one engine made from it by this run's `setup_engine.sh`: the base environment's Newton with the
record's validated noslip patch ([`mujoco_noslip.diff`](../patches/newton-1.7.0/mujoco_noslip.diff)) and its MuJoCo Warp
with Senua AI's MuJoCo Warp noslip patch ([`mujoco_warp_noslip_on_3.15.0.diff`](../patches/in_design/mujoco_warp_noslip_on_3.15.0.diff),
sha256 36d1f07932743631...), both no fuzz, first on the path. **Off**: the patched tree with noslip unset; **on**:
`noslip_iterations=5`. The MuJoCo solver with its elliptic cone, the Warp path unless the CPU path is named. Rig as
committed at this registration: `tools/nwt_contact.py`. Measured by Senua AI's `sx_contact` (`creep`, `stop`, `rest`)
and judged by its `rule`.

## The scenes, registered parameters

None of these numbers was used in the probes or in Study 11. At 2 and 0.5 ms.

- **H, a hold**: a 1.2 kg cube of half-size 0.045 m on the ground at friction 0.7, pushed sideways from 0.3 s at 5.36 N
  (65% of its friction's limit), 1.4 s.
- **L, a slide**: a 0.9 kg cube of half-size 0.035 m sent at 1.1 m/s at friction 0.5, 0.8 s.
- **D, a drop**: a 1.4 kg cube of half-size 0.05 m dropped from 3 cm at friction 0.4, 0.8 s.

Each as released (Warp path, noslip cannot be set), off, and on, on the Warp path and on the CPU path.

## The rules

Each judged by `sx_contact rule`, from the measured lines, and nowhere else.

| Rule | Statement | Kind |
|---|---|---|
| R1 safe when off | Off, every Warp-path play byte for byte the release's | eq (count) |
| R2 the fault is there | As released, the Warp path's hold creeps at 100 um/s or more at both steps | all_ge |
| R3 held | On, the Warp path's hold within 10 um/s of still at both steps | all_in |
| R4 as MuJoCo's C engine | On, the Warp path as the CPU path at both steps: the hold's speed within 10 um/s, the slide's distance and the drop's weight within 1 in 100 | near, within |
| R5 the other plays kept | On, the Warp path's slide within 1 in 20 of its play off, and the drop's weight within 1 in 100 of it, at both steps | within |
| R6 a number | Every play on a number throughout | all_eq |

Reported, not ruled: every reading, the CPU path off.

## What it decides

When R1 to R6 hold, issue 15 is fixed and validated on the MuJoCo solver's Warp path by Senua AI's MuJoCo Warp noslip
patch with the record's Newton noslip patch, and with Study 11 on the CPU path, issue 15 is resolved. A rule that
fails is reported as failed, and the issue stays open on the Warp path.
