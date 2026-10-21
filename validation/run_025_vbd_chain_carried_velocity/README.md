# Run 025: VBD's two-link chain with the carried velocity (first form)

15 October 2026. Not registered: a probe of the patch in design, by [`play.sh`](play.sh), its prediction pushed
before the plays, on run 022's patched source. Reading `reading.txt`, made with Senua AI's `sx_contact chain` and the
rig's own statistics lines, re-made byte for byte on the laptop from the same files. In the logs the home folder is
written `~/`.

## The question

In run 014 VBD and VBD-ALM took energy out of a free chain, less as the step shrank to 0.625 ms but more again at
0.156 ms (VBD 3.8% against 3.2%, VBD-ALM 7.6% against 3.1%), where XPBD's loss kept falling. Run 022's first form
removes the 32-bit cancellation in VBD's linear velocity, which grows as the step shrinks. Does it remove that excess,
and is it safe when off on joints?

## What was played

Run 014's two scenes (arms of 1.2 and 0.6 kg; the free chain with no gravity, set turning; the swinging chain released
from rest; 2 s) on VBD and VBD-ALM at 10 ms over 1, 4, 16 and 64, switch off and on (`=1`).

| Free chain: kinetic energy after 2 s, per million of the start (right answer 1,000,000) | 10 ms | 2.5 ms | 0.625 ms | 0.156 ms |
|---|---|---|---|---|
| VBD, off (run 014's files) | 539,831 | 886,550 | 967,735 | 961,793 |
| VBD, on | 539,822 | 886,630 | 967,293 | **943,546** |
| VBD-ALM, off | 540,907 | 888,187 | 968,602 | 923,643 |
| VBD-ALM, on | 540,918 | 888,319 | 967,794 | **944,181** |

| Swinging chain: largest energy departure, ppm of the largest kinetic energy | 10 ms | 2.5 ms | 0.625 ms | 0.156 ms |
|---|---|---|---|---|
| VBD, off | 720,723 | 581,627 | 240,264 | 52,450 |
| VBD, on | 720,729 | 581,566 | 239,363 | 54,161 |
| VBD-ALM, off | 714,799 | 582,062 | 275,636 | 112,818 |
| VBD-ALM, on | 714,807 | 582,030 | 275,102 | **130,018** |

| Prediction | Result |
|---|---|
| S: off, 16 of 16 files byte-identical to run 014's | Held: the patch is safe when off on joints |
| P1: on, the free chain loses less at 0.156 ms than at 0.625 ms, on both solvers | **Failed** on both: it keeps 943,546 per million at 0.156 ms against 967,293 at 0.625 ms on VBD, 944,181 against 967,794 on VBD-ALM |

No play stopped being a number or left the format's range.

## What it shows

- **The first form does not remove the chain's excess loss at small steps.** With it VBD-ALM's free chain loses less
  at 0.156 ms (7.6% to 5.6%), VBD's more (3.8% to 5.6%), and VBD-ALM's swinging chain departs further (11.3% to 13.0%);
  at 10 ms and 2.5 ms almost nothing changes. Some readings get worse, so the patch's third check is not met on the
  chain.
- **A reason, read in the patch:** it carries the linear velocity but still reads the angular velocity back from
  32-bit quaternions, so a joint anchor's velocity, v + w x r, joins an exact part to a rounded one. The second form,
  carrying the angular velocity too, is run 026.
