# Study 33: a fast body kept from passing through a thin slab

**Outcome: 6 of 8 rule lines held; issue 20's tunnelling stays open.** Registered 21 October 2026
([`PREREGISTRATION_33.md`](../../preregistrations/PREREGISTRATION_33.md)); played once as
[run 136](../../validation/run_136_study_33/README.md). As released XPBD, SemiImplicit and Featherstone let a cube
through a 6 mm slab wherever a step carries it past; with Newton's own configuration (64 iterations and speculative
contacts) XPBD stops it on the slab, and with Senua AI's speculative normal patch SemiImplicit and Featherstone keep it
from passing through, but their slide moves by 1 in 204 against the registered 1 in 1,000.

## How it got here

| Run | What | Result |
|---|---|---|
| [060](../../validation/run_060_tunnelling/README.md) | A fast cube onto a thin slab, speculative contacts on and off | Through wherever a step carries the cube past; speculative contacts changed nothing |
| (host checks) | Why | The pipeline's gap already caught run 060's cubes; XPBD's two iterations leave the overlap; the penalty contact ignores a contact still apart |

## The rules and the result

| Rule | Result |
|---|---|
| R1 safe when off | held: 8 of 8 plays byte for byte |
| R2 the fault is there as released | held: all three through in every scene at both steps |
| R3 kept | held: none through with the configuration (XPBD at rest on the slab; SemiImplicit and Featherstone thrown back up where a 4 ms step brings the cube at speed) |
| R4 nothing else changes | XPBD and the holds held; **SemiImplicit's and Featherstone's slides failed**, 1 in 204 longer |
| R5 a number | held |

## What it decides

Issue 20's tunnelling stays open: fixed on XPBD by Newton's own configuration in every scene played; on SemiImplicit and
Featherstone the patch's first form keeps the cube from passing through and moves a slide, for a second form whose
friction bound counts the patch's normal impulse.
