# Run 109: Study 20, played once

20 October 2026, 15:06 to 15:08 UTC, on the second x86-64 host, by [`play.sh`](play.sh), under
[`PREREGISTRATION_20.md`](../../preregistrations/PREREGISTRATION_20.md), registered and pushed with the runner before
any play. The runner's dry run (`dry/`, throwaway parameters) ran to the end first. Played from the record at its commit
7694d65, on Newton 1.7.0, the engine made by [`setup_engine.sh`](setup_engine.sh), and MuJoCo 3.15's own engine for the
reference. Measured by Senua AI's `sx_contact` (`final`; the chains read at fixed instants from their files) and judged
by its `rule` (`rules.txt`).

## The result: 13 of 13 rule lines held

| Rule | Measured | |
|---|---|---|
| R1 safe when off | Off, all 7 A and C plays byte for byte the release's | held |
| R2 the fault is there | As released the arms turn back at 1.93 and 2.68 rad/s at 2 ms, 1.93 and 2.59 at 0.4 ms | held |
| R3 the arms held | On, A1 at 2.1995 and 2.2000 rad, A2 at 2.9000 and 2.8984, turning at under 0.005 rad/s | held, 3 lines |
| R4 the reference converged | At 2.6 s the first joint at 1.854220 and 1.854185 rad at the two time constants | held |
| R5 the reference stops the chain | The first joint at 2.400000 rad at 1.7 and 1.9 s; the second link at 5.219 rad/s, 0.41% under the closed form's 5.24 | held, 2 lines |
| R6 the fault is there on the chain | As released the first joint 23, 37 and 39 mrad off its limit at 1.9 s | held |
| R7 on the limit | On, the first joint within 2 urad of 2.4 rad at 1.7 and 1.9 s at 0.625 and 0.156 ms | held |
| R8 nearer the reference as the step shrinks | On, 0.140, 0.069 and 0.029 rad from the reference at 2.6 s at 2.5, 0.625 and 0.156 ms | held, 2 lines |
| R9 a number | Every play on a number | held |

Reported: as released at 64 iterations the arms are still thrown back (0.66 to 0.72 rad/s), so the iterations alone do
not hold them; as released the chain's first joint rattles off its limit (it turns away at up to 0.38 rad/s at 1.9 s)
and is 0.006 to 0.12 rad from the reference at 2.6 s, not nearer it as the step shrinks.

## What it shows

**Issue 8 is fixed and validated on XPBD**: with its joint angle read past pi, the swing given its exact gradient, and
the limit sized with the joint's anchor held and applied in full (the joint-angle patch's fourth form), at 64
iterations, an arm struck against its limit stops and stays, where as released it is thrown back at up to 77% of its
speed; and a chain's first joint stops dead on its limit, stays there while the limit's reaction pushes, and leaves it
as the converged hard-limit reference does, nearer it as the step shrinks. The 64 iterations are a configuration
XPBD's solve needs to converge on the chain (runs 106, 107); without the patch no count holds the arm.
