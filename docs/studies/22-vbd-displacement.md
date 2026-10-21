# Study 22: VBD's rigid solve in displacement form

**Outcome: 12 of 14 rule lines held; not validated.** Senua AI's VBD displacement patch keeps a spinning body's centre
still at every step and makes a free chain's loss fall with the step at the origin, but 10 m out at the smallest step
the chain departs 3.4 times as far as at the origin, and the slide at 0.075 ms is 1.4% shorter than the release's.
Registered 21 October 2026 ([`PREREGISTRATION_22.md`](../../preregistrations/PREREGISTRATION_22.md)); played once as
[run 114](../../validation/run_114_study_22/README.md). Issues 13 (on VBD-ALM) and 12 (VBD's part) stay open.

## How it got here

| Run | What | Result |
|---|---|---|
| [104](../../validation/run_104_vbd_spin_iterations/README.md), [108](../../validation/run_108_vbd_spin_forward_step/README.md) | Where VBD's spinning body's drift comes from | The velocity read back from 32-bit poses, and the solve's own writes of the pose |
| [111](../../validation/run_111_vbd_displacement/README.md) | The displacement form (pull request #4721's, in 1.7.0's rigid solve) | The centre still at every step; the chain's loss first order in the step; contacts kept |
| [113](../../validation/run_113_vbd_displacement_far/README.md) | The chain 10 m and 100 m out | The growth gone at every place; 100 m out a part remains, of the order Featherstone pays there |

## The rules and the result

| Rule | Result |
|---|---|
| R1 safe when off | held: 19 of 19 plays byte for byte |
| R2 the fault is there as released | held, 3 lines |
| R3 the centre still | held: 0 um/s at every step on both paths |
| R4 the chain's loss falls with the step | held: 24,420, 6,410, 952 ppm |
| R5 where the chain is | 3 of 4 lines held; **failed 10 m out at 0.09375 ms**: 3,281 ppm against 952 at the origin |
| R6 contacts kept | 2 of 3 lines held; **the slide at 0.075 ms failed**: 101,903 um against the release's 103,396 |
| R7 a number | held |

## What it decides

Not all of R1 to R7 hold, so the patch does not land and the issues stay open. Two things are left, each a design
question for a new registration:

- **A second 32-bit cost, in the joints' evaluation.** With the displacement form the velocity no longer reads the
  poses' rounding, but the joints are still evaluated on 32-bit poses, and away from the origin their correction at a
  small step reads that spacing. Featherstone, whose state is the joints' angles, plays alike at the origin and 10 m
  out.
- **The slide's comparison.** The release's own slide lengthens as the step shrinks (F2: VBD's read-back loses
  friction), and the patch's lengthens less; R6 compared the patch with a play that carries the fault. Run 115 plays
  the slide at four steps to see which settles.
