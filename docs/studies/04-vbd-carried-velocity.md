# Study 4: VBD's velocity carried, not read back from 32-bit poses

**Outcome: 5 of 5 rules held; the patch validated as registered, with readings VBD gets wrong for another cause
reported, some moved further from their answers.** Registered 15 October 2026
([`PREREGISTRATION_04.md`](../../preregistrations/PREREGISTRATION_04.md)); played once as
[run 034](../../validation/run_034_study_04/README.md).

## The question

VBD reads each body's velocity back from its 32-bit poses, so a body high enough, or a step small enough, does not fall
or falls at the wrong rate (F2). The patch carries the velocity instead. Does VBD then fall as Newton's other solvers do,
does every test that passes without the patch still pass, and is the patch safe when off?

## How it got here

| Run | What | Result |
|---|---|---|
| [006](../../validation/run_006_vbd_free_fall/README.md), [022](../../validation/run_022_vbd_carried_velocity/README.md) | The cause, and the first form | The read-back gives run 006's readings to the unit; carrying the velocity makes VBD fall as SemiImplicit does |
| [025](../../validation/run_025_vbd_chain_carried_velocity/README.md), [026](../../validation/run_026_vbd_carried_velocity_v2/README.md), [029](../../validation/run_029_vbd_gamma/README.md) | The chain, the second form, the warm-start decay | VBD's chain and hold go wrong at small steps for another cause, not traced; ruled against the released readings, both forms failed |

The registration rules "nothing else gets worse" against the right answer, as the first deep dive learned in its G8:
every test that passes without the patch must still pass; a test failing for VBD's other cause may move and is reported.

## The rules and the result

| Rule | Result |
|---|---|
| R1 safe when off: 24 of 24 files | held |
| R2 the defect is there: the fall 1.0 m and 4.6 m (summed) off SemiImplicit's | held |
| R3 the fall byte-identical to SemiImplicit's, 4 of 4 | held |
| R4 every test passing without the patch passes with it: 5 of 5, and 2 more pass (the lift) | held |
| R5 no play stops being a number | held |

Reported: on the jointed chain at 0.05 ms VBD with the patch gains 45% of the energy in 2 s (loses 8% as released) and
VBD-ALM 9% (gains 2%); VBD's hold at 0.05 ms creeps 17% faster. That error is VBD's other cause, not traced at the
study. Traced since (runs 045 and 047): VBD's solve keeps its poses in 32 bits and a joint's motion a step falls under
their spacing; read at its largest, the chain at 0.05 ms departs by about half its energy with the patch and without it
(524,931 and 537,677 ppm), the end readings above catching the swing at different places.

## The patch

[`patches/vbd_carried_velocity_v2.diff`](../../patches/vbd_carried_velocity_v2.diff) (sha256 4e33692e4797541f...), switch
`NEWTON_VBD_CARRIED_VELOCITY=2` (`=1` selects the first form, linear velocity only, not validated). See
[the patches](../patches.md).
