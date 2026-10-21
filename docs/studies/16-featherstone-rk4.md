# Study 16: Featherstone's step as the classic Runge-Kutta scheme

**Outcome: 9 of 9 rule lines held; issue 11 fixed and validated on Featherstone** by Senua AI's RK4 patch. Registered
21 October 2026 ([`PREREGISTRATION_16.md`](../../preregistrations/PREREGISTRATION_16.md)); played once as
[run 100](../../validation/run_100_study_16/README.md).

## How it got here

| Run | What | Result |
|---|---|---|
| [014](../../validation/run_014_chain/README.md) | A free chain's energy on every solver | Featherstone gains in proportion to the step, 9.7% in 2 s at 10 ms |
| [064](../../validation/run_064_study_09/README.md) (Study 9) | The MuJoCo solver's own RK4 | The chain within 5 ppm at every step: fixed there by configuration |
| [096](../../validation/run_096_featherstone_rk4/README.md) | Featherstone's step in four stages, as MuJoCo's RK4 | The free chain within 14 ppm, a swinging chain within 7 ppm at 2.5 ms; the suite's T01 and T08 ask for a first-order scheme's convergence |

## The rules and the result

| Rule | Result |
|---|---|
| R1 safe when off | held |
| R2 the fault is there: as released 100 ppm or more | held: 9,934 to 416 ppm |
| R3 the free chain's energy and momentum within 20 ppm | held: within 7 and 2 ppm |
| R4 the swinging chain within 100 ppm at 2 and 0.5 ms, 1,000 at 5 ms | held: 3, 7 and 20 ppm |
| R5 a number | held |
| R6 no suite verdict lost, T01 and T08 aside | held |
| R7 T01's and T08's gaps no larger than the release's | held, at every halving |

## What it decides

**Issue 11 on Featherstone, fixed and validated:** [`featherstone_rk4.diff`](../../patches/newton-1.7.0/featherstone_rk4.diff),
switch `NEWTON_FEATHERSTONE_RK4=1`. With the MuJoCo solver's own RK4 (Study 9) issue 11 is fixed on both the solvers it
was reported on.
