# First pre-registration: Coulomb's friction for SemiImplicit and Featherstone, the unit friction direction

Registered 15 October 2026, after design probes (runs 001 to 005). Registered before any play of this registration
existed. Played once, as run 008.

## The question

SemiImplicit and Featherstone give friction the direction `vt / H(vt)`, H Warp's Huber norm not divided by its width,
so their friction is Coulomb's times |v| / H(v) (runs 001 to 004). The patch in design
`patches/in_design/unit_friction_direction.diff` launches, only when `NEWTON_UNIT_FRICTION_DIRECTION=1`, a copy of
their body contact kernel whose friction is `vt / |vt| * min(kf * |vt|, mu * N)`. On scenes the probes did not use:
does Newton as released still give friction above Coulomb's; with the switch on, is it Coulomb's, whatever the
smoothing width; does nothing else change; and with the switch unset, is the patched Newton the release byte for
byte?

## Engines and arms

- **stock**: Newton 1.6.1 from PyPI with run 001's environment (`validation/run_001_design_probes/environment.txt`).
- **off**: Newton v1.6.1 from source (commit 713fecdc...) with the patch file of sha256 dd4042afa2894458... applied,
  every dependency pinned to stock's (run 005's `environment_patched.txt`); switch unset.
- **on**: the same, `NEWTON_UNIT_FRICTION_DIRECTION=1`.

Rig as committed at this registration: `tools/nwt_contact.py`; measured by Senua AI's `sx_contact` and judged by its
`rule`. Warp's CPU device. Every play at 0.25 ms, a step no probe used.

## The scenes, registered parameters

None of these numbers was used in the probes.

- **The cube**: 0.8 kg, half-size 0.045 m, friction 0.45, set sliding at 1.3 m/s with its face on the ground, 1.2 s.
  Coulomb's distance: 1.3^2 / (2 x 0.45 x 9.8) = 191,610 um.
- **The plate**: 0.6 kg, 12 cm square (half-size 0.06 m), half-height 0.004 m, friction 0.3, set down from 1.5 mm,
  settled for 0.25 s, then kicked to 0.7 m/s along x; 1.1 s. Coulomb's distance 0.7^2 / (2 x 0.3 x 9.8) = 83,333 um,
  deceleration 2,940 mm/s2. Played with friction_smoothing 1.0 (the default) and 0.05.
- **The impact**: the cube landing from 40 mm at 1.5 m/s along x, friction 0.25, 0.4 s. Coulomb's friction over the
  impact, per 10,000: 2,500.
- **Nothing else**: the cube set down from 15 mm (friction 0.45, 1 s) and dropped from 80 mm with friction 0
  (1 s), on SemiImplicit and Featherstone; and the cube's slide on XPBD and the MuJoCo solver, which do not use the
  kernel.

Each scene on SemiImplicit and on Featherstone, unless it says otherwise.

## The rules

Each judged by `sx_contact rule`, from the measured lines, and nowhere else.

| Rule | Statement | Kind |
|---|---|---|
| R1 safe when off | Every file the off arm plays is byte-identical to the stock arm's | eq (identical files, files) |
| R2 the defect is there | Stock, both solvers: the cube's slide stops short of 60% of Coulomb's distance, and the plate (smoothing 1.0) decelerates from 260 to 300 ms at more than 1.5 times Coulomb's | all_le, all_ge |
| R3 the slide | On, both solvers: the cube's slide within 2 parts in 100 of Coulomb's distance, the plate's (both widths) within 1 part in 100 | all_within |
| R4 the impact | On, both solvers: friction over the impact within 1 part in 100 of 2,500 | all_within |
| R5 the width does not matter | On, each solver: the plate's file at width 0.05 byte-identical to its file at width 1.0 | eq |
| R6 the cube does not tip | On, both solvers: the cube's largest turn during its slide at most 30,000 urad | all_le |
| R7 nothing else changes | On: the set-down and the drop on both solvers, and the slides on XPBD and the MuJoCo solver, byte-identical to stock | eq (identical files, files) |
| R8 nothing blows up | On: no play's state stops being a number | eq (plays with nan_at_step, 0) |

The study holds if every rule holds. A rule that fails is reported as failed, with its numbers, and the patch stays in
design.

## Dry run

The study's runner is new. It is played once before the study on the stock arm only with throwaway parameters (run
004's plate and run 001's cube), only to check that it runs to the end and writes every measured line; no rule is read
from it, and its files are kept apart.
