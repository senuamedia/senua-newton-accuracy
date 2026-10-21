#!/usr/bin/env bash
# Run 042, a trace (not registered): the damping the MuJoCo limit patch in design (run 039) still leaves short at the
# light masses: with it, run 036's arm turns back at -0.804 rad (0.1 kg) and -0.448 rad (1 kg) at 0.25 ms against
# Featherstone's -0.890 and -0.484, where its depth past the limit matches Featherstone's. MuJoCo's limit acceleration,
# aref = -b v - k d x, is taken from the velocity and violation at the start of each step, and the light arms' limit
# springs are the fastest (sqrt(ke / I) = 788 and 249 rad/s), so a step of 0.25 ms covers h w = 0.20 and 0.06 of them.
# Hypothesis: the shortfall is that step's discretization. If so it shrinks as the step does.
# Run 036's arm (0.4 m, half-size 0.04 m, released level onto -1 rad) at 0.1 and 1 kg on the MuJoCo solver with the
# patch (run 039's source, NEWTON_MUJOCO_LIMIT_FORCE_SPACE=1), and on Featherstone from the same source, at 0.0625 ms.
# Predicted, before the plays:
#   P1  with the patch at 0.0625 ms the arm turns back within 0.02 rad of Featherstone's at the same step, at both masses.
#   Reported, not predicted: how far past the limit it goes.
# usage: play.sh <sx_contact binary>   (repository root; MJLIM_VENV set to run 039's patched source's environment)
set -u
B="${1:?usage: play.sh <sx_contact binary>}"
O=validation/run_042_mujoco_limit_damping_step; W=$O/runs; mkdir -p $W
: > $W/stats.txt; : > $W/log.txt
ARM="radius=0.04 arm=0.4 secs=2 lo=-1 hi=1"
one() {  # <name> <mass> <solver> <rig settings...>
  local n=$1 m=$2 s=$3; shift 3
  ( . "$MJLIM_VENV/bin/activate"; export NEWTON_MUJOCO_LIMIT_FORCE_SPACE=1
    python tools/nwt_joint.py $W/${n}_m$m.txt dt=0.0000625 mass=$m $ARM solver=$s "$@" 2>> $W/log.txt | sed "s/^STATS/STATS ${n}_m$m/" >> $W/stats.txt )
}
date -u +%FT%TZ > $O/started.txt
one mujoco 0.1 mujoco & one mujoco 1 mujoco & one featherstone 0.1 featherstone & one featherstone 1 featherstone &
wait
date -u +%FT%TZ > $O/finished.txt
{
  for n in mujoco featherstone; do for m in 0.1 1; do echo "$n m $m kg 0.0625 ms | $("$B" swing $W/${n}_m$m.txt | tail -1)"; done; done
  echo "plays that stopped being a number: $(grep -c nan_at_step $W/stats.txt)"
} > $O/reading.txt
cat $O/reading.txt
