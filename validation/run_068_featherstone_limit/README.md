# Run 068: Featherstone's joint limit kept from pulling, and integrated implicitly (issues 16 and 28)

Not registered: a design probe, its predictions pushed with [`play.sh`](play.sh) before any play. Newton 1.7.0 from
PyPI, and the same with Senua AI's Featherstone limit patch in design first on the path
([`featherstone_limit_on_1.7.0.diff`](../../patches/in_design/featherstone_limit_on_1.7.0.diff), sha256
4cec45b4a22bc144...). Measured by Senua AI's `sx_contact` (`final`, `swing`, `chain`) and judged by its `rule`.

## The patch

Newton's joint limit (`joint_force`) is a spring `limit_ke (limit - q)` and a damper `-limit_kd qd` whenever the joint
is past its limit, evaluated at the step's start. It pulls the joint back as it leaves (F16, runs 036 and 042), and on
Featherstone it is integrated by semi-implicit Euler, stable only for steps under (-g + sqrt(g^2 + 4 w^2)) / w^2
(F20, run 055: microseconds on light links). The patch computes the limit after the stock joint forces (given the
limit's stiffness and damping as zero, so their drive is still off past a limit) and adds it to tau:

- **`NEWTON_FEATHERSTONE_LIMIT=1`**: the same spring and damper, explicit, never pulling (the no-tension spring-dashpot
  of Schwager and Poeschel 2007, as Study 3's contact and Study 6's MuJoCo limit);
- **`=2`**: also linearly implicit, backward Euler for the spring and damper (Baraff and Witkin 1998): with
  q' = q + h qd' and qd' = qd + h qdd, (H + h kd + h^2 ke) qdd = tau + ke (limit - q - h qd) - kd qd, the diagonal
  term added to the joint-space inertia before its Cholesky factorization, as an armature is. Unconditionally stable
  for the spring and damper; where the implicit force would pull, the limit is left out of that step.

## What is played

On Featherstone, as released, the patch's tree with the switch unset, and with it at 1 and 2:

- **L1, run 055's light arm** (0.05 kg, half-size 0.01 m, centre 0.02 m out, I = 2.333e-5 kg m^2, released level under
  gravity onto -0.5 rad, Newton's default limit, 0.15 s; its explicit bound 4.66 us) at 1/240 s, 1 ms, 250 us, 20 us,
  5 us and 2 us. Held: a number throughout, the last angle within 1 in 100 of -0.5 rad, the last speed within 0.01
  rad/s of 0.
- **L3, run 042's strike** (half-size 0.04 m, centre 0.4 m out, released level onto -1 rad, 2 s) at 0.1 and 1 kg, at
  0.25 and 0.0625 ms: where the arm turns back after its first strike. The spring and damper kept from pulling turn it
  at **-0.815 rad** (0.1 kg) and **-0.450 rad** (1 kg) (run 042's closed form).
- **L5, a free chain** (Study 9's), no limit, 2 ms.

## Predictions (pushed before the plays)

| Check | Prediction | Why |
|---|---|---|
| F0 | With the switch unset, every play byte for byte the release's (11 of 11) | The stock kernels are launched |
| F1 | As released the light arm stops being a number at 1/240 s, 1 ms, 250 us and 20 us | Run 055 |
| F2 | With `=2` the light arm is held at every step, 1/240 s to 2 us | Backward Euler on the spring and damper has no step bound |
| F3 | As released the 0.1 kg strike turns back at -0.88 rad or lower, at both steps | Run 042: -0.890 and -0.913, the pull |
| F4 | Kept from pulling, the strike turns back within 0.02 rad of -0.815 (0.1 kg) and -0.450 (1 kg): `=1` at both steps, `=2` at 0.0625 ms for 0.1 kg and both for 1 kg | The no-tension form; at 0.25 ms the 0.1 kg arm's limit spring covers h w = 0.2 a step, where backward Euler's own damping is not small (reported) |
| F5 | The chain, with no limit, byte for byte the release's at `=1` and `=2` | No joint past a limit: no force, no diagonal |

Reported, not predicted: `=1` on the light arm (explicit, never pulling: the step bound stands), the light arm's
rest at 5 and 2 us as released, and every reading at every step.

## The result: 6 of 10 checks held

Played 20 October 2026 on the second x86-64 host, from the record at 8f0119d (these predictions pushed);
`measured.txt` and `checks.txt` made there.

| Light arm (bound 4.66 us) | 1/240 s | 1 ms | 250 us | 20 us | 5 us | 2 us |
|---|---|---|---|---|---|---|
| As released | stops, step 14 | step 53 | step 202 | step 2,839 | thrown (-0.271 rad, -18.8 rad/s) | -0.500015 rad |
| `=1` (explicit, no pull) | stops, step 14 | step 53 | step 202 | step 2,839 | thrown, the same | the same |
| `=2` (implicit), last angle, rad | **-0.500796** | **-0.500370** | **-0.500048** | **-0.500002** | **-0.500007** | **-0.500016** |
| `=2`, last speed column, rad/s | 0.794 | -0.184 | 0.046 | 0.0014 | 0.0059 | 0.0148 |

| The strike, where the arm turns back, rad | 0.1 kg, 0.25 ms | 0.1 kg, 0.0625 ms | 1 kg, 0.25 ms | 1 kg, 0.0625 ms |
|---|---|---|---|---|
| As released | -0.890 | -0.913 | -0.484 | -0.484 |
| `=1` | **-0.805** | **-0.826** | **-0.450** | **-0.456** |
| `=2` | -0.843 | -0.836 | -0.517 | -0.474 |
| Kept from pulling (the closed form) | -0.815 | -0.815 | -0.450 | -0.450 |

F0 (11 of 11 byte for byte with the switch unset), F1, F3 and F5 held; F2's still check (both lines) and F4 (both
lines) failed.

- **Issue 16: the first form removes the pull.** Explicit and never pulling, the strike turns back within 0.011 rad of
  the no-tension spring-dashpot's -0.815 and -0.450 rad at both masses and steps, where as released the limit pulls the
  arm 0.075 to 0.098 rad lower. F4 failed on the second form's lines only.
- **Issue 28: the second form never stops being a number**, at every step from 1/240 s to 2 us, where the release
  stops at every step from 1/240 s to 20 us; the arm stays within 0.8 mrad of the limit. It is not still at large steps:
  the time series (1 ms) shows the implicit limit taking the arm back out at 5 rad/s and letting it go while it still
  leaves at 4.6 rad/s, so it rises 26 mrad clear and falls back, again and again. The cause is in the patch: its
  one-sided test reads the step's predictor, ke (limit - q - h qd) - kd qd, not the force the implicit step applies,
  which is larger by (h kd + h^2 ke) times the joint's deceleration; the limit is dropped too early. The same early
  release takes the strike's turn back lower than the closed form (F4's `=2` lines).
- **The still check read the wrong column at small steps.** At 2 us the release and the second form both sit at one
  angle (-0.500015 and -0.500016 rad) for the last 50,000 steps while the speed column reads a constant 14 mrad/s: a
  step's move, 2.9e-8 rad, is under half a 32-bit ulp at 0.5 rad, so the joint's angle, kept in 32 bits, cannot move,
  and the damper's force at that speed balances the spring's at the stuck angle. Run 055's 0.014 rad/s at 2 us is the
  same. A held arm is read by its angle and by whether it comes back up off the limit ([run 070](../run_070_featherstone_limit_v3/README.md)).
- The third form ([`featherstone_limit_v2_on_1.7.0.diff`](../../patches/in_design/featherstone_limit_v2_on_1.7.0.diff),
  `=3`) decides the implicit limit on the force the implicit step applies, from the joint's own row of the joint-space
  inertia built for the step.
