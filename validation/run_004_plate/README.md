# Run 004: the friction law, read on a plate that cannot tip

15 October 2026. Not registered: a design probe, by [`probe.sh`](probe.sh) (its predictions written into it and pushed
before the plays); reading `reading.txt`. A flat plate, 10 cm square and 1 cm thick, 1 kg (the rig's new `hz`
setting), set down from 2 mm, left 0.3 s to settle, then kicked to 1 m/s along x; friction 0.4. Coulomb's deceleration
is 3,920 mm/s2 and Coulomb's distance 127,551 um. Check on the rig: a cube play is byte-identical to run 001's. The
plate turns by 0.013 rad at most on any solver, so the friction law is read directly.

## The friction law of SemiImplicit and Featherstone

Newton's kernel (`newton/_src/solvers/semi_implicit/kernels_contact.py`, `eval_body_contact`) computes each contact's
friction as `vt / H(vt) * min(kf * H(vt), mu * N)`, where `H` is Warp's `norm_huber` (`warp/_src/math.py`): 1/2 |v|^2 up
to the width d (`friction_smoothing`), and d (|v| - d/2) above it, not divided by the width. The vector `vt / H(vt)`
that gives the friction its direction is then |v| / H(v) long, not 1: 2 / |v| below the width and about 1 / d above it.
While the plate slides fast enough for the second term to be mu N, its friction is Coulomb's times |v| / H(v).

| SemiImplicit, smoothing | Predicted near 1 m/s | Deceleration 301 to 320 ms, mm/s2 | Times Coulomb's | Distance (Coulomb 127,551 um) |
|---|---|---|---|---|
| 1.0 (default), 0.125 ms | about 2.1 times | 8,266 to 8,869 | 2.1 to 2.3 | 42,315 um |
| 1.0, 0.031 ms | | 8,545 to 9,018 | 2.2 to 2.3 | 41,971 um |
| 0.1, 0.125 ms | about 10.6 times | 46,333 to 56,293 | 11.8 to 14.4 | 9,733 um |
| 0.01, 0.125 ms | about 100 times, 200 as it stops | stops within about 1.4 ms | about 185 on average (from the distance) | **690 um** |
| 0.01, 0.031 ms | | stops within about 1.4 ms | | 710 um |

Featherstone gives the same numbers as SemiImplicit at 0.125 ms, to within 0.01%. At 330 to 350 ms, with the plate
slower, the default smoothing decelerates it at 13,124 to 14,235 mm/s2, 3.3 to 3.6 times Coulomb's, as 2 / |v| has it.

For reference, on the same plate: **XPBD** 127,470 um, decelerating at 3,919 to 3,920 mm/s2 (Coulomb's). **The MuJoCo
solver** 127,663 um; its plate leaves the ground for a few milliseconds after the kick (no friction from 301 to
305 ms) and then decelerates at 3,354 to 3,410 mm/s2, the lift-off of the MuJoCo deep dive's run 008.

## What it shows

- **The reading of the kernel holds.** The plate's friction is Coulomb's times |v| / H(v): about 2.2 times at the
  default smoothing near 1 m/s (predicted 2.1), rising as the plate slows; about 13 times at 0.1 (predicted 10.6: the
  right size, somewhat above); and at 0.01 the plate set sliding at 1 m/s stops in 0.69 mm, where Coulomb's law has
  127.6 mm, 185 times too short.
- **So N1's cause is the smoothing's normalisation, not its width.** Narrowing the width, which a user would do to
  make friction sharper, makes it larger at speed, roughly as 1 / width. The cap the kernel writes, mu N, is
  applied before the factor and does not bound the result. The excess is enough to explain the cube's tipping in runs
  001 to 003: a cube tips only where friction exceeds its weight, a coefficient above 1.
- **A correction has a clear form**: give friction a unit direction and bound its size by mu N at every speed, for
  example `vt / |vt| * min(kf * |vt|, mu * N)`, or divide the Huber norm by its width. A correction is designed first,
  then validated under a registered study's rules, as in the first deep dive.
