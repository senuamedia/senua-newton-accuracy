# Run 070: Featherstone's implicit joint limit decided on the force it applies (issue 28)

Not registered: a design probe, its predictions pushed with [`play.sh`](play.sh) before any play. Newton 1.7.0 from
PyPI, and the same with the Featherstone limit patch's third form first on the path
([`featherstone_limit_v2_on_1.7.0.diff`](../../patches/in_design/featherstone_limit_v2_on_1.7.0.diff), sha256
1bf1a3bbcf7001bd...; its first two forms unchanged in it).

## The third form

`NEWTON_FEATHERSTONE_LIMIT=3`: the second form's linearly implicit limit, launched after the step's joint-space inertia
H is built and before its Cholesky factorization. For each degree of freedom past its limit it estimates the step's
acceleration of that degree of freedom alone, qdd = (tau + f) / (H_jj + armature + h kd + h^2 ke), with
f = ke (limit - q - h qd) - kd qd, and keeps the limit (f added to tau, h kd + h^2 ke to the diagonal) only where the
force the implicit step applies, f - (h kd + h^2 ke) qdd, pushes the joint back inside its range. The coupled solve
then gives the step's accelerations. The default, untiled path only (with `use_tile_gemm` the solver refuses `=3`).

## What is played

Run 068's scenes: the light arm (0.05 kg, I = 2.333e-5 kg m^2, onto -0.5 rad) at 1/240 s, 1 ms, 250, 20, 5 and 2 us;
run 042's strike at 0.1 and 1 kg, 0.25 and 0.0625 ms; Study 9's free chain at 2 ms. As released, the switch unset, `=1`
and `=3`. A held arm is now read as run 068 found it must be: a number throughout, its last angle within 1 in 100 of
the limit, and the arm not coming back up off the limit by more than 1 in 100 (where it turns back after its first
strike, `sx_contact swing`; no turn back counts as at the limit).

## Predictions (pushed before the plays)

| Check | Prediction | Why |
|---|---|---|
| G0 | With the switch unset every play byte for byte the release's (11 of 11) | The stock kernels |
| G1 | `=1`'s four strikes byte for byte run 068's | Its code is unchanged |
| G2 | `=3` holds the light arm at every step, 1/240 s to 2 us: a number, the last angle within 1 in 100 of -0.5 rad, no bounce off it of more than 1 in 100 | The limit no longer let go while the arm leaves it fast; backward Euler has no step bound |
| G4 | `=3`'s strike turns back within 0.02 rad of -0.815 rad (0.1 kg, 0.0625 ms) and of -0.450 rad (1 kg, both steps) | The no-tension form, the release no longer early |
| G5 | `=3`'s free chain byte for byte the release's | No limit, no change |

Reported: `=3`'s 0.1 kg strike at 0.25 ms (h w = 0.2 a step, backward Euler's own damping not small there).

## The result: 5 of 8 checks held

Played 20 October 2026 on the second x86-64 host, from the record at 93361c6 (these predictions pushed).

| Light arm, `=3` | 1/240 s | 1 ms | 250 us | 20 us | 5 us | 2 us |
|---|---|---|---|---|---|---|
| Stops being a number | never | never | never | never | never | never |
| Last angle, urad (limit -500,000) | -500,001 | -500,001 | -500,001 | -500,002 | -500,007 | -500,016 |
| Last speed column, urad/s | 7 | 17 | 75 | 1,436 | 5,905 | 14,786 |
| Turns back after the first strike at, urad | **-342,056** | **-473,977** | -497,700 | none | none | none |

G0 (11 of 11), G1 (`=1`'s strikes byte for byte run 068's), G2's numbers and angle, and G5 held; G2's bounce line and
G4 (both lines) failed. `=3`'s strikes are `=2`'s of run 068 to the microradian (-0.843, -0.836, -0.517, -0.474 rad).

- **The third form brings the light arm to rest on its limit at every step**, where the second chattered at large
  steps (0.79 rad/s at 1/240 s): the last speed is 7 to 75 urad/s from 1/240 s to 250 us (at 20 us and below the speed
  column is the 32-bit stuck angle's, run 068). It never stops being a number.
- **The first strike still rebounds at large steps**, to -0.342 rad at 1/240 s. The arm falls freely through the step
  in which it reaches the limit, and the limit acts only from the next: at 1/240 s it is 84 mrad past the limit when it
  first acts, against the 47 urad the spring and damper would stop it in (I v0 / kd; the limit's damping ratio is 10),
  and the implicit spring takes it back out of that depth in a few steps, faster than the no-tension form's creep. The
  third form's test changes nothing there: for so heavily damped a limit the force the implicit step applies is near
  zero throughout the creep out, and the implicit step's solution is the second form's. The cure in the method's own
  terms is to let the limit act in the step that would carry the joint past it (a speculative limit, as speculative
  contacts are: Catto, GDC 2013), not to tune it.
- For issue 28 (Featherstone diverges on serial arms): the second and third forms never stop being a number at any step
  from 1/240 s to 2 us, where the release diverges at every step from 1/240 s to 20 us; the third holds the arm at rest
  on its limit. The rebound at steps far above the limit's own time scale (here 900 times its explicit bound) is open.
