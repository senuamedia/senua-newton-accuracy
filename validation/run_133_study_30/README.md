# Run 133: Study 30, a static friction coefficient imported and applied, XPBD's slip seen whole (issue 18)

The thirtieth registered study ([`PREREGISTRATION_30.md`](../../preregistrations/PREREGISTRATION_30.md)), played once
with [`play.sh`](play.sh) on the engines made by [`setup_engine.sh`](setup_engine.sh): Newton 1.7.0 as released; with
the record's validated friction chains and pull request #4306 rebased onto 1.7.0 (`chain`); and the chain with Senua
AI's static friction patch
([`static_friction_v2_on_chain.diff`](../../patches/in_design/static_friction_v2_on_chain.diff)) and its XPBD friction
slip patch on that ([`xpbd_friction_slip_on_static.diff`](../../patches/in_design/xpbd_friction_slip_on_static.diff),
sha256 104a1a88390f1c3d...), both switches unset (`off`) and set (`on`).

The slip patch, after Study 27: XPBD's friction measured a step's slip as the difference of two contact points' 32-bit
world positions, blind to a slip under one spacing of those coordinates, so a held cube slipped about that a step (12
um/s at 0.25 ms, its chain the same without the static patch). With `NEWTON_XPBD_FRICTION_SLIP=1` the slip is the
points' separation at the step's start plus each body's motion over the step, carried per body: the integrator's v dt
and w dt and every iteration's correction (`apply_body_deltas`' own arithmetic), a turn on a lever by Rodrigues'
formula. On the host before this study: the hold at 0.25 ms 7 um/s (12 without), at 1 ms 1 (3), the slides' distances
unchanged and a stopped slide still where it crept 13 to 391 um/s; with the switch unset, byte for byte the chain's.
Below 0.25 ms another floor of XPBD's remains, not traced (at 0.0625 ms a hold creeps 115 um/s with the patch).

## What it found

Played 20 October 2026 (UTC) on the second x86-64 host (`started.txt`, `finished.txt`); the measured lines in
`measured.txt`, the rules in [`rules.txt`](rules.txt). **16 of 16 rule lines held.**

| On (both switches set), mean speed, um/s | hold, 1 ms | hold, 0.25 ms | imported, 1 ms | imported, 0.25 ms |
|---|---|---|---|---|
| XPBD | 1 | 7 | 1 | 7 |
| SemiImplicit | 0 | 0 | 0 | 0 |
| Featherstone | 0 | 0 | 0 | 0 |
| As released, the three (hold; imported) | 50,638 to 1,177,250 | 9,238 to 1,175,466 | 25,084 to 588,870 | 9,089 to 587,698 |
| The MuJoCo solver, VBD-ALM, VBD on (they warn; the dynamic coefficient) | 1,176,861; 1,216,876; 1,236,761 | 1,176,340; 1,229,869; 1,289,394 | | |

- R1 held (60 of 60 plays off byte for byte the chain's); R2 held (as released the hold and the import depart from rest
  by 9 mm/s or more, and 12 of 12 imports drop the static coefficient); R3 held (1 and 7 um/s on XPBD, 0 on SemiImplicit
  and Featherstone); R4 held (within 1 in 2,300 of 2.26 m/s); R5 held (within 1 in 340 of 4.41 m/s); R6 held on all six
  lines (within 1 in 1,060 of the chain's slide, which is within 0.3% of Coulomb's 118,076 um); R7 held (the imported
  coefficient 0.75 in 24 of 24 models, the imported cube held as the built one); R8 held (204 of 204); R9 held.
- **Issue 18 resolved**: with pull request #4306 a USD material's static friction reaches the model, and with Senua
  AI's static friction patch and its XPBD friction slip patch XPBD, SemiImplicit and Featherstone hold a cube pushed
  between the limits at 1 and 0.25 ms, imported or built, and slide on the dynamic coefficient once it breaks away; the
  MuJoCo solver and VBD say they do not apply it.
