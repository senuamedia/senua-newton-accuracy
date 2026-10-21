#!/usr/bin/env bash
# Run 050, a trace (not registered): XPBD's joint limit with the swing's gradient taken exactly. Run 048 traced the
# limit's gain to the source: the swing part of XPBD's swing-twist split gives the angle exactly, e = f(|v|) v with
# f = theta / sin(theta / 2), but its gradient is v's gradient times f alone, so along the axis it is
# (theta / 2) cot(theta / 2) of the true one and the gain relaxation / ((theta / 2) cot(theta / 2)) has no bound toward
# pi (chatter from 2.86 rad at relaxation 0.4, a throw at 3.05 rad). The exact gradient is de/dv = f I + (2/w - f) a a^T,
# w = cos(theta / 2), a = v / |v| (the twist part already takes its exact 2 / |w|).
# The patch: patches/in_design/xpbd_joint_angle_v2.diff (sha256 b969131ba1f65879...), run 035's joint-angle patch plus
# the exact swing gradient. Switch NEWTON_XPBD_JOINT_ANGLE_UNWRAP: unset = Newton as released; 1 = run 035's patch
# alone; 2 = run 035's patch and the exact swing gradient.
# A second question, for issue 8's other part (F14: the arm leaves a limit turning back at most of its speed, at every
# gain). Read in the source: the limit's correction is sized by the arm's inertia about its own centre (9e-4 kg m^2 for
# this arm), while the arm turns about the joint (0.136 kg m^2), and the joint's linear constraint, solved separately
# after it, turns most of that correction back into the arm's turn, so the limit acts as a stiff spring with little to
# damp it. If so, the return falls as the arm's centre comes in toward the joint, and with no lever at all a full
# correction (relaxation 1, gain 1 with the exact gradient) holds the arm.
# The arm: run 048's (1.5 kg, half-size 0.03 m, 0.3 m), no gravity, set turning at 3 rad/s from L - 2.5 toward an upper
# limit L (lower limit L - 3), 1.4 s, at 1.6 and 0.32 ms. A chatter is more than one turning point, read by sx_contact
# swing; the penetration is the first turning point's angle less L.
# Predicted, before the plays:
#   P1  with switch 2, run 048's eleven limits (2.7, 2.8, 2.9, 2.95, 3.05, 3.3, 3.8 and 4.5 rad at relaxation 0.4;
#       2.9, 2.95 and 3.05 rad at 0.2) each turn the arm back once (one turning point) and none is thrown, at both
#       steps.
#   P2  with switch 2, at each step and relaxation the first turning point lies the same distance past its limit at
#       every limit, within 500 urad (the gain is the relaxation at every angle).
#   P3  with switch 2 the return stays: each of those 22 arms ends turning back at between 1 and 3 rad/s.
#   P4  with switch 2, a limit at 2.5 rad (lower -0.5), relaxation 0.4: the arm's last speed back is lower with its
#       centre at 0.1 m than at 0.3 m, and lower at 0 m than at 0.1 m, at both steps.
#   P5  with switch 2 and relaxation 1, the arm with its centre at the joint (0 m) is held at the limit: it ends within
#       0.05 rad of 2.5 rad and slower than 0.1 rad/s, at both steps.
#   Checks: C1 unset on the patched source is run 048's release plays byte for byte (2.7 and 3.05 rad at relaxation
#       0.4, both steps); C2 switch 1 is run 048's patched plays byte for byte (3.3, 3.8 and 4.5 rad, both steps);
#       C3 an arm turning from 0.2 to 4.4 rad inside limits of -10 and 10 rad, which it never reaches, plays byte for
#       byte the same with switches 1 and 2, both steps.
#   Reported, not predicted: every arm's last angle and speed; the 0.3 m arm at relaxation 1 with switch 2.
# usage: play.sh <sx_contact binary>   (repository root; XSG_VENV set: Newton 1.6.1 with the patch above)
set -u
B="${1:?usage: play.sh <sx_contact binary>}"
O=validation/run_050_xpbd_swing_gradient; W=$O/runs; mkdir -p $W
R48=validation/run_048_xpbd_limit_gain/runs
: > $W/log.txt
BASE="mass=1.5 radius=0.03 gravity=0 omega0=3 secs=1.4 solver=xpbd"
one() {  # <name> <unset|1|2> <arm> <relaxation> <L> <a0> <lo> <dt>
  local n=$1 sw=$2 arm=$3 r=$4 L=$5 a0=$6 lo=$7 dt=$8
  ( . "$XSG_VENV/bin/activate"; unset NEWTON_XPBD_JOINT_ANGLE_UNWRAP; if [ $sw != unset ]; then export NEWTON_XPBD_JOINT_ANGLE_UNWRAP=$sw; fi
    python tools/nwt_joint.py $W/${n}_$dt.txt dt=$dt $BASE arm=$arm angle0=$a0 lo=$lo hi=$L opt.joint_angular_relaxation=$r > $W/${n}_$dt.stats 2>> $W/log.txt )
}
date -u +%FT%TZ > $O/started.txt
for dt in 0.0016 0.00032; do
  one s2_r0.4_L2.7 2 0.3 0.4 2.7 0.2 -0.3 $dt & one s2_r0.4_L2.8 2 0.3 0.4 2.8 0.3 -0.2 $dt & one s2_r0.4_L2.9 2 0.3 0.4 2.9 0.4 -0.1 $dt & one s2_r0.4_L2.95 2 0.3 0.4 2.95 0.45 -0.05 $dt & wait
  one s2_r0.4_L3.05 2 0.3 0.4 3.05 0.55 0.05 $dt & one s2_r0.4_L3.3 2 0.3 0.4 3.3 0.8 0.3 $dt & one s2_r0.4_L3.8 2 0.3 0.4 3.8 1.3 0.8 $dt & one s2_r0.4_L4.5 2 0.3 0.4 4.5 2 1.5 $dt & wait
  one s2_r0.2_L2.9 2 0.3 0.2 2.9 0.4 -0.1 $dt & one s2_r0.2_L2.95 2 0.3 0.2 2.95 0.45 -0.05 $dt & one s2_r0.2_L3.05 2 0.3 0.2 3.05 0.55 0.05 $dt & wait
  one s2_arm0.3_r0.4_L2.5 2 0.3 0.4 2.5 0 -0.5 $dt & one s2_arm0.1_r0.4_L2.5 2 0.1 0.4 2.5 0 -0.5 $dt & one s2_arm0_r0.4_L2.5 2 0 0.4 2.5 0 -0.5 $dt & wait
  one s2_arm0_r1_L2.5 2 0 1.0 2.5 0 -0.5 $dt & one s2_arm0.3_r1_L2.5 2 0.3 1.0 2.5 0 -0.5 $dt & wait
  one off_r0.4_L2.7 unset 0.3 0.4 2.7 0.2 -0.3 $dt & one off_r0.4_L3.05 unset 0.3 0.4 3.05 0.55 0.05 $dt & wait
  one s1_r0.4_L3.3 1 0.3 0.4 3.3 0.8 0.3 $dt & one s1_r0.4_L3.8 1 0.3 0.4 3.8 1.3 0.8 $dt & one s1_r0.4_L4.5 1 0.3 0.4 4.5 2 1.5 $dt & wait
  one free_s1 1 0.3 0.4 10 0.2 -10 $dt & one free_s2 2 0.3 0.4 10 0.2 -10 $dt & wait
done
date -u +%FT%TZ > $O/finished.txt
{
  for f in $W/*_0*.txt; do
    s=$(grep -o 'out_of_range_at_step [0-9]*\|nan_at_step [0-9]*' ${f%.txt}.stats || echo "plays")
    echo "$(basename $f .txt) | $s | $("$B" final $f | tail -1) | $("$B" swing $f | tail -1)"
  done
} > $O/reading.txt
same() { if cmp -s "$1" "$2"; then echo "same $(basename $1) $(basename $2)"; else echo "DIFFERENT $(basename $1) $(basename $2)"; fi; }
{
  for dt in 0.0016 0.00032; do
    same $W/off_r0.4_L2.7_$dt.txt $R48/stock_r0.4_L2.7_$dt.txt
    same $W/off_r0.4_L3.05_$dt.txt $R48/stock_r0.4_L3.05_$dt.txt
    for L in 3.3 3.8 4.5; do same $W/s1_r0.4_L${L}_$dt.txt $R48/on_r0.4_L${L}_$dt.txt; done
    same $W/free_s1_$dt.txt $W/free_s2_$dt.txt
  done
} > $O/checks.txt
cat $O/reading.txt $O/checks.txt
