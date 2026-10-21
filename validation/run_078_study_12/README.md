# Run 078: Study 12, played once

20 October 2026, 11:18 to 11:19 UTC, on the Newton host, by [`play.sh`](play.sh), under
[`PREREGISTRATION_12.md`](../../preregistrations/PREREGISTRATION_12.md), registered and pushed with the runner before
any play. The runner's dry run (`dry/`, throwaway parameters) ran to the end first; no rule was read from it. Played from
the record at its commit 29691d9, on Newton 1.7.0 and the two engines made by [`setup_engine.sh`](setup_engine.sh).
Measured by Senua AI's `sx_contact` (`final`, `swing`, each play's statistics line and last line) and judged by its
`rule` (`rules.txt`). In the logs the home folder is written `~/`.

## The result: 20 of 21 rule lines held; R4 failed

| Rule | Measured | |
|---|---|---|
| R1 safe when off (27) | 12 of 12 S1 and S2 plays byte for byte the release's | held |
| R2 the fault is there (27) | As released S1 turns at 37,697 and 18,849 urad/s (defaults) and 37,699 and 18,850 (the report's settings) after one step of 1 and 0.5 ms | held |
| R3 held past a full turn (27) | With the patch S1's speed 0 or -1 urad/s after 1 and 800 steps, its reading unchanged to 1 urad | held, 5 lines |
| R4 the fault is there (27) | As released S2's first angle after 600 steps: 1.077 and 1.096 rad at 2 ms, but 0.2495 and 0.2498 rad at 0.5 ms, under the registered 0.25 | **failed** |
| R5 the D6 held (27) | With the patch S2 at 0.200000 and 0.400000 rad, at both steps and settings | held, 8 lines |
| R6 safe when off (28) | 8 of 8 S3 and S4 plays byte for byte the release's | held |
| R7 the fault is there (28) | As released the light arm stops being a number at steps 17, 33, 125 and 1,383 (1/240 s to 50 us), the serial arm at 20, 38, 148 and 3,448 | held |
| R8 a number (28) | At `=3` every play a number throughout | held |
| R9 at rest on the limit (28) | At `=3` the limited joint's last angle -0.600001 or -0.600002 rad at every step, its last speed -28 to 560 urad/s | held, both lines |

## The readings

| The light arm (bound 11.5 us), `=3` | 1/240 s | 2 ms | 0.5 ms | 50 us |
|---|---|---|---|---|
| Last angle, rad (limit -0.6) | -0.600002 | -0.600002 | -0.600002 | -0.600002 |
| Last speed, urad/s | -2 | -3 | 34 | 560 |
| Turns back after its first strike at, rad (reported) | -0.598 | -0.507 | -0.547 | -0.600 |

| The serial arm, `=3`: the first joint at the end | 1/240 s | 2 ms | 0.5 ms | 50 us |
|---|---|---|---|---|
| Angle, rad; speed, urad/s | -0.600002; -28 | -0.600001; -8 | -0.600001; 15 | -0.600002; 59 |

| The D6 after 600 steps, as released, rad (targets 0.2 and 0.4) | 2 ms | 0.5 ms |
|---|---|---|
| Newton's defaults | 1.077, 0.659 | 0.2495, 0.4421 |
| The report's settings | 1.096, 0.663 | 0.2498, 0.4423 |
| With the patch, both settings | **0.200000, 0.400000** | **0.200000, 0.400000** |

## What it shows

- **Issue 28 is fixed and validated on Featherstone** by the limit patch's third form: a light arm and a serial arm
  resting on a joint limit, which as released stop being a number at every step from 1/240 s to 50 us, stay numbers and
  rest on the limit at every step, the limited joint within 2 urad of it. The first strike's rebound at large steps
  (reported) is a transient: the arm comes to rest on the limit in every play.
- **Issue 27: its fix holds everywhere, but the study does not decide it.** With the patch the drive holds its joint past
  a full turn and the D6 holds at its targets exactly, at both steps and settings; as released the drive turns at up to
  37,699 urad/s after one step and the D6 drifts. The registered fault rule R4 asked the release's D6 to drift to 0.25
  rad in 600 steps: at 2 ms it reached 1.08 rad, at 0.5 ms (0.3 s) only 0.2495 rad, 0.05 rad from its target and 455
  urad under the bound. The rule failed, and by the registration issue 27 stays open; its next study sizes the D6's
  fault rule from this run's drift.
