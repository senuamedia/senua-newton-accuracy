# Run 092: SemiImplicit's Coulomb friction pass made more than once a step (issues 6 and 9)

Not registered: a design probe, its predictions pushed with [`play.sh`](play.sh) before any play. Newton 1.7.0 from
PyPI, and the same with the second form of Senua AI's SemiImplicit Coulomb friction patch in design first on the path
([`semi_coulomb_friction_v2_on_1.7.0.diff`](../../patches/in_design/semi_coulomb_friction_v2_on_1.7.0.diff), sha256
8c69b44b3f59adae..., switches `NEWTON_SEMI_COULOMB_FRICTION=1` and `NEWTON_SEMI_COULOMB_FRICTION_ITERATIONS=K`).

## The patch

[Run 090](../run_090_semi_coulomb_friction/README.md)'s first form makes the slide Coulomb's at every step but leaves
the hold creeping in proportion to the step: its one sweep shares a body's slip among the body's contacts, each with
an effective mass that carries the turn the impulse gives the body, so it stops only part of the slip it finds. For
run 001's cube on its four corners the part is 5 in 8 of a slip common to the corners (each corner's effective mass is
1/m plus 3/m from the turn; the four impulses together stop the slip by 2.5/m times their sum), so the sweep leaves 3
in 8. The second form makes the pass K times a step, each sweep from the velocities the one before left (a damped
Jacobi iteration, which converges since a body's contacts share each sweep), and keeps each contact's friction over
the step within Coulomb's cone on its total rather than each sweep's (accumulated impulses, Catto 2005; as Study 15's
XPBD patch). With K = 1 it is the first form's code.

## What is played

On SemiImplicit as released, and with the second form at K = 1, 4, 16 and 64: run 090's hold (1 kg, half-size 0.05 m,
friction 0.5, pushed by 2.94 N, 0.6 of what friction holds, from 0.5 s, 2 s) and slide (from 1 m/s at friction 0.5, 0.5
s; Coulomb's distance v^2 / (2 mu g) = 102,041 um) at 2, 0.5 and 0.125 ms; the contact suite as released and at K = 16
and 64.

## Predictions (pushed before the plays)

| Check | Prediction |
|---|---|
| C0 | Every play with the patch a number; at K = 1 each hold and slide byte for byte run 090's with the patch |
| C1 | At K = 64 the hold within 10 um/s of still at every step |
| C2 | At K = 64 the slide within 1 in 100 of Coulomb's 102,041 um at every step |
| C3 | At K = 64 the suite's T06 (held below the friction limit) passes, and no verdict that passes as released is lost |

Reported: the hold and slide at K = 4 and 16, the suite at K = 16, every verdict.

## What it found

Played 20 October 2026 on the second x86-64 host (`started.txt`, `finished.txt`); the measured lines in
`measured.txt`, the checks in [`checks.txt`](checks.txt), the suites under `suites/`. **4 of 6 checks held.**

| Check | Result |
|---|---|
| C0 | Held: every play a number; at K = 1 the 6 plays byte for byte run 090's with the patch |
| C1 | Held: at K = 64 the hold 1, 0 and 0 um/s at 2, 0.5 and 0.125 ms |
| C2 | Held: at K = 64 the slide 101,529, 102,279 and 102,467 um against 102,041 |
| C3 | **Failed**: T06 fails at the suite's largest step (21 and 0 um/s); T08, which passes as released, is lost |

| Sweeps | The hold at 2, 0.5 and 0.125 ms |
|---|---|
| 1 | 8,821, 2,205 and 551 um/s |
| 4 | 297, 74 and 18 um/s |
| 16 | 1, 0 and 0 um/s |
| 64 | 1, 0 and 0 um/s |

- **More sweeps hold the cube**: from 1 to 4 sweeps the creep falls about thirty times at every step, and from 16 on it
  is within 1 um/s of still, at the issue's own 2 ms step too (issue 9's 10 cm cube). The slide moves by 32 um at most
  from one sweep to 64 (101,561 to 101,529 um at 2 ms), and by 3 um from 4 sweeps on.
- **The suite passes 6 of 10 at 16 and 64 sweeps**, 4 as released: steady sliding (T02: 4,000 and 4,000), Coulomb at
  impact (T05: 3,999 to 4,000 at every step) and the friction over an impact (T10) now pass. T06 holds at the suite's
  1/16 step (0) but creeps 21 um/s at its largest, 10 ms, where the cube's normal contact is past SemiImplicit's
  explicit limit (T04: it rebounds 1.69 times its drop height there, as released and with the patch); T07 is 3.6% fast
  at 1/16 (1,015,500 um/s for 980,000) and 31% at 10 ms.
- **T08 is lost for the bounce, not the friction**: its readings fall from 3,639,133 to 7,248 over four halvings, rise
  to 9,949 at the fifth and fall to 2,221 at the sixth. The chain is a drop with a sideways speed; with friction
  Coulomb's the slide no longer hides the bounce, which grows as the step shrinks (T04: 103, 157, 251 and 267 per
  10,000 of the drop at 1/8 to 1/64, issue 4), so where it lands after the bounce moves with the step. Issue 4 is fixed
  by Senua AI's contact damping patch (Study 3): run 093 stacks the friction pass on it.
