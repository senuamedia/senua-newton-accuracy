#!/usr/bin/env bash
# Run 048, a trace (not registered): XPBD's joint limit against the angle it lies at. Run 046 found XPBD's limit is not
# the same when the whole scene is turned: an arm's return off a limit at 1.5, 2.5 and 3.0 rad differs (2.62, 2.29 and
# 3.02 rad/s at 1.6 ms), and at 3.0 rad the arm chatters on the limit before it leaves.
# Read in the source (xpbd/kernels.py, solve_body_joints): for a revolute joint about z its angle theta comes through
# the swing part of the swing-twist split, err = theta exactly, but the gradient is the quaternion component's
# gradient times the scale theta / sin(theta / 2), the derivative of the scale left out, so the constraint's angular
# Jacobian along the axis is (theta / 2) cot(theta / 2), not 1. Each iteration's correction is then
# relaxation / ((theta / 2) cot(theta / 2)) of the overshoot: 0.49 at 1.5 rad, 1.07 at 2.5 rad, 3.8 at 3.0 rad with the
# default relaxation 0.4, without bound toward pi. Where that gain passes 2 a correction overshoots by more than it
# corrects and the limit chatters: theta above 2.85 rad at relaxation 0.4, above 3.01 rad at 0.2. (It also explains run
# 040: relaxation 1 at 2.5 rad is a gain of 2.67, and the arm was thrown.)
# Hypothesis: XPBD's limit acts with that gain. Run 046's arm (1.5 kg, half-size 0.03 m, 0.3 m), no gravity, set
# turning at 3 rad/s from L - 2.5 toward an upper limit L (lower limit L - 3), 1.4 s, at 1.6 and 0.32 ms.
# Predicted, before the plays (a chatter: more than 2 turning points, read by sx_contact swing):
#   P1  at relaxation 0.4 (as released), limits at 2.7 and 2.8 rad turn the arm back once (one turning point) and limits
#       at 2.9, 2.95 and 3.05 rad chatter, at both steps.
#   P2  at relaxation 0.2, limits at 2.9 and 2.95 rad turn the arm back once and a limit at 3.05 rad chatters, at both
#       steps.
#   P3  with the joint-angle patch (run 035's source) at relaxation 0.4, a limit at 3.3 rad (its wrapped angle -2.98,
#       gain 3.3) chatters and limits at 3.8 and 4.5 rad (gains 1.05 and 0.55) turn the arm back once, at both steps.
#   Reported, not predicted: every arm's last angle and speed, and how far past its limit it turns.
# usage: play.sh <sx_contact binary>   (repository root; STOCK_VENV and XLIM_VENV set: Newton 1.6.1 from PyPI, and
#        run 035's patched source)
set -u
B="${1:?usage: play.sh <sx_contact binary>}"
O=validation/run_048_xpbd_limit_gain; W=$O/runs; mkdir -p $W
: > $W/log.txt
ARM="mass=1.5 radius=0.03 arm=0.3 gravity=0 omega0=3 secs=1.4 solver=xpbd"
one() {  # <stock|on> <relaxation> <L> <a0> <lo> <dt>
  local a=$1 r=$2 L=$3 a0=$4 lo=$5 dt=$6 venv
  if [ $a = stock ]; then venv="$STOCK_VENV"; else venv="$XLIM_VENV"; fi
  ( . "$venv/bin/activate"; unset NEWTON_XPBD_JOINT_ANGLE_UNWRAP; if [ $a = on ]; then export NEWTON_XPBD_JOINT_ANGLE_UNWRAP=1; fi
    python tools/nwt_joint.py $W/${a}_r${r}_L${L}_$dt.txt dt=$dt $ARM angle0=$a0 lo=$lo hi=$L opt.joint_angular_relaxation=$r > $W/${a}_r${r}_L${L}_$dt.stats 2>> $W/log.txt )
}
date -u +%FT%TZ > $O/started.txt
for dt in 0.0016 0.00032; do
  one stock 0.4 2.7 0.2 -0.3 $dt & one stock 0.4 2.8 0.3 -0.2 $dt & one stock 0.4 2.9 0.4 -0.1 $dt & one stock 0.4 2.95 0.45 -0.05 $dt & wait
  one stock 0.4 3.05 0.55 0.05 $dt & one stock 0.2 2.9 0.4 -0.1 $dt & one stock 0.2 2.95 0.45 -0.05 $dt & one stock 0.2 3.05 0.55 0.05 $dt & wait
  one on 0.4 3.3 0.8 0.3 $dt & one on 0.4 3.8 1.3 0.8 $dt & one on 0.4 4.5 2 1.5 $dt & wait
done
date -u +%FT%TZ > $O/finished.txt
{
  for f in $W/*_0*.txt; do
    s=$(grep -o 'out_of_range_at_step [0-9]*\|nan_at_step [0-9]*' ${f%.txt}.stats || echo "plays")
    echo "$(basename $f .txt) | $s | $("$B" final $f | tail -1) | $("$B" swing $f | tail -1)"
  done
} > $O/reading.txt
cat $O/reading.txt
