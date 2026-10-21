# Run 113: VBD's displacement form with the chain far from the world's origin (issue 12)

Not registered: a design probe, its predictions pushed with [`play.sh`](play.sh) before any play. Newton 1.7.0 from PyPI,
and the same with Senua AI's VBD displacement patch in design first on the path
([`vbd_displacement_on_1.7.0.diff`](../../patches/in_design/vbd_displacement_on_1.7.0.diff), sha256 685c333b840ae7a4...,
switch `NEWTON_VBD_DISPLACEMENT=1`).

## Why

Run 111 found that with the patch VBD's free chain loses energy in proportion to the step, its 32-bit growth gone at
the origin. F9's evidence that the growth was the bodies' 32-bit poses was its dependence on where the chain is: moved
100 m from the origin, where a position's 32-bit spacing is 7.6e-6 m, VBD's chain departed from its energy by 419,732
ppm at 0.625 ms against 31,979 at the origin (run 045). The patch keeps each body's displacement from its target apart
from its pose and takes the velocity from it, but the joints are still evaluated on the 32-bit poses, so some cost of
being far from the origin may remain. Featherstone, whose state is the joints' angles, measures what 32-bit world
positions cost the reading itself (run 045: 9,070 ppm at 100 m against 6,019 at the origin). This probe sizes, before
Study 22 registers it, how near the chain 100 m out comes to the chain at the origin with the patch.

## What is played

Run 111's free chain (links of 0.7 and 1.3 kg, half-size 0.04 m, the first's centre 0.25 m from its joint, the second
joint 0.5 m out, the second's centre 0.22 m beyond it, at 0 and -0.4 rad turning at 2.2 and -1.1 rad/s, no gravity, 2
s), its first joint at the world's origin, 10 m and 100 m along x, at 2, 0.5 and 0.125 ms: on VBD as released
(`stock`) and with the patch (`on`), and on Featherstone as released.

## Predictions (pushed before the plays)

| Check | Prediction |
|---|---|
| C0 | Every play a number; with the patch at the origin, run 111's three chain files byte for byte |
| P1 | As released at 0.5 ms the chain 100 m out departs from its energy, at its largest, at least 5 times as far as at the origin |
| P2 | With the patch the chain 100 m out departs at most twice as far as at the origin, at every step |

Reported: every reading at 10 m, Featherstone's at every place and step.

## What it found

Played 20 October 2026 on the second x86-64 host (`started.txt`, `finished.txt`); the measured lines in `measured.txt`,
the checks in [`checks.txt`](checks.txt). **3 of 4 checks held; P2 failed.**

| Check | Result |
|---|---|
| C0 | Held: every play a number; with the patch at the origin, run 111's three chain files byte for byte (played on the Newton host) |
| P1 | Held: as released at 0.5 ms the chain 100 m out departs by 792,485 ppm at its largest, 77 times the origin's 10,272 |
| P2 | Failed: with the patch the chain 100 m out departs by 41,604, 16,643 and 11,003 ppm against 39,653, 10,787 and 2,463 at the origin, 1.05, 1.5 and 4.5 times; at 0.125 ms more than twice |

The chain's largest departure from its energy, ppm:

| | 2 ms | 0.5 ms | 0.125 ms |
|---|---|---|---|
| VBD as released, at the origin | 39,602 | 10,272 | 366,862 |
| 10 m out | 43,132 | 279,943 | 827,523 |
| 100 m out | 177,784 | 792,485 | 823,949 |
| VBD with the patch, at the origin | 39,653 | 10,787 | 2,463 |
| 10 m out | 38,492 | 9,403 | 2,977 |
| 100 m out | 41,604 | 16,643 | 11,003 |
| Featherstone as released, at the origin | 9,323 | 2,374 | 613 |
| 10 m out | 9,341 | 2,402 | 635 |
| 100 m out | 18,618 | 9,183 | 7,122 |

- **As released, where the chain is decides what VBD does**: its departure grows as the step shrinks, and grows with the
  distance from the origin, to 83% and 82% of the energy at 10 m and 100 m; at 0.5 ms 10 m out departs 27 times as far as at
  the origin.
- **With the patch, the growth is gone at every place**: the departure falls as the step shrinks at the origin, at 10 m
  (within 1 in 4 of the origin's at every step) and at 100 m. At 100 m a part remains that does not fall in proportion
  to the step (11,003 ppm at 0.125 ms, 4.5 times the origin's): the joints are still evaluated on 32-bit poses, whose
  spacing there is 7.6e-6 m. A solver whose state is the joints' angles pays a cost of the same order there:
  Featherstone, which works in spatial quantities about the world's origin, departs by 7,122 ppm at 100 m against 613
  at the origin, 11.6 times. So P2's bound, twice the origin's, was not one a 32-bit solver holds 100 m out; with the
  patch VBD is within 1.6 times Featherstone's own departure there.
- For Study 22 this sets what to register: with the patch, the departure no larger as the step shrinks at every place,
  and 10 m out within a stated fraction of the origin's; 100 m out reported against Featherstone at the same place.
