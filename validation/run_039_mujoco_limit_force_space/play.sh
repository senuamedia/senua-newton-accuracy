#!/usr/bin/env bash
# Run 039, a patch in design (not registered): patches/in_design/mujoco_limit_force_space.diff, against Newton v1.6.1.
# Run 036 (F15) found the MuJoCo solver's joint limit 15 to 20 times softer than the limit_ke Newton gives it, and damped
# at about a fifth of the ratio. Traced in the source: kernels.update_jnt_solref_from_invweight0_kernel pre-scales
# limit_ke and limit_kd by dof_invweight0 * (1 - dmax), reading MuJoCo's effective stiffness as k / (invweight
# (1 - dmax)). For one constraint MuJoCo's soft solve gives the acceleration (1 - d) a0 + d aref, aref = -b v - k d x, so
# the effective torque stiffness is d^2 k / invweight and the damping d b / invweight; with convert_solref(ke', kd', 1, 1)
# MuJoCo's own k and b are (d / dmax^2) ke' and kd' / dmax, and the limit holds with (1 - dmax) ke and (1 - dmax) kd past
# solimp's width: 0.05 of each by default, a limit 20 times softer and a damping ratio 0.05 / sqrt(0.05) = 0.22 of
# Newton's, as run 036 read. The patch pre-scales by dof_invweight0 alone, launched only when
# NEWTON_MUJOCO_LIMIT_FORCE_SPACE=1 (read once when solver_mujoco is imported; the use_mujoco_cpu path too).
# The five checks, on the patched source's environment:
#   limit    run 036's arm (0.4 m, half-size 0.04 m, released level onto -1 rad) at 0.1, 1, 10 and 100 kg, 0.25 ms and
#            10 ms, on the MuJoCo solver, off and on
#   suite    the ten-test suite on the MuJoCo solver with its elliptic cone (run 013's), on
#   chains   run 014's free and swinging chains on the MuJoCo solver at 10 ms over 1, 4, 16 and 64, on
# Predicted, before the plays:
#   S   off: run 036's eight MuJoCo files at 0.25 ms and 10 ms byte-identical (8 of 8 per step).
#   P1  on, at 0.25 ms: the arm's first turn after the strike within 0.02 rad of Featherstone's in run 036 (-0.890,
#       -0.484, -0.191 and -0.069 rad) at each mass.
#   N   on: the suite's 39 files and the eight chain files byte-identical to runs 013 and 014 (no joint limit in them).
#   K   no play stops being a number.
#   Reported, not predicted: how far past the limit the arm goes; 10 ms, where MuJoCo's refsafe lengthens a time constant
#   shorter than two steps.
# usage: play.sh <sx_contact binary>   (repository root; MJLIM_VENV and MJLIM_SRC set)
set -u
B="${1:?usage: play.sh <sx_contact binary>}"
O=validation/run_039_mujoco_limit_force_space; W=$O/runs; mkdir -p $W
: > $W/stats.txt; : > $W/log.txt
ARM="radius=0.04 arm=0.4 secs=2"
ARMS="mass1=1.2 mass2=0.6 radius=0.04 arm1=0.25 len1=0.5 arm2=0.2"
FREE="gravity=0 angle2=-0.9 omega1=2.5 omega2=1.5 secs=2"
SWING="gravity=1 angle1=0.4 angle2=-0.7 secs=2"
dt_of() { awk -v k=$1 'BEGIN { printf "%.12f", 0.01 / k }'; }
act() { . "$MJLIM_VENV/bin/activate"; if [ $1 = on ]; then export NEWTON_MUJOCO_LIMIT_FORCE_SPACE=1; else unset NEWTON_MUJOCO_LIMIT_FORCE_SPACE; fi; }
limits() {  # <off|on>
  local a=$1 m dt
  ( act $a; for dt in 0.00025 0.01; do for m in 0.1 1 10 100; do
      python tools/nwt_joint.py $W/lim_mujoco_m${m}_${dt}_$a.txt dt=$dt mass=$m $ARM lo=-1 hi=1 solver=mujoco 2>> $W/log.txt | sed "s/^STATS/STATS lim_m${m}_${dt}_$a/" >> $W/stats.txt
    done; done )
}
chains() {
  local k sc S
  ( act on; for k in 1 4 16 64; do for sc in free swing; do
      if [ $sc = free ]; then S="$FREE"; else S="$SWING"; fi
      python tools/nwt_chain.py $W/${sc}_mujoco_$k.txt dt=$(dt_of $k) $ARMS $S solver=mujoco > $W/${sc}_mujoco_$k.stats 2>> $W/log.txt
    done; done )
}
date -u +%FT%TZ > $O/started.txt
if [ -n "${MJLIM_SRC:-}" ]; then
  { git -C "$MJLIM_SRC" status --short
    (cd "$MJLIM_SRC" && sha256sum newton/_src/solvers/mujoco/solver_mujoco.py newton/_src/solvers/mujoco/limit_force_space_kernels.py newton/_src/solvers/mujoco/kernels.py)
  } > $O/patched_source.txt
fi
limits off & limits on & chains &
( act on; tools/contact_suite.sh r039_on_mujoco_elliptic solver=mujoco opt.cone=elliptic > $O/play_suite.txt 2>> $W/log.txt ) &
wait
date -u +%FT%TZ > $O/finished.txt
{
  n=0; d=0
  for dt in 0.00025 0.01; do for m in 0.1 1 10 100; do n=$((n + 1))
    cmp -s $W/lim_mujoco_m${m}_${dt}_off.txt validation/run_036_limit_damping_inertia/runs/lim_mujoco_m${m}_$dt.txt || { d=$((d + 1)); echo "DIFFERS m$m $dt"; }
  done; done
  echo "S off against run 036: $((n - d)) of $n byte-identical"
  for a in on off; do for dt in 0.00025 0.01; do for m in 0.1 1 10 100; do
    echo "$a m $m kg $dt s | $("$B" swing $W/lim_mujoco_m${m}_${dt}_$a.txt | tail -1)"
  done; done; done
  n=0; d=0
  for f in suites/1/r039_on_mujoco_elliptic/*_[0-9]*.txt; do n=$((n + 1)); cmp -s $f suites/1/mujoco_elliptic/$(basename $f) || { d=$((d + 1)); echo "DIFFERS $(basename $f)"; }; done
  echo "N on, the suite against run 013's: $((n - d)) of $n byte-identical"
  n=0; d=0
  for k in 1 4 16 64; do for sc in free swing; do n=$((n + 1))
    cmp -s $W/${sc}_mujoco_$k.txt validation/run_014_chain/runs/${sc}_mujoco_$k.txt || { d=$((d + 1)); echo "DIFFERS ${sc}_mujoco_$k"; }
  done; done
  echo "N on, run 014's MuJoCo chains: $((n - d)) of $n byte-identical"
  echo "K plays that stopped being a number: $(cat $W/stats.txt $W/*.stats suites/1/r039_on_mujoco_elliptic/stats.txt | grep -c nan_at_step)"
} > $O/reading.txt
cat $O/reading.txt
