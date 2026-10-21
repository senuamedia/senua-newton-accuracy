#!/usr/bin/env bash
# Run 040, a trace (not registered): F14, XPBD throwing an arm back off a joint limit (Study 5, run 037: an arm turning
# at 3 rad/s onto a limit at 2.5 rad leaves it turning back at 2.29 and 2.39 rad/s, most of its speed). XPBD's limit is
# a position correction of the joint's angle past the limit (kernels.solve_body_joints), scaled each iteration by
# joint_angular_relaxation (0.4 by default), 2 iterations, and XPBD moves a body's velocity by each position
# correction it makes (its release note: velocities are updated incrementally after every position correction).
# Hypothesis: the return is the limit's position correction left as speed, the joint's form of F5 (XPBD's bounce off
# the ground with no restitution, traced in run 015 to its position solve). If so it depends on how the correction is
# spread over the step's iterations, not on any restitution.
# Study 5's arm (1.5 kg, half-size 0.03 m, 0.3 m), no gravity, turning at 3 rad/s from 0 onto limits -0.5 and 2.5 rad,
# 1.4 s (it reaches 2.5 rad at 0.83 s; a return at the release's speed brings it back to about 1.2 rad by the end, short
# of the lower limit), on XPBD from PyPI at 1.6 ms and 0.32 ms: as released (relaxation 0.4, 2 iterations), with
# relaxation 1, with 8 iterations, with both.
# Predicted, before the plays:
#   P1  as released the arm ends turning back at about the speed Study 5 read (-2.29 and -2.39 rad/s): the files are
#       Study 5's below plays byte for byte.
#   P2  with relaxation 1 and 8 iterations the arm turns back slower than as released, at both steps.
#   Reported, not predicted: relaxation 1 alone, 8 iterations alone.
# usage: play.sh <sx_contact binary>   (repository root, Newton from PyPI's environment on; writes the reading)
set -u
B="${1:?usage: play.sh <sx_contact binary>}"
O=validation/run_040_xpbd_limit_return; W=$O/runs; mkdir -p $W
: > $W/stats.txt; : > $W/log.txt
ARM="mass=1.5 radius=0.03 arm=0.3 gravity=0 omega0=3 secs=1.4 lo=-0.5 hi=2.5 solver=xpbd"
one() {  # <name> <dt> <rig settings...>
  local n=$1 dt=$2; shift 2
  python tools/nwt_joint.py $W/${n}_$dt.txt dt=$dt $ARM "$@" 2>> $W/log.txt | sed "s/^STATS/STATS ${n}_$dt/" >> $W/stats.txt
}
date -u +%FT%TZ > $O/started.txt
for dt in 0.0016 0.00032; do
  one released $dt &
  one relax1 $dt opt.joint_angular_relaxation=1.0 &
  one it8 $dt iterations=8 &
  one relax1_it8 $dt opt.joint_angular_relaxation=1.0 iterations=8 &
  wait
done
date -u +%FT%TZ > $O/finished.txt
pick() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
{
  for dt in 0.0016 0.00032; do for n in released relax1 it8 relax1_it8; do
    l=$("$B" final $W/${n}_$dt.txt | tail -1)
    echo "$n $dt s | angle_urad $(echo "$l" | pick angle_urad) speed_urads $(echo "$l" | pick speed_urads)"
  done; done
  for dt in 0.0016 0.00032; do
    if cmp -s $W/released_$dt.txt validation/run_037_study_05/stock/runs/below_$dt.txt; then r=yes; else r=NO; fi
    echo "CHECK released $dt s byte-identical to Study 5's below play: $r"
  done
  echo "plays that stopped being a number: $(grep -c nan_at_step $W/stats.txt)"
} > $O/reading.txt
cat $O/reading.txt
