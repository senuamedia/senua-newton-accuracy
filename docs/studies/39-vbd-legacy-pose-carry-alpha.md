# Study 39: VBD's legacy path far from the origin, its poses carried and its joint stabilisation off

**Outcome: 10 of 15 rule lines held; issue 12's VBD legacy part stays open.** Registered 21 October 2026
([`PREREGISTRATION_39.md`](../../preregistrations/PREREGISTRATION_39.md)); played once as
[run 142](../../validation/run_142_study_39/README.md). On VBD's legacy path with Senua AI's VBD displacement patch and
pose carry and Newton's own `rigid_avbd_joint_alpha=0`, a free chain's loss falls with every halving of the step at 0,
20 and 50 m from the origin, 206 and 159 ppm at 0.025 ms 20 and 50 m out against 9,301 and 7,837 with the carry unset;
but the far chain is not within 1 in 10 of the origin's departure at four of the five steps (49% above it at 20 m and
0.025 ms), so the registered bar is not met.

## How it got here

| Run | What | Result |
|---|---|---|
| [125](../../validation/run_125_far_chain_solvers/README.md)'s notes | The pose carry on both VBD paths | On the legacy path the far chain not as at the origin at the smallest steps |
| [139](../../validation/run_139_study_36/README.md) (Study 36) | The pose carry, registered | The compliant-ALM path fixed; the legacy path holds 15 m out, not 60 m out at the two smallest steps |
| Host check after Study 36 | The legacy path's joint stabilisation (`rigid_avbd_joint_alpha`) at 0 | 844 and 194 ppm at 0.05 and 0.025 ms 60 m out, against 5,269 and 5,558 at 0.95 |

## The rules and the result

| Rule | Result |
|---|---|
| R1 safe when off | held: 24 of 24 plays byte for byte the displacement patch's |
| R2 the fault is there | held: unset, 9,301 ppm at 20 m and 7,837 at 50 m at 0.025 ms, against 137 at the origin |
| R3 far as at the origin | failed at 0.4, 0.2, 0.1 and 0.025 ms (held at 0.05 ms): at 0.025 ms 206 and 159 ppm against 138 |
| R4 falls with the step | held at 0, 20 and 50 m |
| R5 nothing else worse | the spinning body's centre and the hold held; the slide failed, VBD's legacy cold slide (Study 17), the same with the carry unset to 41 um |
| R6 a number | held |

## What it decides

**Issue 12's VBD legacy part stays open.** The carry with the joint stabilisation off makes the far chain's loss fall
with the step everywhere, where without the carry it grows, but the far chain stays up to half again above the origin's
departure. With the stabilisation at its default (reported) the far chain's departure grows again at the smallest steps
(8,651 ppm at 50 m and 0.025 ms). Issue 12 (XPBD and VBD) is fixed and validated on VBD's compliant-ALM path and,
for a free chain, on XPBD; VBD's legacy path far from the origin and a chain under gravity on XPBD remain open.
