# Run 115: VBD-ALM's slide as the step shrinks, with VBD's displacement form (issues 12 and 13)

Not registered: a design probe, its predictions pushed with [`play.sh`](play.sh) before any play. Newton 1.7.0 from PyPI,
and the same with Senua AI's VBD displacement patch in design first on the path
([`vbd_displacement_on_1.7.0.diff`](../../patches/in_design/vbd_displacement_on_1.7.0.diff), switch
`NEWTON_VBD_DISPLACEMENT=1`), the engines run 114's `setup_engine.sh` made.

## Why

Study 22 (run 114) ruled that the patch keeps contacts' play: the slide within 1 in 100 of the release's. At 0.075 ms it
was 1.4% shorter. But the release's own slide changes as the step shrinks, 2.2% longer from 1.5 ms to 0.075 ms (the
patch's 0.7%), and the record's F2 says why: VBD's velocity read back from 32-bit positions loses friction as the step
shrinks, the fault the patch takes away. If so, as the step shrinks further the release's slide keeps moving and the
patch's settles; the comparison R6 made was against a play that carries the fault. This probe plays the slide at four
steps, on Study 22's slide and a second, beside Study 22's hold.

## Predictions (pushed before the plays)

| Check | Prediction |
|---|---|
| C0 | Every play a number; Study 22's slide at 1.5 and 0.075 ms, as released and with the patch, run 114's files byte for byte |
| P1 | As released, each slide at 0.0375 ms is more than 1% longer than at 0.3 ms |
| P2 | With the patch, each slide at 0.3 and 0.075 ms is within 1 in 200 of its play at 0.0375 ms |

Reported: every distance, the slides at 1.5 ms, the hold at every step.

## What it found

Played 20 October 2026 on the second x86-64 host (`started.txt`, `finished.txt`); the measured lines in `measured.txt`,
the checks in [`checks.txt`](checks.txt). **5 of 6 checks held; P1 failed on the first slide.**

| Check | Result |
|---|---|
| C0 | Held: every play a number; Study 22's slide at 1.5 and 0.075 ms run 114's four files byte for byte |
| P1, first slide | Failed: as released at 0.0375 ms it is 13% shorter than at 0.3 ms (88,507 against 101,688 um), not longer |
| P1, second slide | Held: as released at 0.0375 ms it never stops, 808,838 um against 289,207 at 0.3 ms |
| P2, both slides | Held: with the patch each within 1 in 200 of its play at 0.0375 ms at 0.3 and 0.075 ms |

| Slide's distance, um | 1.5 ms | 0.3 ms | 0.075 ms | 0.0375 ms |
|---|---|---|---|---|
| First (1.1 kg, 0.8 m/s, friction 0.45), as released | 101,160 | 101,688 | 103,396 | 88,507 |
| With the patch | 101,163 | 101,786 | 101,903 | 101,924 |
| Second (0.6 kg, 1.2 m/s, friction 0.3), as released | 289,910 | 289,207 | 277,044 | 808,838 (not stopped) |
| With the patch | 289,937 | 290,746 | 290,904 | 290,932 |

The hold is still at every step, as released and with the patch (-2 um/s as released at 0.0375 ms).

- **As released, the slide comes apart as the step shrinks** (F2): at 0.0375 ms the first stops 13% short, the
  second loses its friction and is still sliding at 0.99 m/s at the end, 2.8 times as far. P1 predicted only that
  each would lengthen; the first moved the other way, by more.
- **With the patch the slide settles**: each distance moves by less than 0.14% from 0.3 ms down, where as released
  they move by 13% and 180%. Study 22's R6 compared the patch with the release at 0.075 ms, a play that carries this
  fault: the 1.4% between them there is the release's, not the patch's.
- Both settled distances are longer than Coulomb's law gives with the cube's own friction (72.5 and 244.6 mm), as
  they are at the largest step as released, 1.40 and 1.19 times: not this patch's doing, and not read further
  here.
