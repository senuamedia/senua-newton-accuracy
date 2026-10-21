# Run 011: the friction at which Newton's MuJoCo solver starts to play

15 October 2026. Not registered: a design probe, by [`probe.sh`](probe.sh) (pushed before its plays); reading
`reading.txt`. Runs 009 and 010 found Newton's MuJoCo solver stopping being a number at the first contact of the
suite's drop with a friction of 1e-5 and of 2e-5, above MuJoCo Warp's stated floor of 1e-5. The suite's drop (2 kg,
half-size 0.04 m, from 80 mm, 0.5 s) on the MuJoCo solver, with frictions from 1e-4 to 0.3, at 2.5 ms and 0.156 ms.
No play raised a warning.

| Friction | 2.5 ms | 0.156 ms |
|---|---|---|
| 0.0001 | stops being a number at step 51 (the first contact) | at step 822 (the first contact) |
| 0.001 | at step 51 | at step 818 |
| 0.01 | plays | plays |
| 0.03, 0.1, 0.3 | plays | plays |

## What it shows

Newton's MuJoCo solver stops being a number at the first contact of a shape whose friction is 0.001 or less, at both
steps, with no warning; it plays from 0.01 up. The floor MuJoCo Warp warns of is 1e-5, a hundred times lower, and
MuJoCo's C engine plays every friction. Any near-frictionless surface (ice, a lubricated part, a frictionless test
contact) is out of reach of the MuJoCo solver as Newton ships it. The cause, between 0.001 and 0.01, is not yet
traced.
