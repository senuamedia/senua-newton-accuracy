# Run 095: VBD's hold against its own friction_epsilon (issue 6)

Not registered: a design probe, its prediction pushed with [`play.sh`](play.sh) before any play. Newton 1.7.0 from PyPI
as released.

## Why

Run 089 found VBD's hold creeping faster as the step shrinks, 12, 58 and 223 mm/s at 2, 0.5 and 0.125 ms, and run 091
VBD-ALM's holding from 4 to 0.5 ms. VBD's contact friction is IPC's (Li et al., Incremental potential contact, 2020):
below a slip of eps_u = `friction_epsilon` times the step, the friction force is mu N (2 - u / eps_u) u / eps_u, a
spring, so a load inside the limit is held only at a slip a step. For run 044's hold, pushed at 0.6 of what friction
holds, the slip y eps_u a step solves 2y - y^2 = 0.6, y = 0.3675, and the creep is y times `friction_epsilon`: 3,675
um/s at its default 1e-2, at every step. That is less than VBD creeps; here the hold against `friction_epsilon` (a
constructor option of Newton's VBD) and the iterations.

## What is played

VBD and VBD-ALM, run 044's hold (1 kg, half-size 0.05 m, friction 0.5, pushed by 2.94 N from 0.5 s, 2 s), at
`friction_epsilon` 1e-2, 1e-3, 1e-4 and 1e-5, at 2, 0.5 and 0.125 ms, at the default iterations and at 40.

## Prediction (pushed before the plays)

| Check | Prediction |
|---|---|
| C1 | VBD at 40 iterations creeps as IPC's law has it, 0.3675 times `friction_epsilon` within 1 in 10, at every step: 3,307 to 4,043 um/s at 1e-2, 330 to 405 at 1e-3, 33 to 41 at 1e-4, 3 to 5 at 1e-5 |

Reported: VBD at its default iterations, VBD-ALM at both.

## What it found

Played 20 October 2026 on the arm64 host (`started.txt`, `finished.txt`), the x86-64 hosts being busy; its readings
made from the play files by the record's measure on an x86-64 host (the arm64 host has none), in `measured.txt`, the
check in [`checks.txt`](checks.txt). **The prediction failed, and its premise with it.**

| Play | Default iterations: 2, 0.5, 0.125 ms | 40 iterations: 2, 0.5, 0.125 ms |
|---|---|---|
| VBD, every `friction_epsilon` | 12,396, 58,208, 223,151 um/s | 1,921, 14,011, 58,811 um/s |
| VBD-ALM, 1e-2 | 1, 0, 74 um/s | 0, 0, 24 um/s |
| VBD-ALM, 1e-3 | 1, -2, 59 um/s | 0, 0, 60 um/s |
| VBD-ALM, 1e-4 | 1, -48, 53 um/s | 0, 72, 21 um/s |
| VBD-ALM, 1e-5 | 1, -58, 40 um/s | 0, 18, 54 um/s |

- **`friction_epsilon` does not reach VBD's rigid contact**: each VBD play is byte for byte the same at all four
  values. VBD's body contact is not IPC's: on its default path (`rigid_contact_hard=True`, the legacy AVBD path) its
  friction is the Coulomb projection of the contact's penalty times the slip plus a carried multiplier
  (`rigid_vbd_kernels.py`, the hard/ALM branch), `friction_epsilon` entering only the ALM path's sliding metric. IPC's
  smoothed friction is the soft path's, unused here; the prediction worked from it does not apply.
- **VBD's creep falls with its iterations**: four times the iterations cut it six times at 2 ms, four times at 0.5 and
  0.125 ms. Its penalty is fixed at the contact's stiffness while the ramp is off (`rigid_avbd_beta=0`, Newton's
  default; Newton's documentation), and at small steps the body's inertia over the step, m / dt^2, is far larger, so
  each iteration moves the contact's multiplier only a little: a solve left unconverged within the step, worse as the
  step shrinks. Newton's documentation marks this path deprecated since 1.6, its default to become the compliant ALM
  path (`rigid_compliant_alm=True`, VBD-ALM here).
- **VBD-ALM holds at 2 ms**, within 1 um/s, at every `friction_epsilon`; at 0.5 ms within 2 um/s at 1e-2 and 1e-3 and
  up to 72 um/s at the smaller ones; at 0.125 ms it creeps 21 to 74 um/s at every value and iteration count.
