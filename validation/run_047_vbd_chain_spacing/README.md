# Run 047: VBD's chain error against the step and the chain's place together

15 October 2026, 11:16 to 11:18 UTC, on the Newton host, by [`play.sh`](play.sh), whose hypothesis and predictions
were pushed before the plays. Not registered: a trace. Run 026's patched source, switch `2` (Study 4's validated
carried velocity). Reading `reading.txt`, made with Senua AI's `sx_contact chain`, re-made byte for byte on the laptop
from the same files. In the logs the home folder is written `~/`.

## The question

Run 045 traced VBD's chain error at small steps to its solve's 32-bit positions: a joint's increment a step, about
(h^2 / m) F, falls under the spacing of the positions. If so, what decides the error is the ratio of h^2 to the spacing
at the chain's place, not the step or the place alone. The chain spans x0 to x0 + 0.7 m; the spacing is 6.0e-8 m at the
origin, 4.8e-7 m at 4 m, 1.9e-6 m at 16 m and 7.6e-6 m at 64 m. The ratio h^2 / spacing, in s^2 / m (VBD at 0.05 ms at
the origin: 0.042), is 6.5, 0.81, 0.20 and 0.051 at 0.625 ms; 1.6, 0.20, 0.051 and 0.013 at 0.3125 ms; 0.41, 0.051,
0.013 and 0.0032 at 0.15625 ms. (The script's comment names the ratio's unit wrongly, "units of 1e-9 s^2 / 6e-8 m";
its numbers are h^2 / spacing in s^2 / m, as here.)

## What was played

Run 014's free chain (no gravity, 2 s) on VBD with the carried velocity, the first joint at x0.

| Largest departure of the energy, ppm of its most (ratio h^2 / spacing) | x0 = 0 | 4 m | 16 m | 64 m |
|---|---|---|---|---|
| 0.625 ms | 31,979 (6.5) | 51,229 (0.81) | 64,659 (0.20) | **467,058** (0.051) |
| 0.3125 ms | 26,567 (1.6) | 76,450 (0.20) | **415,665** (0.051) | 457,871 (0.013) |
| 0.15625 ms | 68,148 (0.41) | **426,927** (0.051) | 504,348 (0.013) | 661,207 (0.0032) |

| Prediction | Result |
|---|---|
| P1: the three plays at a ratio of 0.051 each depart by more than 200,000 ppm | Held: 467,058, 415,665 and 426,927 |
| P2: at each step the departure grows with x0 | Held at all three steps |
| Checks: x0 = 0 at 0.625 and 0.15625 ms, run 026's files | Held |

No play stopped being a number.

## What it shows

- **The ratio decides it.** Three plays at different steps and places but the same ratio of h^2 to the spacing (0.051)
  depart alike, 42% to 47%, as VBD at 0.05 ms at the origin (ratio 0.042, 52%); the two at 0.20 depart alike too
  (6.5% and 7.6%). Between a ratio of 0.20 and 0.051 the chain stops being the chain: there the joint's increment a
  step, (h^2 / m) F, about the ratio times 11 m/s^2 for these arms, falls from about two spacings to about half of one.
- For a user: VBD's jointed bodies need their joints' motion a step to be several 32-bit spacings of their positions,
  which a smaller step or a scene far from the origin takes away. At the origin this chain departs by 7% at
  0.156 ms and by half at 0.05 ms; 64 m from the origin it departs by 47% at 0.625 ms.
