# Run 039: a patch in design, the MuJoCo solver's joint limit with the stiffness and damping it is given (F15)

15 October 2026, 10:17 to 10:33 UTC. Not registered: a patch in design, held to the five checks. Played on the Newton
host by [`play.sh`](play.sh), whose cause and predictions were pushed with the patch before the plays; reading
`reading.txt`, made with Senua AI's `sx_contact swing` and byte comparisons, re-made byte for byte on the laptop from
the same files. In the logs the home folder is written `~/`.

## The cause, traced in the source

Run 036 found the MuJoCo solver's joint limit about 20 times softer than Newton's `limit_ke` and damped at about a
fifth of the ratio (F15). Newton's conversion (`kernels.update_jnt_solref_from_invweight0_kernel`, and the same in the
`use_mujoco_cpu` path) pre-scales `limit_ke` and `limit_kd` by `dof_invweight0 * (1 - dmax)`, reading MuJoCo's effective
stiffness as k / (invweight (1 - dmax)). For one constraint MuJoCo's soft solve gives the acceleration
(1 - d) a0 + d aref, with aref = -b v - k d x, so the effective torque stiffness is d^2 k / invweight and the damping
d b / invweight. With `convert_solref(ke', kd', 1, 1)`, MuJoCo's own k and b are (d / dmax^2) ke' and kd' / dmax, so past
solimp's width (d = dmax) the limit holds with (1 - dmax) ke and (1 - dmax) kd: 0.05 of each with the default solimp,
a limit 20 times softer and a damping ratio 0.05 / sqrt(0.05) = 0.22 of Newton's, as run 036 read.

## The patch

[`patches/in_design/mujoco_limit_force_space.diff`](../../patches/in_design/mujoco_limit_force_space.diff) (sha256
77925587f1591155...), against Newton v1.6.1: a copy of the conversion kernel pre-scaling by `dof_invweight0` alone, and
the same in the `use_mujoco_cpu` path; `NEWTON_MUJOCO_LIMIT_FORCE_SPACE=1`, read once when `solver_mujoco` is imported.

## The five checks

| Run 036's arm released onto its limit, 0.25 ms | 0.1 kg | 1 kg | 10 kg | 100 kg |
|---|---|---|---|---|
| How far past the limit, rad: Featherstone (run 036) | 0.005 | 0.022 | 0.078 | 0.269 |
| The MuJoCo solver as released | 0.032 | 0.110 | 0.360 | 1.144 |
| **With the patch** | **0.005** | **0.021** | **0.077** | **0.253** |
| Where it turns back, rad: Featherstone | -0.890 | -0.484 | -0.191 | -0.069 |
| As released | -0.351 | -0.135 | -0.045 | -0.014 |
| **With the patch** | **-0.804** | **-0.448** | **-0.183** | **-0.063** |

| Check | Measured | |
|---|---|---|
| **1. Required** | Run 036: the limit 20 times softer, the damping ratio a fifth | Held |
| **2. Correct** | With the patch the arm goes past the limit as far as on Featherstone, within 0.016 rad, at every mass: the stiffness is Newton's. It turns back within 0.02 rad of Featherstone at 10 and 100 kg, but 0.086 and 0.036 rad higher at 0.1 and 1 kg: the light arms keep more of their speed than the given damping lets them | **Not met** at 0.1 and 1 kg |
| **3. Nothing else gets worse** | With the switch, the ten-test suite on the MuJoCo solver with its elliptic cone (39 files) and run 014's MuJoCo chains (8 files) byte-identical: they have no joint limit | Held |
| **4. Safe when off** | No switch: run 036's eight MuJoCo files byte-identical | Held |
| **5. The solver keeps converging** (here: no play stops being a number) | None did; at 10 ms the 1 kg arm with the patch leaves the format's range at step 79 (as released it plays there) | Held, with that play reported |

| Prediction | Result |
|---|---|
| S: off, run 036's files | Held, 8 of 8 |
| P1: on at 0.25 ms, the turn within 0.02 rad of Featherstone's at each mass | **Failed** at 0.1 and 1 kg; held at 10 and 100 kg |
| N: the suite and the chains byte for byte | Held, 39 of 39 and 8 of 8 |
| K: no play stops being a number | Held |

## What it shows

- **The cause of F15 is the conversion's (1 - dmax) factor:** without it the MuJoCo solver's limit is as stiff as
  Newton's `limit_ke`, the arm going no further past it than on Featherstone at any mass.
- **The damping is not yet Newton's at the light masses**, and the stiffer limit leaves the format's range at 10 ms on
  the 1 kg arm. Not traced; the patch stays in design.
