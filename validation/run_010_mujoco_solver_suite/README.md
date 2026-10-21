# Run 010: the MuJoCo solver on the ten contact tests, the frictionless scenes at 2e-5

15 October 2026. Not registered: a design probe, by [`play.sh`](play.sh) (pushed before its plays); reading
`reading.txt`. Run 009 found the MuJoCo solver stopping being a number at a friction of 1e-5, which 32-bit floats
hold just under MuJoCo Warp's floor, and found the suite's rest, lift and fast rebound frictionless too. This run gave
all four frictionless scenes a friction of 2e-5, above the floor (the suite script's new `SUITE_ZEROMU`; unset, the
script plays as before), and played the suite on the MuJoCo solver (`suites/1/mujoco_zeromu/`).

**Check on the suite script:** XPBD's suite played again without the setting is byte-identical to run 007's, 40 of 40
files (`suites/1/xpbd_check2/`).

## The result: still not readable

MuJoCo Warp no longer warns, yet the same 12 plays stop being a number, at their first contact: the drop at every
step, the rest and the lift at both steps, and the fast rebound (`suites/1/mujoco_zeromu/stats.txt`), so the runner
stops (`runner rc 1`). The fault is not only below MuJoCo Warp's stated floor: a friction of 2e-5 does it too, where
run 001 played frictions of 0.3 to 0.5 without fault. [Run 011](../run_011_mujoco_solver_low_friction/probe.sh)
brackets the friction at which the MuJoCo solver starts to play.
