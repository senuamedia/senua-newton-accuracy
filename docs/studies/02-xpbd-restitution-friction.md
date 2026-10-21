# Study 2: XPBD with its restitution option, no bounce and Coulomb's friction at an impact

| | |
|---|---|
| Question | XPBD bounces with a restitution of 0; its own `enable_restitution` removes the bounce but loses friction at an impact. On scenes the probes did not use, does the patch give no bounce and Coulomb's friction at and after an impact, with nothing else changed and Newton unchanged when it is off? |
| Outcome | **9 of 9 rule lines held.** The patch is validated |
| Registered | [`PREREGISTRATION_02.md`](../../preregistrations/PREREGISTRATION_02.md), 15 October 2026, pushed with its runner before any play |
| Played | Once, as [run 019](../../validation/run_019_study_02/README.md), 15 October 2026 05:17 UTC, on Linux (EC2 c7i.xlarge), Warp's CPU device, at 4 ms and 0.4 ms |
| Arms | Newton 1.6.1 from PyPI, XPBD as released and with `enable_restitution`; the patched source with the switch unset, both ways; the switch at 2, both ways |
| Measured by | The Senua AI Robotics Core's measuring programs (`bounce`, `impact`, `settle`), judged by their `rule` command |

Previous: [Study 1](01-coulomb-friction.md). All studies: [index](README.md).

## How it came about

Run 015 found XPBD's own restitution option removes its bounce but takes friction at an impact down to 4% to 43% of
Coulomb's, and Newton's source showed why: the restitution pass applies normal impulses only, while XPBD bounds
friction by the position pass's own normal correction. A first patch (run 016) gave the pass Coulomb's friction on the
normal impulse it applies, but overshot Coulomb's by up to 24%, failing the second of the five checks. The hypothesis
that it never took friction back where the pass pulls a contact down was tested in run 018 with a second form, which
held all five checks. This study is that second form, on fresh numbers, played once.

## The scenes

None of these numbers used in the probes: a cube of 1.4 kg, half-size 0.035 m; dropped from 60 mm with friction 0;
landing from 50 mm at 2.5 m/s with friction 0.35 (Coulomb's 3,500 per 10,000); and, for nothing else changing, the
cube set sliding at 1.8 m/s, set at rest, and pushed with 0.6 of what friction holds. Each at 4 ms and 0.4 ms.

## The result

| Rule | Measured | |
|---|---|---|
| R1 safe when off | 20 of 20 files byte-identical | held |
| R2 the defects are there | Released: rebounds of 850 and 1,067 per 10,000; with `enable_restitution`, friction at the impact 300 and 1,980 | held |
| R3 no bounce | Patched: 0 and 0 | held |
| R4 the impact | Patched: 3,499 and 3,499 | held |
| R5 after the impact | Patched: 3,499 and 3,499 | held |
| R6 nothing else changes | 6 of 6 files byte-identical | held |
| R7 nothing when the pass does not run | 10 of 10 files byte-identical | held |
| R8 nothing blows up | No play's state stopped being a number | held |
