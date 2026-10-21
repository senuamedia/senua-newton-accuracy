# Run 110: Study 21, played once

20 October 2026, 15:32 to 15:34 UTC, on the second x86-64 host, by [`play.sh`](play.sh), under
[`PREREGISTRATION_21.md`](../../preregistrations/PREREGISTRATION_21.md) as amended before any play, registered and
pushed with the runner before any play. The runner's dry run (`dry/`, throwaway parameters) ran to the end first.
Played from the record at its commit a6d0575, on Newton 1.7.0 and the engine made by [`setup_engine.sh`](setup_engine.sh).
Each play's error stream kept in `runs/err_<play>.txt`; the loop read by Senua AI's `sx_contact` (`final`) and judged by
its `rule` (`rules.txt`).

## The result: 7 of 7 rule lines held

| Rule | Measured | |
|---|---|---|
| R1 named | On, the 12 expected names found: the velocity limit on all five solvers, the effort limit on Featherstone, SemiImplicit, XPBD and VBD, the loop-closing joint on Featherstone, its limits and drive in #3552's warning on the MuJoCo solver | held |
| R2 nothing where nothing is ignored | On, no warning naming a joint feature in any plain joint's error stream | held |
| R3 off says nothing new | Off, no Senua AI warning in any limited joint's error stream | held |
| R4 nothing else changes | All 12 plays off and on byte for byte the release's | held |
| R5 SemiImplicit plays the loop | With `joint_attach_kd=0` a number throughout; joint A at 0.449998 rad (B's target 0.45), turning at 0.0002 rad/s | held, 3 lines |

Reported, the warnings as the solvers give them (here on Featherstone and the MuJoCo solver):

- *SolverFeatherstone does not apply these joint features the model configures: effort limit (joints j); velocity
  limit (joints j).*
- *SolverMuJoCo does not apply these joint features the model configures: velocity limit (joints j).*
- *SolverFeatherstone does not apply these joint features the model configures: loop-closing joints, played as if
  absent (joints b).*
- *SolverMuJoCo converts loop joint 'b' to MuJoCo equality constraints, which ignore these configured joint
  properties: limits (including limit stiffness/damping), drive.* (pull request #3552)

## What it shows

**Issue 19 is fixed and validated**: a solver that does not apply a joint feature the model sets now says so when it
is made, naming the feature and the joints, on every solver (Senua AI's patch, with pull request #3552 for the MuJoCo
solver's loop-closing joints), says nothing where nothing is ignored, and plays every scene exactly as before; and
SemiImplicit, which as released cannot play a loop-closing joint, plays it with Newton's own `joint_attach_kd=0` (issue
10's fix, Study 9) and applies its drive. The features themselves stay unapplied where Newton's documentation says so:
MuJoCo's equality constraints cannot carry a joint's limit or drive, and Featherstone plays a tree.
