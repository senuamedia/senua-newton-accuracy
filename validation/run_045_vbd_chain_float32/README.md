# Run 045: VBD's jointed-chain error at small steps, against where the chain is in the world

15 October 2026, 11:10 to 11:12 UTC, on the Newton host, by [`play.sh`](play.sh), whose hypothesis and predictions
were pushed before the plays (with the chain rig's new `x0`, the first joint's place along x, a no-op when not given).
Not registered: a trace. Run 026's patched source (switch `2`: Study 4's validated carried velocity; `0`: unset, the
release). Reading `reading.txt`, made with Senua AI's `sx_contact chain`, re-made byte for byte on the laptop from the
same files. In the logs the home folder is written `~/`.

## What the existing plays already said

Read with the chain measure on the first n steps of each file (the header's step count set to n), VBD's free chain at
0.05 ms leaves the right trajectory within milliseconds: after 5 ms its second joint turns at 1.728 rad/s where the
MuJoCo solver's RK4 (its energy kept to 5 ppm, run 014) gives 1.649, and after 0.1 s at 8.44 rad/s against 4.88. Its
energy swings with the motion, as released and with Study 4's patch alike (13% over after 0.1 s on both). At its
largest it departs by 537,677 ppm as released and 524,931 with the patch; the end readings that runs 038 and 041
compared (915,739 and 1,451,104) differ only in where the swing ends. At 0.625 ms the largest departure is 31,979 ppm
and at 0.2 ms 23,161.

## The hypothesis, read in the source

VBD's rigid solve (`rigid_vbd_kernels.py`, `solve_rigid_body`) keeps each body's pose in 32-bit floats and, every
iteration, adds the solve's increment to it: `com_new = com_current + x_inc`, and the inertial term of the next
iteration is `(com_star - com_current) * m / h^2`. A joint's share of a step's motion is about (h^2 / m) F: for these
arms some 3e-8 m a step at 0.05 ms, under the 32-bit spacing of a position 0.5 to 1 m from the origin (6e-8 m). So the
joint's increments are rounded away or to whole spacings, and the inertial term built from rounded positions is wrong
by up to m / h^2 times half a spacing (some 7 N for the 0.6 kg arm at 0.05 ms, as large as the joint forces), the same
32-bit arithmetic that stopped VBD's bodies falling (F2), here inside the solve. If so the error depends on where the
chain is, which the physics does not.

## What was played

Run 014's free chain (arms of 1.2 and 0.6 kg, no gravity, set turning, 2 s), the first joint at x0.

| Free chain, largest departure of the energy, ppm of its most (end reading per million of the start) | x0 = 0 | x0 = 10 m | x0 = 100 m |
|---|---|---|---|
| VBD with the carried velocity, 0.625 ms | 31,979 (968,020; run 026's file) | 90,881 (907,820) | **419,732** (425,630) |
| VBD with the carried velocity, 0.2 ms | 23,161 (983,503; run 038) | **500,862** (412,666) | |
| VBD with the carried velocity, 0.05 ms | 524,931 (Study 4) | | 615,525 (26,100) |
| VBD as released, 0.625 ms | 32,263 (run 026) | | 602,012 (352,905) |
| VBD-ALM with the carried velocity, 0.625 ms | | | 456,898 (484,602) |
| Featherstone, 0.625 ms | 6,019 (1,006,055; run 014's file) | | 9,070 (1,009,154) |
| XPBD, 0.625 ms | 32,625 (967,374) | | 23,979 (976,019) |

| Prediction | Result |
|---|---|
| P1: VBD with the carried velocity at 0.625 ms, the chain at 100 m, departs by more than 200,000 ppm | Held: 419,732 |
| P2: the same at 0.2 ms at 10 m, more than 200,000 ppm | Held: 500,862 |
| P3: Featherstone at 0.625 ms at 100 m, within 1,000 ppm of its play at the origin | **Failed**: 9,070 against 6,019 |
| Checks: x0 not given, VBD with the carried velocity at 0.625 ms run 026's file, Featherstone run 014's | Held, both |

No play stopped being a number. The momentum fields are about the world's origin, so not the chain's at an x0 other
than 0, and are not read.

## What it shows

- **Traced: VBD's chain error at small steps is its solve's 32-bit positions.** Moved 100 m from the origin, where
  the spacing is 128 times coarser, VBD's chain at 0.625 ms departs from its energy as it does at 0.05 ms at the
  origin, 13 times further than at the origin at the same step; moved 10 m, its chain at 0.2 ms does too. Nothing in
  the physics depends on where the chain is. VBD as released and VBD-ALM do the same: it is the solve, not Study 4's
  patch, and not the velocity read-back (runs 025, 026), the warm-start decay (029), the penalty's start (038) or the
  joint stiffness (041), each of which only moved where the rounding fell.
- **Study 4's patch did not make the chain worse.** At 0.05 ms the chain departs by 52% to 54% at its largest with or
  without it; the end readings compared in Study 4 and runs 038 and 041 caught the swing at different places.
- **P3 failed: Featherstone is not translation-invariant either**, though far less: 100 m from the origin its largest
  departure grows from 6,019 to 9,070 ppm and its trajectory moves (its joints end at -0.551 rad and 5.17 rad/s
  against -0.649 and 4.31). Its state is the joints' angles; where it loses precision far from the origin is not traced
  here. XPBD's moves the other way (32,625 to 23,979). VBD's is the only one that becomes a different simulation.
- A correction has to keep the solve's increments out of the rounding: VBD's block solve carried as a displacement from
  the step's inertial target (as implicit solvers solve for increments), the inertial term built from it and the
  velocity from it, the pose formed only to evaluate the joints. Run 047 measures how the error follows the ratio of
  h^2 to the spacing first.
