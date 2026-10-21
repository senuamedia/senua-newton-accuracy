# Study 9: five issues answered by Newton's own options

**Outcome: 14 of 14 rule lines held.** Issues 10 and 14 are fixed by Newton's own configuration; issues 11 and 13 are
fixed on the MuJoCo solver by its own RK4, their other solvers still open; issue 9's normal part is fixed by a step
within the explicit damper's bound with Study 3's normal contact, and issue 9 stays open for its friction part, which
this study did not play. Registered 20 October 2026
([`PREREGISTRATION_09.md`](../../preregistrations/PREREGISTRATION_09.md)); played once as
[run 064](../../validation/run_064_study_09/README.md).

## The question

Five open issues each have a remedy that is one of Newton's own options, measured in a design probe but never held to
rules registered in advance. On scenes and steps no probe used, on Newton 1.7.0 as released: is each fault there, and
does the option remove it?

| Issue | The option | Measured in |
|---|---|---|
| 11, a free chain gains energy (the MuJoCo solver's half) | `integrator=rk4` | run 014 |
| 13, a spinning body's centre moves (the MuJoCo solver's half) | `integrator=rk4` | runs 030, 031 |
| 14, the MuJoCo solver cannot play a frictionless contact | `cone=elliptic` | runs 012, 023 |
| 9, a small cube unstable at large steps (its normal part) | a step at most m / (4 kd), with Study 3's normal contact | run 021 |
| 10, SemiImplicit cannot play a joint chain | `joint_attach_kd=0` | run 024 |

## The rules and the result

| Rule | Result |
|---|---|
| R1 the fault is there (11): the chain's energy drifts by 1,000 ppm or more at 8 ms | held: +33,864 ppm |
| R2 kept (11): with RK4 the energy and angular momentum within 100 ppm at 8, 2, 0.5 and 0.125 ms | held: within 5 and 3 ppm |
| R3 the fault is there (13): the centre's mean speed 1,000 um/s or more at 8 ms | held: 1,079 um/s |
| R4 at rest (13): with RK4 the centre's largest speed in the last third within 120 um/s at 8, 2 and 0.5 ms | held: 1, 3 and 19 um/s |
| R5 the fault is there (14): the default cone stops being a number at friction 0, 0.0001 and 0.001 | held, at the first contact in every play |
| R6 played (14): the elliptic cone a number throughout, the ground carrying the weight within 1 in 100 | held: 14,669 to 14,673 mN against 14,700 |
| R7 the fault is there (9): at 5 ms (4 kd h / m = 4) the cube rebounds 1,000 per 10,000 or more | held: thrown 10.8 times its drop |
| R8 carried (9): at 1.25 and 0.3125 ms with Study 3's normal contact, no rebound, a number throughout | held: 0 on both solvers |
| R9 the fault is there (10): SemiImplicit's chain stops at 1 ms | held: leaves its range at step 14 |
| R10 played (10): with `joint_attach_kd=0` a number at 1, 0.5 and 0.25 ms, its kinetic energy within 1 in 100 | held: 0.13% below the start at every step |

## What it decides

- **Issue 14, fixed and validated by configuration.** Set the MuJoCo solver's `cone="elliptic"` for any contact whose
  friction may be 0.001 or less; the default pyramidal cone stops being a number at the first contact.
- **Issue 10, fixed and validated by configuration.** Set SemiImplicit's `joint_attach_kd=0` for joint chains: the
  joint's penalty damper is what blows up (its explicit limit is h kd / m_eff < 2, run 024); its spring alone plays the
  chain at every step played, keeping 99.87% of its kinetic energy.
- **Issues 11 and 13 on the MuJoCo solver, fixed and validated by configuration.** Set `integrator="rk4"`: the chain's
  energy and the spinning body's centre are kept to a few parts per million and 19 um/s. Featherstone's chain (11) and
  VBD-ALM's spinning body (13) have no such option; both issues stay open on those solvers.
- **Issue 9, its normal part only.** Within m / (4 kd), with Study 3's normal contact, a small cube dropped at friction
  0 does not rebound; at four times that bound it is thrown. The registration named issue 9 by that part, but the
  issue's own scene, a 10 cm cube held at 2 ms, is inside the normal's bound and outside explicit friction's (run 021:
  h c_t = 20, where friction settles only near 1.25). That part was not played, and issue 9 stays open for it.
