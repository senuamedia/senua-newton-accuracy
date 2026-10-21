# Run 028: XPBD's energy loss on the free chain, against its iterations

15 October 2026, 08:56 to 08:57 UTC, on the Newton host, by [`play.sh`](play.sh), whose hypothesis and predictions
were pushed before the plays. Not registered: a trace. Newton 1.6.1 from PyPI. Reading `reading.txt`, made with Senua
AI's `sx_contact chain`, re-made byte for byte on the laptop from the same files.

## The question

XPBD takes energy out of a free two-link chain (F9; run 014): it keeps 69.9% of the kinetic energy after 2 s at 10 ms,
89.0% at 2.5 ms, 96.7% at 0.625 ms and 99.1% at 0.156 ms. XPBD moves each body by its velocity, projects the joints
back together (2 iterations by default) and reads the velocity back from the poses. Is the loss the projection itself,
which removes the velocity along the joint's constraint every step whatever the iterations, or its solve left
unconverged, as run 027 found for most of XPBD's creep at rest?

## What was played

Run 014's free chain (arms of 1.2 and 0.6 kg, no gravity, set turning, 2 s) on XPBD at 10 ms and 2.5 ms, at 2, 8 and
32 iterations.

| Free chain, kinetic energy after 2 s, per million of the start (right answer 1,000,000) | 10 ms | 2.5 ms |
|---|---|---|
| 2 iterations (the default; run 014's files byte for byte) | 699,482 | 889,609 |
| 8 iterations | 706,671 | 889,580 |
| 32 iterations | 705,891 | 889,588 |
| Angular momentum, change, ppm, at 2 and 32 iterations | -112,925 and -113,890 | -34,734 and -34,766 |

| Prediction | Result |
|---|---|
| P1: 32 iterations leave at least half of the loss (the chain keeps at most 85% at 10 ms, 94.5% at 2.5 ms) | Held: 70.6% and 89.0% |
| P2: at 32 iterations the loss at 2.5 ms is between a sixth and a third of the loss at 10 ms | **Failed**: 110,412 against 294,108 ppm, 0.375 |

No play stopped being a number.

## What it shows

- **XPBD's loss on a free chain is its projection's own, not its solve's convergence.** Sixteen times the iterations
  leave the energy within 0.7% at 10 ms and to 3 parts in 100,000 at 2.5 ms, and the momentum's loss unchanged.
- **It approaches first order only as the step shrinks.** The loss at a step 4 times smaller is 0.375 of the loss at
  10 ms, and in run 014's chain 0.366, 0.300 and 0.276 down the steps: toward a quarter, the first-order ratio, but
  not there at these steps, which is why P2's band was too narrow.
- For a user: on a jointed body, XPBD's iterations buy nothing against this loss; only a smaller step (or substeps)
  does.
