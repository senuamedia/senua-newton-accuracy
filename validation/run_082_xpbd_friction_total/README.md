# Run 082: XPBD's friction bounded on the step's totals (issue 6)

Not registered: a design probe, its predictions pushed with [`play.sh`](play.sh) before any play. Newton 1.7.0 from
PyPI, and the same with Senua AI's XPBD friction patch in design first on the path
([`xpbd_friction_total_on_1.7.0.diff`](../../patches/in_design/xpbd_friction_total_on_1.7.0.diff), sha256
9a1c85f32b941c6c..., switch `NEWTON_XPBD_FRICTION_TOTAL=1`).

## The patch

Each iteration XPBD bounds a contact's friction correction by mu times that iteration's normal correction ("limit
friction based on incremental normal force, good approximation to limiting on total force"). At rest a step's normal
corrections add up only to the step's sink and shrink from iteration to iteration, so a load well inside Coulomb's
limit is not held (run 044, issue 6). The patch keeps the bound that comment names, Coulomb's on the totals: the
step's friction at a contact, summed over its iterations, within mu times the normal correction summed over the same
iterations (the accumulated-impulse clamp of sequential impulses, Catto, GDC 2005); two sums a contact, zeroed each
step.

## What is played

XPBD's contact suite as released, with the switch unset and set; run 044's hold (1 kg, half-size 0.05 m, friction 0.5,
pushed by 2.94 N, 0.6 of what friction holds, from 0.5 s, 2 s) at 2 and 0.5 ms, at 2 and 32 iterations, the same three
ways. XPBD's speed floor stays on (a creep under 0.1 mm/s reads 0).

## Predictions (pushed before the plays)

| Check | Prediction |
|---|---|
| X0 | With the switch unset every suite file and every hold byte for byte the release's |
| X1 | The suite's T06 (held below the friction limit, allowed 10 um/s) fails as released and passes with the patch |
| X2 | As released the hold creeps 300 um/s or more at both steps and iteration counts; with the patch within 10 um/s |
| X3 | Every suite verdict that passes as released passes with the patch |

Reported: T07 (pushed above the friction limit), T04 and T08, and every reading.

## The result: 4 of 6 checks held

Played 20 October 2026, 11:58 to 12:02 UTC, on the Newton host, from the record at ba2a4f4 (these predictions pushed).

| The hold's creep, um/s (the answer 0) | 2 ms, 2 iterations | 2 ms, 32 | 0.5 ms, 2 | 0.5 ms, 32 |
|---|---|---|---|---|
| As released | 10,862 | 1,531 | 2,715 | 380 |
| **With the patch** | 10,862 | **0** | 2,715 | **0** |

- X0 (43 of 43 files byte for byte with the switch unset) and X3 (no verdict lost: the suite 6 of 10 either way) held;
  X1's release line held (T06 fails as released).
- **At 32 iterations the patch holds the cube still** at both steps, where as released it creeps 1,531 and 380 um/s:
  the friction bound on the step's totals removes the floor run 044 traced.
- **At XPBD's default 2 iterations it changes nothing** (10,862 and 2,715 um/s, as released), so the suite's T06,
  played at 2 iterations, still fails (X1's patched line and X2's patched line failed). That creep is the solve left
  unconverged, run 027's first cause: two iterations of a contact relaxed by 0.8 do not undo the step's slip, and the
  bound never binds there. Run 083 measures how many iterations the patched hold needs.
