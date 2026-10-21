# Run 091: VBD-ALM's hold against the step (issue 6)

Not registered: a design probe that decides nothing and states no prediction. Run 089 found VBD's hold creeping faster
as the step shrinks (12 to 223 mm/s) and VBD-ALM holding at 2 and 0.5 ms but creeping 74 um/s at 0.125 ms. Here
VBD-ALM's hold at seven steps from 4 ms to 62.5 us, at its default iterations and at 40: where it holds, and whether
its creep at small steps follows the step (32-bit positions) or the iterations.

## What it measured

Played 20 October 2026 on the Newton host (`started.txt`, `finished.txt`); each play's reading in `measured.txt`.

| Step | Default iterations: mean speed | 40 iterations: mean speed |
|---|---|---|
| 4 ms | 7 um/s | 0 |
| 2 ms | 1 um/s | 0 |
| 1 ms | 0 | 0 |
| 0.5 ms | 0 | 0 |
| 0.25 ms | 99 um/s | 36 um/s |
| 0.125 ms | 74 um/s | 24 um/s |
| 0.0625 ms | 225 um/s | 95 um/s |

VBD-ALM holds the cube from 4 ms to 0.5 ms (within 7 um/s at its default iterations, still at 40) and creeps at 0.25
ms and below. Four times its iterations cut the creep to between a third and two fifths but do not remove it, and the
creep does not follow the step (99, 74 and 225 um/s as it halves): neither a solve left unconverged alone nor a
rounding in proportion to the step. Issue 6 stays open on VBD-ALM at small steps, and on VBD (run 089).
