# Run 114: Study 22, played once

20 October 2026, 16:19 to 16:26 UTC, on the second x86-64 host, by [`play.sh`](play.sh), under
[`PREREGISTRATION_22.md`](../../preregistrations/PREREGISTRATION_22.md), registered and pushed with the runner before
any play. The runner's dry run (`dry/`, throwaway parameters) ran to the end first, and its rules section was run on
the dry run's lines to check it ran to the end too (not recorded; those numbers mean nothing). Played from the record
at its commit 525cf9e, on Newton 1.7.0 and the engine made by [`setup_engine.sh`](setup_engine.sh) (Senua AI's VBD
displacement patch, [`vbd_displacement_on_1.7.0.diff`](../../patches/in_design/vbd_displacement_on_1.7.0.diff)). Read
by Senua AI's `sx_contact` (`creep`, `chain`, `stop`) and judged by its `rule` (`rules.txt`).

## The result: 12 of 14 rule lines held; R5 at the smallest step and R6's slide at the smallest step failed

| Rule | Measured | |
|---|---|---|
| R1 safe when off | 19 of 19 plays off byte for byte the release's | held |
| R2 the fault is there | As released the spinning body's centre at 201 um/s at 0.075 ms; the chain at the origin departs by 258,054 ppm at 0.09375 ms against 13,680 at 0.375 ms; 10 m out by 495,421 at 0.375 ms, 36 times the origin's | held, 3 lines |
| R3 the centre still | With the patch 0 um/s at every step on VBD and VBD-ALM | held |
| R4 the loss falls with the step | With the patch 24,420, 6,410 and 952 ppm, 3.8 and 6.7 times smaller at each step | held |
| R5 where the chain is | 10 m out 21,038 and 5,243 ppm, within 1 in 3 of the origin's at 1.5 and 0.375 ms; **3,281 at 0.09375 ms, 3.4 times the origin's 952**; 100 m out 25,646, 18,002 and 8,361, falling with the step | held 3 of 4 lines; failed at 0.09375 ms |
| R6 contacts kept | The hold still at both steps with the contact history; the slide 101,163 um against the release's 101,160 at 1.5 ms; **101,903 against 103,396 at 0.075 ms, 1.4% shorter** | held 2 of 3 lines; the slide failed at 0.075 ms |
| R7 a number | Every play a number throughout | held |

The chain's largest departure from its energy, ppm:

| | 1.5 ms | 0.375 ms | 0.09375 ms |
|---|---|---|---|
| VBD as released, at the origin | 23,750 | 13,680 | 258,054 |
| 10 m out | 32,370 | 495,421 | 905,205 |
| 100 m out | 143,691 | 792,139 | 891,481 |
| VBD with the patch, at the origin | 24,420 | 6,410 | 952 |
| 10 m out | 21,038 | 5,243 | 3,281 |
| 100 m out | 25,646 | 18,002 | 8,361 |
| Featherstone as released, at the origin | 3,606 | 906 | 215 |
| 10 m out | 3,598 | 892 | 219 |
| 100 m out | 3,316 | 2,473 | 3,686 |

The slide's distance, um: as released 101,160 at 1.5 ms and 103,396 at 0.075 ms; with the patch 101,163 and 101,903.

## What it shows

**The registration's decision: not all of R1 to R7 hold, so the patch is not validated by Study 22, and issues 13 and
12's VBD part stay open.** What the plays show, reported:

- **The spinning body is still at every step with the patch** (R3), where as released it drifts at up to 201 um/s, on
  both paths: the drift's cause, the velocity read back from 32-bit poses, is gone.
- **The chain's growth as the step shrinks is gone at the origin**: its loss falls by 3.8 and 6.7 times at each step,
  as released it grows to 26% of its energy; 10 m and 100 m out the growth to 91% and 89% is gone too. **What remains
  away from the origin does not fall with the step at the smallest step**: 10 m out 3,281 ppm, 3.4 times the origin's,
  where Featherstone, whose state is the joints' angles, plays alike at the origin and 10 m out (215 and 219 ppm). The
  joints are still evaluated on 32-bit poses (9.5e-7 m apart 10 m out), and their correction at a small step reads that
  spacing: a second 32-bit cost, in the joints' evaluation, which the displacement form does not reach.
- **The slide at the smallest step changes by 1.4%**: as released its distance grows by 2.2% from 1.5 ms to 0.075 ms,
  with the patch by 0.7%. The rule asked for the release's play kept; it was not. Whether the patch's slide is the
  nearer to the slide's own converged distance, which neither the release nor the patch reached here (Coulomb's law
  gives 72.5 mm; both slide about 101 mm), is a question for a probe, not a reason to read R6 as held.
