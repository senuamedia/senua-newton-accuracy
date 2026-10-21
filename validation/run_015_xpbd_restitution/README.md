# Run 015: XPBD's bounce with a restitution of 0, against its own restitution option

15 October 2026, 03:57 to 04:00 UTC. Not registered: a design probe on the Newton host, by [`play.sh`](play.sh), whose
prediction was pushed before the plays. The first deep dive's ten-test suite, every scene unchanged
([`tools/contact_suite.sh`](../../tools/contact_suite.sh)), on XPBD with its own option `enable_restitution=true`; the
shapes keep Newton's default restitution of 0. Read by the first deep dive's runner, `sx_contact_suite.sh`, and each
drop by `sx_contact bounce` (`reading.txt`); both were re-made byte for byte on the laptop from the same files. The
plays are under `suites/1/xpbd_restitution/`; XPBD as released is run 007's `suites/1/xpbd/`.

## The prediction, and what was measured

Written before the plays, from Newton's source: XPBD moves a body out of the ground and takes its velocity from how
far it moved in the step, so the push that undoes the penetration leaves as an upward speed. Its velocity-level
restitution pass is off by default; switched on, with a restitution of 0, it sets the separating speed toward 0.

| Predicted | Measured | |
|---|---|---|
| The rebound falls under 100 parts in 10,000 of the drop at every step, and T04 passes | 0 at every step (as released: 382 to 1,125); T04 passes | **Held** |
| The hold still creeps: T06 fails | 54,333 and 3,395 um/s, as released to the unit | **Held** |

| A cube dropped 80 mm, restitution 0: rebound per 10,000 of the drop | 10 ms | 5 ms | 2.5 ms | 1.25 ms | 0.625 ms | 0.3125 ms | 0.156 ms |
|---|---|---|---|---|---|---|---|
| XPBD as released (run 007's plays) | 382 | 851 | 951 | 1,055 | 1,125 | 1,097 | 1,092 |
| XPBD with `enable_restitution` | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

With the option on, the cube never rises after it lands: its highest point after the turn is below where it touched
(0.17 to 673 um below).

## What it costs: friction at an impact

| Test | XPBD as released | With `enable_restitution` |
|---|---|---|
| T04 the bounce does not depend on the step | FAIL (382 to 1,125) | **PASS** (0) |
| T05 Coulomb at impact, per 10,000 (right answer 4,000) | PASS (3,999 to 4,000) | **FAIL: 147 to 1,733**, and still sliding |
| T08 the refinement chain falls at every step | FAIL | **PASS** |
| T10 friction over the impact and after it, per 10,000 | PASS (3,999 to 4,000) | **FAIL: 1,828 to 3,359** |
| T01, T02, T03, T09 | PASS | PASS |
| T06 the hold, T07 the slip | FAIL | FAIL, the same numbers |
| **Passed** | **6 of 10** | **6 of 10** |

## What it shows

- **XPBD's bounce with a restitution of 0 comes from its position solve, and its own restitution option removes it,
  at every step.** Without it, the push that takes the cube out of the ground leaves as a rebound of 4% to 11% of
  the drop.
- **The same option takes friction away at an impact.** A cube landing at 4 m/s sideways gets 4% to 43% of Coulomb's
  friction impulse at the impact (T05), against Coulomb's exactly as released. Over the impact and the 0.1 s after
  it, 46% to 84% (T10). The score stays 6 of 10, with a different 6. Which part of the restitution pass takes the
  friction is not traced.
- Neither setting of XPBD's own option passes both the bounce and friction at an impact. That makes it a candidate
  for a patch: the restitution velocity pass with friction kept at Coulomb's.

Next: trace where the restitution pass takes the friction (`newton/_src/solvers/xpbd/restitution_kernels.py`).
