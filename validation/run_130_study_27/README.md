# Run 130: Study 27, a static friction coefficient imported and applied (issue 18)

The twenty-seventh registered study ([`PREREGISTRATION_27.md`](../../preregistrations/PREREGISTRATION_27.md)), played
once with [`play.sh`](play.sh) on the engines made by [`setup_engine.sh`](setup_engine.sh): Newton 1.7.0 as released;
with the record's validated friction chains and pull request #4306 rebased onto 1.7.0 (`chain`); and the chain with
Senua AI's static friction patch
([`static_friction_v2_on_chain.diff`](../../patches/in_design/static_friction_v2_on_chain.diff), sha256
ac70ebdcb1ea088e...), the switch `NEWTON_STATIC_FRICTION` unset (`off`) and set (`on`). Newton's USD importer's own
dependencies (usd-core 26.8, newton-usd-schemas 0.6.0) beside every engine, pinned and checked by sha256.

The patch's second form against run 129's: XPBD, SemiImplicit and Featherstone apply the static coefficient as there,
and VBD, like the MuJoCo solver, warns once that it does not apply it, naming the shapes (on the host, VBD's contact
held a cube between the limits on neither of its paths by the needed-impulse rule: its friction decides on the solve's
iterate, which overestimates the friction a hold needs). The rig's `usd=1` makes the cube and its friction material in
a UsdPhysics stage and imports it through Newton's own importer; on the host, the imported cube played byte for byte
as the one built in Python, the stage's gravity set to the rig's 9.8 m/s^2 (the importer otherwise takes USD's default
9.81).

## What it found

Played 20 October 2026 (UTC) on the second x86-64 host (`started.txt`, `finished.txt`); the measured lines in
`measured.txt`, the rules in [`rules.txt`](rules.txt). **13 of 16 rule lines held; R2's first line, R3 and R7's second
failed.**

| On (the switch set), the hold's mean speed, um/s | 1 ms | 0.25 ms |
|---|---|---|
| XPBD | 3 | 12 |
| SemiImplicit | 0 | 0 |
| Featherstone | 0 | 0 |
| XPBD, the imported cube | 3 | 12 |
| SemiImplicit and Featherstone, the imported cube | 0 | 0 |

- R1 held (60 of 60 plays off byte for byte the chain's). R2's second line held: as released every import drops the
  static coefficient (12 of 12 read none). R4 held (within 1 in 340 of 2.36 m/s), R5 held (within 1 in 440 of 4.41
  m/s), R6 held on all six lines (within 1 in 1,050 of the chain's slide), R7's first line held (the imported static
  coefficient 0.7 in all 24 models with the chain and on), R8 held (204 of 204: one warning on every MuJoCo solver,
  VBD-ALM and VBD play with the switch, none elsewhere), R9 held.
- **R3 and R7's second line failed on XPBD at 0.25 ms**: it creeps 12 um/s against the 10 registered (3 at 1 ms);
  SemiImplicit and Featherstone held at 0 at both steps, the cube built in Python and the cube imported alike.
- **R2's first line failed as registered**: as released, SemiImplicit and Featherstone at 0.25 ms do not slide on under
  the push (the registered fault) but move backward, at 6.4 mm/s held and 5.4 to 5.6 imported; at 1 ms they slide
  at 46 to 428 mm/s, XPBD at 1.18 m/s. As released the hold is wrong at every step, not in the way R2 stated.
- After the run, not registered (`xpbd_floor`, on the same host): XPBD's chain without the static patch, pushed below
  its dynamic limit at 0.25 ms, creeps the same 12 um/s, at 64, 128 and 256 iterations alike. The 12 um/s is XPBD's own
  floor at that step, about 3 nm a step, the cube held as still with the static coefficient as XPBD holds anything; the
  static rule adds nothing to it. Which arithmetic the 3 nm is (a 32-bit spacing at the cube's scale is about that)
  is not measured here.
- By the registration, issue 18's static part stays open: the static coefficient is imported, and applied by
  SemiImplicit and Featherstone at both steps and by XPBD at 1 ms; at 0.25 ms XPBD's floor is above the bar.
