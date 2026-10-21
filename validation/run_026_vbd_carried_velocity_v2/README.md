# Run 026: the VBD carried-velocity patch, second form: the angular velocity carried too

15 October 2026, 08:48 to 09:07 UTC. Not registered: a patch in design, held to the five checks. Played on the Newton
host by [`play.sh`](play.sh), whose hypothesis and predictions were pushed with the patch before the plays; reading
`reading.txt`, made with Senua AI's `sx_contact` (`chain`) and its suite runner, re-made byte for byte on the laptop
from the same files, every suite's verdicts included. In the logs the home folder is written `~/`.

## The hypothesis

Run 022's first form carries VBD's linear velocity and makes bodies fall as SemiImplicit and XPBD do, but in run 025
it left VBD's excess energy loss on the chain at 0.156 ms in place and made some chain readings worse. With the linear
velocity carried and the angular one still read back from 32-bit quaternions, a joint anchor's velocity, v + w x r,
joins an exact part to a rounded one. The second form carries the angular velocity as well.

## The patch

[`patches/in_design/vbd_carried_velocity_v2.diff`](../../patches/in_design/vbd_carried_velocity_v2.diff) (sha256
4e33692e4797541f...), against Newton v1.6.1. It holds the first form unchanged, selected by
`NEWTON_VBD_CARRIED_VELOCITY=1`, and adds the second, selected by `=2`: the linear velocity as in the first form, and
the angular velocity as the forward step's turn computed from its own angular velocity,
w_forward 2 atan(dt |w_forward| / 2) / (dt |w_forward|), which is what the stock read-back gives for that turn in exact
arithmetic, plus the solve's own turn, read from two nearby quaternions. Nothing is fitted.

## The five checks

| Check | Measured | |
|---|---|---|
| **1. Required** | Runs 006 and 022: VBD's bodies stop falling, the velocity read back from 32-bit positions | Held |
| **2. Correct** | With `=2` the suite's seven free plays are byte-identical to SemiImplicit's on VBD and VBD-ALM, as with `=1` | Held |
| **3. Nothing else gets worse** | The suite: VBD-ALM reads every line the release measured no further from its answer (5 of 10, as with `=1`); VBD reads its hold at 0.625 ms (93,487 against 93,355 um/s) and its slide's friction (3,893 against 3,896 per 10,000) slightly further, as with `=1`. The chain (below): readings move both ways by small amounts at most steps, and further from their answers in several cells on both solvers | **Not met** |
| **4. Safe when off** | No switch: 39 of 39 suite files byte-identical to run 007's on each solver, 16 of 16 chain files to run 014's. `=1`: 39 of 39 on each to run 022's, 16 of 16 chain files to run 025's (the first form unchanged) | Held |
| **5. The solver keeps converging** (here: no play stops being a number) | None did | Held |

| The free chain, kinetic energy after 2 s, per million of the start (right answer 1,000,000) | 10 ms | 2.5 ms | 0.625 ms | 0.156 ms |
|---|---|---|---|---|
| VBD, as released | 539,831 | 886,550 | 967,735 | 961,793 |
| VBD, first form | 539,822 | 886,630 | 967,293 | 943,546 |
| VBD, second form | 539,832 | 886,474 | 968,020 | 959,161 |
| VBD-ALM, as released | 540,907 | 888,187 | 968,602 | 923,643 |
| VBD-ALM, first form | 540,918 | 888,319 | 967,794 | 944,181 |
| VBD-ALM, second form | 540,944 | 888,279 | 967,863 | 929,314 |

| The swinging chain, largest energy departure, ppm of the largest kinetic energy | 10 ms | 2.5 ms | 0.625 ms | 0.156 ms |
|---|---|---|---|---|
| VBD, as released | 720,723 | 581,627 | 240,264 | 52,450 |
| VBD, second form | 720,718 | 581,634 | 239,081 | 60,796 |
| VBD-ALM, as released | 714,799 | 582,062 | 275,636 | 112,818 |
| VBD-ALM, second form | 714,812 | 582,033 | 275,845 | 135,088 |

| Prediction | Result |
|---|---|
| S: off and `=1` byte-identical to runs 007, 014, 022 and 025 | Held, every file |
| C: with `=2` the free plays byte-identical to SemiImplicit's | Held, 7 of 7 on each solver |
| P1: with `=2` the free chain loses less at 0.156 ms than at 0.625 ms, and no chain reading is further from its answer than as released | **Failed** on both solvers: the chain keeps less at 0.156 ms (959,161 against 968,020 on VBD; 929,314 against 967,863 on VBD-ALM), and readings further from their answers are VBD's free chain at 2.5 and 0.156 ms and its swinging chain at 2.5 and 0.156 ms, VBD-ALM's free chain at 0.625 ms and its swinging chain at 10, 0.625 and 0.156 ms |
| P2: with `=2` every suite line the release measured reads no further from its answer | Held on VBD-ALM; failed on VBD (the hold and the slide, as with `=1`) |
| K: no play stops being a number | Held |

## What it shows

- **The hypothesis does not hold.** Carrying the angular velocity too leaves VBD's excess loss on the chain at
  0.156 ms in place: it is not the velocity's 32-bit read-back, linear or angular, but something else in VBD's joint
  solve, not traced here.
- **Either form fixes the free fall exactly and moves the chain's readings both ways.** At 10 ms and 2.5 ms the
  changes are a part in 10,000 or less; at 0.625 ms and 0.156 ms they reach 2 parts in 100, more often against the answer
  on VBD-ALM's swinging chain. By the third check as set, no reading may get further from its answer, and both forms
  fail it.
- **Both forms stay in design, no study registered.** Whether the third check should allow a change smaller than the
  reading's own error, on readings that are wrong for another cause (here VBD's joint solve), is a question this
  record leaves open; it is not decided by re-reading these numbers.
