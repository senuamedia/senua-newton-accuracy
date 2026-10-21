# Run 121: VBD's chain far from the origin with its own joint options (issue 12)

Not registered: a design probe, its predictions pushed with [`play.sh`](play.sh) before any play. Newton 1.7.0 with
Senua AI's VBD displacement patch first on the path ([`vbd_displacement.diff`](../../patches/newton-1.7.0/vbd_displacement.diff),
validated for issue 13 by Study 23; the engine run 114's `setup_engine.sh` makes), switch `NEWTON_VBD_DISPLACEMENT=1`
in every play.

## Why

Study 22 (run 114) found that with the patch VBD's free chain loses energy in proportion to the step at the origin, but
10 m out at its smallest step (0.09375 ms) it departs 3.4 times as far (3,281 ppm against 952), where Featherstone plays
alike at both places and XPBD, whose state is 32-bit poses as VBD's is, departed no further 100 m out than at the
origin (run 045). VBD's chain plays its joints on its legacy path, as hard constraints: an augmented Lagrangian whose
multiplier is carried from step to step (decayed by `rigid_avbd_gamma`, 0.999) and stabilized against the violation
the step starts with (`C - alpha C0`, `rigid_avbd_joint_alpha`, 0.95). A violation the 32-bit poses' rounding makes
each step, corrected within the step, is a velocity kick; a multiplier carried from step to step sums such
corrections. If the floor is how VBD's joint solve takes up the rounding, one of VBD's own joint options may remove it.

## What is played

Study 22's chain (links of 1.0 and 0.8 kg, the joints 0.45 m apart, turning at 1.9 and -0.9 rad/s, no gravity, 2 s)
on VBD with the patch, at the origin and 10 m out, at 0.375 and 0.09375 ms: at VBD's defaults; on its compliant ALM
path (`rigid_compliant_alm=true`, Newton's recommended path, its joints of finite stiffness); with the multiplier not
carried (`rigid_avbd_gamma=0`); and with the stabilization off and full (`rigid_avbd_joint_alpha=0`, `=1`).

## Predictions (pushed before the plays)

| Check | Prediction |
|---|---|
| C0 | Every play a number; at the defaults, Study 22's four files byte for byte |
| P1 | At the defaults, 10 m out at 0.09375 ms the chain departs at least twice as far as at the origin |
| P2 | Reported per option: whether 10 m out at 0.09375 ms it departs within 1 in 3 of the origin's (a check each, not a prediction that every option does) |

Reported: every reading.

## What it found

Played 20 October 2026 on the Newton host (`started.txt`, `finished.txt`); the measured lines in `measured.txt`, the
checks in [`checks.txt`](checks.txt). **3 of 7 checks held; no option brings 10 m out within 1 in 3 of the origin.**

| The chain's largest departure from its energy, ppm | origin, 0.375 ms | 10 m, 0.375 ms | origin, 0.09375 ms | 10 m, 0.09375 ms | 10 m over the origin |
|---|---|---|---|---|---|
| VBD's defaults (legacy hard joints) | 6,410 | 5,243 | 952 | 3,281 | 3.4 |
| Compliant ALM | 6,337 | 3,574 | 1,053 | 2,296 | 2.2 |
| The multiplier not carried (gamma 0) | 6,211 | 3,500 | 1,269 | 5,847 | 4.6 |
| No C0 stabilization (alpha 0) | 5,888 | 2,321 | 905 | 3,410 | 3.8 |
| Full C0 stabilization (alpha 1) | 6,352 | 4,219 | 1,214 | 4,146 | 3.4 |

- C0 held (every play a number; at the defaults Study 22's four files byte for byte); P1 held (the floor, 3,281 ppm
  against 952); P2 failed for every option.
- **The floor is not VBD's joint solve's handling**: with the multiplier carried or not, with the stabilization off or
  full, on its legacy or its compliant path, 10 m out at the smallest step the chain departs 2.2 to 4.6 times as far
  as at the origin, while at 0.375 ms it departs no further there than at the origin on any of them. What is left is
  what the joints read: two 32-bit poses 10 m out, 9.5e-7 m apart, rounded at every step where the step's own motion
  of a joint is near that spacing. A fix has to keep the poses' precision itself, not the joint solve's terms.
