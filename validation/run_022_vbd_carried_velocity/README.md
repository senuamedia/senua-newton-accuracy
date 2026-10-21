# Run 022: a patch in design, VBD's velocity carried, not read back from 32-bit positions

15 October 2026, 08:11 to 08:38 UTC. Not registered: a patch in design, held to the five checks. Played on the Newton
host by [`play.sh`](play.sh), whose cause, patch and predictions were pushed before the plays; reading `reading.txt`,
made with Senua AI's `sx_contact` (`bounce`) and its suite runner, re-made byte for byte on the laptop from the same
files, every suite's verdicts included. In the logs the home folder is written `~/`.

## The finding it answers

F2 (runs 001 and 006): VBD's bodies stop falling, in a way that fits positions held in 32-bit floats. The cause, read
in the source: after its solve, VBD reads each body's velocity back from its positions, v = (x - x_prev) / dt
(`rigid_vbd_kernels.update_body_velocity`). The difference of two 32-bit positions is a whole number of their spacing u
at the body's height, so each step adds round(g dt^2 / u) spacings to the speed instead of g dt^2 / u. That gives every
reading of run 006 by arithmetic alone:

| The cube's centre at, step | g dt^2 / u | Rounded | Fall, mm/s2 (9,800 for gravity) | Run 006 |
|---|---|---|---|---|
| 0.15 m (u 14.9 nm), 0.031 ms | 0.64 | 1 | 15,258 | 15,258 |
| 0.15 m, 0.125 ms | 10.28 | 10 | 9,537 | 9,536 |
| 1.05 m (u 119 nm), 0.125 ms | 1.28 | 1 | 7,629 | 7,629 |
| 1.05 m, 0.031 ms | 0.08 | 0 | 0 | 0 |
| 10.05 m (u 954 nm), both steps | 0.16 and 0.01 | 0 | 0 | 0 |

## The patch

[`patches/in_design/vbd_carried_velocity.diff`](../../patches/in_design/vbd_carried_velocity.diff) (sha256
f7e55ea053a62f07...), against Newton v1.6.1 (commit 713fecd). A new module, `vbd/rigid_velocity_carried.py`, holds a
copy of `update_body_velocity` whose linear velocity is v_forward + (x - x_inertia) / dt: the forward step's velocity,
which the rounded position could not hold, plus the solve's correction, a difference of two nearby positions. In exact
arithmetic it is the stock quantity, since the forward step's target is x_inertia = x_prev + dt v_forward. The angular
velocity and kinematic bodies are as in the stock kernel. `NEWTON_VBD_CARRIED_VELOCITY=1`, read once when `solver_vbd`
is imported, launches the copy in its place; nothing else changes.

## The five checks

The first deep dive's ten-test suite on VBD and on VBD-ALM (`rigid_compliant_alm`, which Newton 1.6 says will become
the default), the suite's cube dropped from 1 m and 10 m, and run 006's falls again.

| Check | Measured | |
|---|---|---|
| **1. Required** | Run 006: a body 10 m up does not fall, nor 1 m up at 0.031 ms | Held |
| **2. Correct** | With the switch, the suite's seven free plays (10 m up, 10 ms to 0.156 ms) are byte-identical to SemiImplicit's on both solvers, and run 006's falls from 0.1, 1 and 10 m at both steps byte-identical to XPBD's: VBD falls exactly as those two solvers do. The drops land at 4,425,906 um/s from 1 m and 14,000,350 from 10 m at 0.125 ms on both solvers, within 1 in 1,000 of 4,427,189 and 14,000,000. At 0.03125 ms every drop reads 3,999,774 um/s: not a landing (see below) | Held, but for four cells the measure cannot read |
| **3. Nothing else gets worse** | VBD-ALM: every line the release measured against a right answer reads no further from it; the suite now reads to the end, **5 of 10** (as released it stopped short), and the lift and the fast rebound no longer pull (T09 passes: 0 mN where the release read -23 and -8). VBD: the lift and the rebound no longer pull and the slip at 0.625 ms reads closer (1,207,300 against 1,214,400 um/s), but the hold at 0.625 ms creeps slightly faster (93,488 against 93,355 um/s) and the slide's friction reads slightly further from 4,000 (3,893 against 3,896 per 10,000); its drops at 10, 5 and 2.5 ms still sink as released, so the suite stops at 45 of 48 numbers | VBD-ALM held; **VBD not met** |
| **4. Safe when off** | The patched source with no switch: 39 of 39 suite files byte-identical to run 007's on each solver, and 16 of 16 of run 006's falls | Held |
| **5. The solver keeps converging** (here: no play stops being a number) | None did | Held |

| Prediction | Result |
|---|---|
| S1: safe when off, 39, 39 and 16 files | Held |
| C1: every drop lands at sqrt(2 g h0) within 1 in 1,000 at both steps; off, the cube does not fall | Held at 0.125 ms on both solvers. **Failed as stated** at 0.03125 ms (3,999,774 um/s whatever the height). Off, the measure reads "the cube started on the ground" for every drop: the rig records a force from the quantized fall from the first step |
| C2: the free plays byte-identical to SemiImplicit's | Held, 7 of 7 on each solver |
| C3: the suite's runner reads every test | Held on VBD-ALM; failed on VBD (45 of 48 numbers) |
| K: no play stops being a number | Held |

**Why 3,999,774 um/s at 0.03125 ms.** Read in the rig's file (`runs/drop_vbd_alm_10_0.00003125_on.txt`), outside the
measure: the rig takes the contact force from the change in the cube's 32-bit speed over a step, and a step's gain,
g dt (306 um/s), is not a whole number of that speed's spacing, so the rig writes a force of a few mN in free flight
(-1, -4 and -8 mN as the speed passes 1 and 2 m/s). At 4.0 m/s, where the speed's spacing doubles, it turns to +8 mN
(step 13,058), and the measure takes the first upward force for the landing. The cube's speed keeps gaining 306 um/s a
step past it. Any solver that falls as these do would read the same: it is the rig's force reading, not the engine.

## What it shows

- **The cause of F2 is VBD's velocity read back from 32-bit positions**, and the arithmetic of it gives run 006's
  readings to the unit.
- **The first form makes VBD fall as SemiImplicit and XPBD do**, byte for byte, at every height and step played, and
  on VBD-ALM it makes the ten-test suite readable for the first time: 5 of 10, the ground no longer pulling.
- **It is not ready**: on VBD it reads two lines slightly worse, and on the two-link chain (run 025) it leaves VBD's
  excess loss at small steps and makes some readings worse. It stays in design; its second form, which carries the
  angular velocity too, is run 026.
