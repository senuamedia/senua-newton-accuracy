# Run 132: Study 29, one model across engines, each held to the right answer (issue 22)

The twenty-ninth registered study ([`PREREGISTRATION_29.md`](../../preregistrations/PREREGISTRATION_29.md)), played
once with [`play.sh`](play.sh) on the engines made by [`setup_engine.sh`](setup_engine.sh) (run 131's): Newton 1.7.0
as released, with the record's validated friction chains (`chain`), and MuJoCo C, MuJoCo's own `mj_step` through the
MuJoCo solver's CPU path with the elliptic cone and noslip (the record's noslip patch, Study 11). After Study 28, whose
precondition (the reference right) failed at 1 ms: here each engine is held to the right answer, and the transfer from
MuJoCo C is ruled where MuJoCo C is right.

## What it found

Played 20 October 2026 (UTC) on the Newton host (`started.txt`, `finished.txt`); the measured lines in `measured.txt`,
the rules in [`rules.txt`](rules.txt), the transfer's lines in [`transfer.txt`](transfer.txt). **6 of 6 rule lines
held.**

| | slide, um (right: 71,429) | | hold, um/s | | push, m/s (right: 3.087) | |
|---|---|---|---|---|---|---|
| | 1 ms | 0.5 ms | 1 ms | 0.5 ms | 1 ms | 0.5 ms |
| MuJoCo C | 71,255 | 71,426 | 0 | 0 | 3.0717 | **3.0432** |
| XPBD, chain | 71,078 | 71,231 | 3 | 6 | 3.0876 | 3.0888 |
| SemiImplicit, chain | 71,489 | 71,663 | 0 | 0 | 3.0877 | 3.0875 |
| Featherstone, chain | 71,490 | 71,664 | 0 | 0 | 3.0877 | 3.0874 |
| The MuJoCo solver's Warp path (reported) | 71,264 | 71,431 | 447 | 447 | 3.0717 | 3.0788 |
| VBD-ALM, chain (reported) | 96,821 | 97,013 | 0 | 0 | 3.1232 | 3.1469 |
| VBD, chain (reported) | 112,277 | 115,759 | 19,858 | 40,830 | 3.1461 | 3.1908 |

- R1 held: the three right on every scene at both steps (the slide within 1 in 200, the hold 0 to 6 um/s, the push
  within 1 in 2,600). R2 held: MuJoCo C right on five of its six readings, and on all 15 (scene, step, solver) lines
  there each of the three within 1 in 100 of it. R3 held (as released one or more of the three departs from MuJoCo C at
  both steps). R4 held.
- MuJoCo C's push at 0.5 ms is 1.4% slow (0.5% at 1 ms): its own departure, as in run 131, where the three are right.
- Reported: the Warp path, without noslip (MuJoCo Warp 3.15 refuses it as released; the record's noslip patch, Study
  25), creeps 447 um/s on the hold; VBD's slides are 36% (VBD-ALM) and 57 to 62% (VBD) long and its pushes up to 3.4%
  fast, where it plays without the record's VBD patches and contact history.
- **Issue 22 resolved as far as these hosts can play it**: with the record's patches one model plays the same on
  XPBD, SemiImplicit and Featherstone as on MuJoCo C wherever MuJoCo C plays the physics, and right where it does not.
  The report's PhysX replay is not played (no PhysX on these hosts).
