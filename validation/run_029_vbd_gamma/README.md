# Run 029: VBD's warm-start decay, against its losses at small steps

15 October 2026, 09:14 to 09:21 UTC, on the Newton host, by [`play.sh`](play.sh), whose hypothesis and predictions
were pushed before the plays. Not registered: a trace. Newton 1.6.1 from PyPI. Reading `reading.txt`, made with Senua
AI's `sx_contact` (`chain`, `creep`), re-made byte for byte on the laptop from the same files.

## The question

VBD gets worse as the step shrinks where its velocity read-back is not the cause: runs 025 and 026 found its free
chain's excess loss at 0.156 ms is not the 32-bit read-back, and run 001 found its hold creeping faster at small steps
(VBD 223 mm/s at 0.125 ms and 614 mm/s at 0.031 ms; VBD-ALM 74 and 406 um/s). In the source (`solver_vbd.py`), VBD
warm-starts each constraint's force from the step before, decayed by `rigid_avbd_gamma`, 0.999 a step (as Augmented
Vertex Block Descent, Giles et al., SIGGRAPH 2025, warm-starts). A per-step factor decays faster per second as the step
shrinks: 0.90 in a second at 10 ms, 0.0017 at 0.156 ms. The hypothesis: that decay is the cause.

## What was played

Run 014's free chain on VBD and VBD-ALM at 0.625 and 0.156 ms, and run 001's hold on both at 0.125 and 0.031 ms, with
`rigid_avbd_gamma` 1 (no decay) against its default 0.999.

| Reading | Gamma 0.999 (as released) | Gamma 1 |
|---|---|---|
| Free chain, energy after 2 s per million of the start: VBD, 0.625 ms | 967,735 | 967,767 |
| VBD, 0.156 ms | 961,793 | 957,071 |
| VBD-ALM, 0.625 ms | 968,602 | 967,784 |
| VBD-ALM, 0.156 ms | 923,643 | 923,643 |
| Hold, mean speed, um/s: VBD, 0.125 ms | 223,151 | 223,151 (the same file) |
| VBD, 0.031 ms | 613,739 (run 001) | 613,739 (run 001's file) |
| VBD-ALM, 0.125 ms | 74 | 74 (the same file) |
| VBD-ALM, 0.031 ms | 406 (run 001) | 406 (run 001's file) |

| Prediction | Result |
|---|---|
| P1: with gamma 1 the free chain keeps more at 0.156 ms than at 0.625 ms, on both solvers | **Failed**: 957,071 against 967,767 on VBD, 923,643 against 967,784 on VBD-ALM |
| P2: with gamma 1 the hold creeps slower than as released, at both steps on both solvers | **Failed**: every hold play with gamma 1 is the released play byte for byte |
| Check: gamma 0.999, given, gives runs 014's and 001's files | Held, all six |

No play stopped being a number.

## What it shows

- **The hypothesis is refuted.** The warm-start decay does not act on the hold at all (the plays are the same files),
  and on the chain it moves the energy by parts in 1,000 either way, leaving the excess loss at 0.156 ms in place.
- **VBD's growing errors at small steps are not its velocity read-back (runs 025, 026) nor its warm-start decay
  (this run).** Their cause is not yet traced.
