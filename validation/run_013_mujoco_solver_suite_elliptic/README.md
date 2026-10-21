# Run 013: the MuJoCo solver on the ten contact tests, with the elliptic cone

15 October 2026. Not registered: a design probe, by [`play.sh`](play.sh) (pushed before its plays); reading
`reading.txt`. Runs 009 and 010 could not read Newton's MuJoCo solver on the first deep dive's ten contact tests: with
its default pyramidal cone it stops being a number on the suite's frictionless scenes. Run 012 traced that to the
pyramid. Here the suite is played exactly as the first deep dive has it, every scene unchanged, on the MuJoCo solver
with the elliptic cone (`opt.cone=elliptic`); the plays are under `suites/1/mujoco_elliptic/`.

**No play stopped being a number. The MuJoCo solver passes 9 of 10.**

| Test | Result |
|---|---|
| T01 nothing touches the cube: the chain halves | PASS |
| T02 steady sliding: Coulomb's friction | PASS (3,999 per 10,000) |
| T03 at rest the ground carries the weight | PASS (19,600 mN) |
| T04 the bounce does not depend on the step | PASS (0 at every step) |
| T05 Coulomb at impact, every step | PASS (3,999 to 4,000) |
| **T06 held below the limit does not move** | **FAIL: creeps 765 um/s** |
| T07 pushed above the limit | PASS |
| T08 the refinement chain falls | PASS |
| T09 the ground never pulls | PASS |
| T10 friction over the impact and after it | PASS |

## What it shows

With the elliptic cone, Newton's MuJoCo solver scores as MuJoCo's C engine does on these tests (9 of 10 as released,
failing only the hold; the MuJoCo deep dive's run 008), and its creep at rest, 765 um/s, is what MuJoCo's C engine
gives on the elliptic cone (766 um/s, the MuJoCo deep dive's run 001). The two engines agree to within 1 um/s here,
one in 32-bit arithmetic on Warp and one in 64-bit C. MuJoCo's C engine holds with the elliptic cone and noslip; that
option in Newton's MuJoCo solver is not yet played.
