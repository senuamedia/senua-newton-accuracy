# Run 009: the MuJoCo solver on the ten contact tests, the drop at a friction of 1e-5

15 October 2026. Not registered: a design probe, by [`play.sh`](play.sh) (pushed before its plays); reading
`reading.txt`. Run 007 could not read Newton's MuJoCo solver on the first deep dive's ten contact tests: its drop is
frictionless, and the MuJoCo solver stops being a number at the first contact of a frictionless shape. MuJoCo's C
engine raises any friction under 1e-5 to 1e-5 and plays on, so this run gave the drop a friction of 1e-5 (the suite
script's new `SUITE_DROPMU`; unset, the script plays as before) and played the suite on the MuJoCo solver
(`suites/1/mujoco_dropmu/`).

**Check on the suite script:** XPBD's suite played again without the setting is byte-identical to run 007's, 40 of 40
files (`suites/1/xpbd_check/`).

## The result: still not readable

The runner stopped again (`runner rc 1`), for two reasons the plays show (`suites/1/mujoco_dropmu/stats.txt`):

| Plays that stopped being a number | Friction | Step at which it stopped |
|---|---|---|
| The drop at every step, 10 ms to 0.156 ms | 1e-5, as given | the first contact (16, 28, 51, 102, 204, 449, 822) |
| The set-down (rest) and the lift, at 10 ms and 0.625 ms | 0: the suite gives these scenes no friction | step 3 and step 1 |
| The fast rebound | 0 | 396 |

- **A friction of 1e-5 is still under MuJoCo Warp's floor.** Newton holds friction in 32-bit floats, where 1e-5 is
  9.99999975e-6, and MuJoCo Warp warns that a friction under `MJ_MINMU` (1e-5) "may cause NaN" (`mujoco_warp`
  `io.py`); the drop goes to NaN at its first contact as at 0.
- **Every frictionless scene of the suite does the same.** The rest, the lift and the fast rebound give no friction,
  as the first deep dive's suite has them (friction plays no part there), and each goes to NaN on its first contact.

So the MuJoCo solver as Newton ships it cannot play a contact whose friction is 0, nor one of 1e-5: the least
friction it plays is just above MuJoCo's own floor, where MuJoCo's C engine plays any friction. A follow-up gives every
frictionless scene of the suite a friction of 2e-5, a change that touches no test's answer (none of those four reads
friction), stated as a difference from the first deep dive's suite.
