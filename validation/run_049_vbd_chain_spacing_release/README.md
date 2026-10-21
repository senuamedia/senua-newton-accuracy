# Run 049: VBD's chain error against the step and the chain's place, as released and on VBD-ALM

15 October 2026, 11:26 to 11:30 UTC, on the Newton host, by [`play.sh`](play.sh), whose hypothesis and predictions
were pushed before the plays. Not registered: a trace. Newton 1.6.1 from PyPI (as released, `NEWTON_VBD_CARRIED_VELOCITY`
unset) and run 026's patched source on VBD-ALM's compliant path with Study 4's carried velocity
(`NEWTON_VBD_CARRIED_VELOCITY=2`, `opt.rigid_compliant_alm=true`). Reading [`reading.txt`](reading.txt), made with
Senua AI's `sx_contact` (`chain`), re-made byte for byte on the laptop from the same files, 24 of 24. Recorded on 19
October 2026.

## The hypothesis

Run 047 found, on VBD with the carried velocity, that the ratio of the step squared to the spacing of 32-bit positions
decides the free chain's energy error: the further the chain sits from the origin, the coarser the positions VBD's
solve holds its poses in (run 045), and the smaller the step, the more of each step's motion falls below that spacing.
VBD as released and VBD-ALM solve the poses the same way, so the same law should hold on both.

## What was played

Run 047's free two-link chain (links of 1.2 and 0.6 kg, no gravity, set turning at 2.5 and 1.5 rad/s, 2 s) with its
first joint at 0, 4, 16 and 64 m, at 0.625, 0.3125 and 0.15625 ms, on both. The reading is the largest departure of
the chain's energy from its start, in parts per million of the most energy it held (energy and angular momentum are
kept exactly with nothing acting on the chain).

| Largest energy departure, ppm | At 0 m | At 4 m | At 16 m | At 64 m |
|---|---|---|---|---|
| As released, 0.625 ms | 32,263 | 62,727 | 73,129 | **347,300** |
| As released, 0.3125 ms | 26,551 | 107,353 | **516,448** | 493,168 |
| As released, 0.15625 ms | 63,239 | **472,579** | 631,403 | 854,761 |
| VBD-ALM, 0.625 ms | 32,136 | 76,110 | 183,726 | **538,563** |
| VBD-ALM, 0.3125 ms | 28,318 | 239,256 | **505,074** | 771,336 |
| VBD-ALM, 0.15625 ms | 112,722 | **521,633** | 824,614 | 616,326 |

In bold, the three plays at a ratio of 0.051 of the step squared to the positions' spacing.

| Prediction | Result |
|---|---|
| P1: as released and on VBD-ALM, the three plays at a ratio of 0.051 each depart by more than 200,000 ppm | **Held**: 347,300 to 538,563 ppm, all six |
| P2: on both, at 0.625 ms the largest departure grows with the chain's distance from the origin, at all four distances | **Held**: 32,263, 62,727, 73,129, 347,300 as released; 32,136, 76,110, 183,726, 538,563 on VBD-ALM |

Checks: as released, the chain at the origin at 0.625 and 0.15625 ms is run 026's files byte for byte, and VBD-ALM with
the carried velocity the same; all four hold.

## What it means

- The law run 047 found holds on VBD as released and on VBD-ALM: the chain's energy error is VBD's solve keeping its
  poses in 32-bit positions, and it grows as the step shrinks or the chain moves away from the origin. It is the cause
  of F9's VBD part on every VBD path, not a property of the carried velocity.
- A correction is to hold the solve's poses with the precision the step needs, in 64 bits or relative to a local
  origin; this run is the baseline it is measured against.
