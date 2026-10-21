# Run 002: the friction smoothing, tested as the cause of N1

15 October 2026. Not registered: a design probe on run 001's machine and environment, by [`probe.sh`](probe.sh);
reading `reading.txt`. SemiImplicit and Featherstone, the slide that ends (1 m/s, friction 0.4) at 0.125 and
0.031 ms and the hold at 0.6 of the limit at 0.031 ms, with `friction_smoothing` at 1.0 (Newton's default, given
explicitly), 0.1, 0.01 and 0.001 m/s, through the rig's new `opt.<name>=` setting (the solver's own constructor
option, passed as given). Check on the rig: the four slides with 1.0 given are byte-identical to run 001's, played
without it.

## What the kernel does

Newton's contact kernel for these two solvers (`newton/_src/solvers/semi_implicit/kernels_contact.py`,
`eval_body_contact`) computes friction as `vt / vs * min(kf * vs, -mu * (fn + fd))`, where `vt` is the tangential
velocity and `vs = norm_huber(vt, friction_smoothing)`. Above the smoothing width `vt / vs` is nearly a unit vector;
below it, it is 2 x width / |vt| long. With the default width of 1 m/s, every slide slower than 1 m/s gets friction of
about 2 / v (in m/s) times Coulomb's, as run 001 measured (2.1 times near 1 m/s, 9.4 times near the end).

## The result

| | smoothing 1.0 (default) | 0.1 | 0.01 | 0.001 |
|---|---|---|---|---|
| Deceleration between 10 and 20 ms, 0.031 ms, SemiImplicit (Coulomb: 3,920 mm/s2) | 9,608 | 5,639 | **3,922** | 3,814 |
| The same, Featherstone | 9,608 | 5,635 | **3,918** | 3,809 |
| Distance reached, SemiImplicit, 0.031 ms (Coulomb: 127,551 um) | 42,974 | 37,053 | 39,216 | 39,672 |
| Then come back by | 11,796 | 33,218 | 38,235 | 39,028 |
| Largest turn of the cube while sliding | 0.22 rad | 0.55 rad | 0.62 rad | 0.64 rad |
| Largest backward force in the first 5 ms, SemiImplicit, 0.125 ms | 7.4 N | 409 N | 1,168 N | 1,877 N |
| The cube's speed after 1 ms, the same play | 0.999 m/s | 0.993 m/s | 0.628 m/s | 0.577 m/s |
| The hold: creep at 0.031 ms, both solvers | 735 um/s | 735 | 735 | 735 |

Featherstone's distances and turns follow SemiImplicit's to within 0.5% (the onset forces were read on SemiImplicit only).

## What it shows

- **The smoothing is the cause of the excess friction while the cube slides**: at a width of 0.01 m/s the deceleration
  is Coulomb's to within 0.05% on both solvers. N1's reported cause is confirmed for the steady slide.
- **Narrowing it does not give back Coulomb's slide.** The narrower the smoothing, the harder the first millisecond:
  as the cube, set sliding with its face on the ground, comes into contact, it takes a backward force of up to 1.9 kN
  (against a weight of 9.8 N) and loses up to 42% of its speed, tips forward by up to 0.64 rad, and rocks back nearly
  to where it started. A rigid cube with friction 0.4 does not tip at all. The kernel caps each contact's friction at
  mu times that contact's normal force, yet the backward force here is 5 to 238 times the vertical force at the same
  step, so something besides friction as written acts at the onset: the next probe looks at each contact's normal
  and force through Newton's own contact data, and starts the cube settled at rest before it is set sliding.
- **The hold does not depend on the smoothing**: its creep, 735 um/s, is the push over four corners' friction
  stiffness, the viscous branch of the same law, below every width tried.

Next: the onset (each contact's normal and force), the slide from a settled cube, and the hold against the friction
stiffness kf.
