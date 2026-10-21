# Run 034: Study 4, played once

15 October 2026, 09:45 to 10:10 UTC, on the Newton host, by [`play.sh`](play.sh), under
[`PREREGISTRATION_04.md`](../../preregistrations/PREREGISTRATION_04.md), registered and pushed with the runner before
any play. The runner's dry run (`dry/`, throwaway parameters, the on arm only) ran to the end first; no rule was read
from it. Measured by Senua AI's `sx_contact` (`gap`, `creep`, `rest`, `pull`, `chain`), judged by its `rule`
(`rules.txt`, with each test's own rule lines in `tests.txt`); the measured lines, the tests and the rules were re-made
byte for byte on the laptop from the kept files. In the logs the home folder is written `~/`.

## The result: 5 of 5 rules held

| Rule | Measured | |
|---|---|---|
| R1 safe when off | 24 of 24 files byte-identical (off to stock) | held |
| R2 the defect is there | stock: the fall departs from SemiImplicit's by 1,003,631 um at 0.2 ms (it falls 21% fast) and 4,633,985 um at 0.05 ms (it does not fall), summed over 30 instants, on both solvers | held |
| R3 the fall | on: the fall byte-identical to SemiImplicit's, 4 of 4 | held |
| R4 what passes still passes | Of the 16 tests, stock passes 5 (the rest at both steps on both solvers, VBD-ALM's hold at 0.2 ms); on passes all 5, and 2 more (the lift at 0.2 ms on both solvers) | held |
| R5 nothing blows up | No play of the on arm stopped being a number | held |

## Reported, not ruled: the tests VBD fails as released

As registered, a test the release fails for another cause may move; each is reported with its distance from the
answer. The causes are those cited in the registration (runs 001, 025, 026, 029).

| Reading (right answer) | Solver, step | As released | With the patch |
|---|---|---|---|
| The lift's lowest ground force, mN (0 or more) | both, 0.2 ms | -366 | **0** (passes) |
| | both, 0.05 ms | -2,750 | -3 |
| The slide's friction over normal, per 10,000 (3,000) | VBD, 0.2 / 0.05 ms | 2,906 / 1 | 2,905 / 0 |
| | VBD-ALM, 0.2 / 0.05 ms | 3,039 / 234 | 3,039 / 267 |
| The hold's mean speed, um/s (0) | VBD, 0.2 / 0.05 ms | 255,312 / 781,969 | 255,805 / **916,115** |
| | VBD-ALM, 0.05 ms | 203 | 224 |
| The free chain's energy after 2 s, per million of the start (1,000,000) | VBD, 0.2 / 0.05 ms | 992,416 / 915,739 | 983,503 / **1,451,104** |
| | VBD-ALM, 0.2 / 0.05 ms | 955,188 / 1,021,708 | 981,456 / **1,089,095** |

The largest moves away from the answer are on the chain at 0.05 ms, where VBD with the patch gains 45% of the chain's
energy in 2 s (it loses 8% as released) and VBD-ALM 9% (2% as released), and VBD's hold at 0.05 ms (17% faster). Run
025 to 029 found that VBD's chain and hold go wrong at small steps for a cause neither the read-back nor the
warm-start decay explains; with the read-back corrected that cause shows more at 0.05 ms. It is not traced.

## What it shows

**The patch is validated as registered.** On scenes and steps no probe used, VBD and VBD-ALM with the velocity carried
fall exactly as SemiImplicit does, where as released they fall 21% fast or not at all; every test VBD passes as released
it still passes, and the lift's phantom ground pull goes; with the switch unset, Newton plays byte for byte as released.
The readings VBD gets wrong for its other cause move, some further from their answers, the jointed chain at the
smallest step most of all: that cause is VBD's open finding, now the larger error there.
