# Study 34: a fast body kept from passing through a thin slab, the patch on contacts strictly apart

**Outcome: 7 of 8 rule lines held; issue 20's tunnelling stays open on SemiImplicit and Featherstone.** Registered 21
October 2026 ([`PREREGISTRATION_34.md`](../../preregistrations/PREREGISTRATION_34.md)); played once as
[run 137](../../validation/run_137_study_34/README.md). The speculative normal's third form (contacts strictly apart)
leaves every slide and hold byte for byte as the chain plays them, but lets a cube that lands touching the slab at speed
through on SemiImplicit and Featherstone; XPBD, by Newton's own configuration, rests on the slab in every scene.

## The rules and the result

| Rule | Result |
|---|---|
| R1 safe when off | held: 8 of 8 |
| R2 the fault is there as released | held |
| R3 kept | **failed**: SemiImplicit and Featherstone in the gap, through at 4 ms and past the middle at 1.5 ms; XPBD kept everywhere |
| R4 nothing else changes | held: the slides byte for byte, the holds 6, 0 and 0 um/s |
| R5 a number | held |

## What it decides

With Study 33: a contact still apart is not the whole case; one that touches while closing fast needs the normal impulse
too, and then its friction must count it (the second form), which Featherstone's pass does not yet converge on. The
tunnelling stays open on SemiImplicit and Featherstone; on XPBD it is fixed by Newton's own configuration in every
scene played (Studies 33 and 34).
