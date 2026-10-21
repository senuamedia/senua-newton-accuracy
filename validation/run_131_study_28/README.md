# Run 131: Study 28, one model across engines with MuJoCo C as the reference (issue 22)

The twenty-eighth registered study ([`PREREGISTRATION_28.md`](../../preregistrations/PREREGISTRATION_28.md)), played
once with [`play.sh`](play.sh) on the engines made by [`setup_engine.sh`](setup_engine.sh): Newton 1.7.0 as released,
and with the record's validated friction chains (`chain`). The reference is MuJoCo C, MuJoCo's own `mj_step`, reached
through the MuJoCo solver on its CPU path with MuJoCo's recommended elliptic cone and noslip, set through Senua AI's
MuJoCo noslip patch (Study 11; amended before any play, see the registration). The
report behind issue 22 replays against PhysX, which these hosts do not have.

## What it found

Played 20 October 2026 (UTC) on the Newton host (`started.txt`, `finished.txt`); the measured lines in `measured.txt`,
the rules in [`rules.txt`](rules.txt). **14 of 18 rule lines held; R1's push and R5 at 1 ms, three lines, failed.**

| | slide, um (right: 91,837) | | hold, um/s | | push, m/s (right: 1.9845) | |
|---|---|---|---|---|---|---|
| | 1 ms | 0.5 ms | 1 ms | 0.5 ms | 1 ms | 0.5 ms |
| MuJoCo C | 91,688 | 91,817 | 0 | 0 | **1.8955** | 1.9943 |
| XPBD, chain | 91,388 | 91,617 | 3 | 6 | 1.9844 | 1.9844 |
| SemiImplicit, chain | 91,738 | 91,963 | 0 | 0 | 1.9868 | 1.9863 |
| Featherstone, chain | 91,741 | 91,964 | 0 | 0 | 1.9868 | 1.9864 |

- R1's slide and hold held; **R1's push failed: MuJoCo C, the reference, ends the push 4.5% slow at 1 ms** (0.5% fast at
  0.5 ms). R2 held (as released one or more of the three departs from MuJoCo C at both steps). R3 held on all six
  lines (within 1 in 300 of MuJoCo C's slide), R4 held (0 to 6 um/s), R6 held. **R5 failed at 1 ms on all three**,
  ruled against MuJoCo C's push: each is within 1 in 800 of the right answer there, and R5 held at 0.5 ms.
- After the run, not registered (`mjc_push`, on the same host): MuJoCo C's push at 1 ms is the same bytes with noslip at
  10 or 50 iterations or none; its elliptic cone's friction rises as the cube speeds up (the push's acceleration 2.31
  m/s^2 from 0.35 to 0.5 s, 2.12 from 0.5 to 0.8 s, against 2.205), and the pyramidal cone ends 1% slow. The departure
  is MuJoCo's soft friction at that step, not Newton's: Newton's three play the model right at both steps.
- By the registration, issue 22 stays open: the model transfers from MuJoCo C to Newton's three on the slide and the
  hold at both steps and on the push at 0.5 ms; at 1 ms the push diverges because the reference departs.
