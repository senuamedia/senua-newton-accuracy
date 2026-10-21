# Run 064: Study 9, played once

20 October 2026, 08:47 to 08:53 UTC, on the Newton host, by [`play.sh`](play.sh), under
[`PREREGISTRATION_09.md`](../../preregistrations/PREREGISTRATION_09.md), registered and pushed with the runner before
any play, and corrected before any play (the runner counts a play that leaves the rig's range as stopping, as the
registration's correction says). The runner's dry run (`dry/`, throwaway parameters) ran to the end first; no rule was
read from it. Played from the record at its commit 62e4fb4. Newton 1.7.0 as released (Study 7's `stock` environment)
and, for C4's second arm, Study 7's `normal` environment. Measured by Senua AI's `sx_contact` (`chain`, `creep`,
`stop`, `rest`, `bounce`, and each play's statistics line) and judged by its `rule` (`rules.txt`); the measured lines
(`measured.txt`) and the rules were re-made byte for byte on the laptop from the kept files, by the measure's laptop
build, with the plays left out. In the logs the home folder is written `~/`.

## The result: 14 of 14 rule lines held

| Rule | Measured | |
|---|---|---|
| R1 the fault is there (11) | C1 as released at 8 ms: the energy drifts by 33,864 ppm | held |
| R2 kept (11) | C1 with RK4: the energy within 1, 1, 5 and 0 ppm and the angular momentum within 1, 0, 3 and 0 ppm, at 8, 2, 0.5 and 0.125 ms | held, both lines |
| R3 the fault is there (13) | C2 as released at 8 ms: the centre's mean speed 1,079 um/s | held |
| R4 at rest (13) | C2 with RK4: the centre's largest speed in the last third 1, 3 and 19 um/s at 8, 2 and 0.5 ms | held |
| R5 the fault is there (14) | C3 with the default cone: stops being a number at every friction and step | held |
| R6 played (14) | C3 with the elliptic cone: a number throughout; the ground carries 14,669 to 14,673 mN at the end | held, both lines |
| R7 the fault is there (9) | C4 at 5 ms as released: the cube thrown 107,609 and 107,610 per 10,000 of its drop | held |
| R8 carried (9) | C4 at 1.25 and 0.3125 ms with Study 3's normal contact: no rebound, a number throughout | held, both lines |
| R9 the fault is there (10) | C5 as released at 1 ms: leaves the rig's range at step 14 | held |
| R10 played (10) | C5 with `joint_attach_kd=0`: a number throughout; its kinetic energy after 2 s 998,734, 998,732 and 998,739 per million of its start | held, both lines |

## C1: a free chain on the MuJoCo solver (issue 11)

| Energy and angular momentum after 2 s, ppm of the start | 8 ms | 2 ms | 0.5 ms | 0.125 ms |
|---|---|---|---|---|
| As released, energy | +33,864 | +9,322 | +2,377 | +616 |
| As released, angular momentum about the first joint | +22,782 | +6,206 | +1,577 | +405 |
| **RK4**, energy | **+1** | **-1** | **+5** | **0** |
| **RK4**, angular momentum | **+1** | **0** | **+3** | **0** |

As released the chain gains energy in proportion to the step (3.6 to 3.9 times less for each step four times shorter),
as run 014 found on another chain; with the MuJoCo solver's own RK4 both are kept to a few parts per million at every
step.

## C2: a spinning body on the MuJoCo solver (issue 13)

| The centre of mass, um/s | 8 ms | 2 ms | 0.5 ms |
|---|---|---|---|
| As released, mean speed | 1,079 | 269 | 56 |
| As released, largest in the last third | 2,189 | 546 | 119 |
| **RK4**, mean speed | **0** | **0** | **-10** |
| **RK4**, largest in the last third | **1** | **3** | **19** |

The motion's scale is 120 mm/s (4 rad/s about a centre 0.03 m off the origin). As released the centre moves in
proportion to the step; with RK4 it is held within 19 um/s, 1 in 6,300 of that scale, the largest at the finest step:
the 32-bit floor run 031 found, growing with the number of steps.

## C3: a slippery drop on the MuJoCo solver (issue 14)

| | Friction 0 | 0.0001 | 0.001 |
|---|---|---|---|
| Default (pyramidal) cone, 2 ms | stops at step 55 | 55 | 55 |
| Default cone, 0.25 ms | stops at step 443 | 443 | 443 |
| **Elliptic cone**, 2 ms: the ground's force at the end, mN | **14,673** | **14,673** | **14,673** |
| **Elliptic cone**, 0.25 ms | **14,669** | **14,669** | **14,669** |

With the default cone every play stops being a number at 0.11 s, the cube's first contact, at every friction; with
the elliptic cone every play is a number throughout and the ground carries the cube's weight (1.5 kg: 14,700 mN at the
registration's 9.8 m/s2) to 0.2%. MuJoCo Warp warns, for friction 0 only, that a friction below 1e-5 "may cause NaN".

## C4: a small cube's drop on SemiImplicit and Featherstone (issue 9's normal part)

| Rebound per 10,000 of the 70 mm drop | 4 kd h / m | SemiImplicit | Featherstone |
|---|---|---|---|
| As released, 5 ms | 4 | 107,609 | 107,610 |
| As released, 1.25 ms (reported) | 1 | 59 | 59 |
| As released, 0.3125 ms (reported) | 0.25 | 13 | 13 |
| **Study 3's normal contact, 1.25 ms** | 1 | **0** | **0** |
| **Study 3's normal contact, 0.3125 ms** | 0.25 | **0** | **0** |

At four times the explicit damper's bound the cube is thrown 10.8 times the height it fell from; within the bound, as
released, it rebounds a little (issue 4's rebound), and with Study 3's normal contact not at all. C4 is frictionless.

## C5: the chain on SemiImplicit (issue 10)

| | 1 ms | 0.5 ms | 0.25 ms |
|---|---|---|---|
| As released | leaves the range at step 14 | at step 19 | at step 32 |
| **`joint_attach_kd=0`**: kinetic energy after 2 s, per million of the start | **998,734** | **998,732** | **998,739** |
| `joint_attach_kd=0`: angular momentum, ppm | -325 | -326 | -326 |

As released the chain leaves the rig's range within 14 ms at every step; with the joint's penalty damper off it plays
its 2 s at every step, its kinetic energy 0.13% below the start and its angular momentum 0.03% below, the same at all
three steps: not the step's error.

## What it shows

- **Issue 14 is fixed by Newton's own configuration.** The MuJoCo solver's elliptic cone plays a contact of friction
  0, 0.0001 and 0.001 at both steps, the ground carrying the cube's weight, where the default cone stops being a number
  at the first contact in every play.
- **Issue 10 is fixed by Newton's own configuration.** SemiImplicit plays the joint chain with `joint_attach_kd=0` at
  1, 0.5 and 0.25 ms, where as released it leaves its range within 14 ms.
- **Issues 11 and 13 are fixed on the MuJoCo solver** by its own RK4: the free chain keeps its energy and angular
  momentum to 5 ppm, and the spinning body's centre is held within 19 um/s. Their other solvers (Featherstone for 11,
  VBD-ALM for 13) are not answered here.
- **Issue 9's normal part is fixed:** a step within the explicit damper's bound, m / (4 kd), with Study 3's normal
  contact, gives no rebound; at four times the bound the cube is thrown. **Issue 9 stays open.** The registration named
  it by its normal part, but the issue's own scene, a 10 cm cube held at 2 ms, is inside that bound (4 kd h / m = 0.8)
  and outside explicit friction's (h c_t = 20, [run 021](../run_021_explicit_limits/README.md)); C4 is
  frictionless, so that part was not played.
