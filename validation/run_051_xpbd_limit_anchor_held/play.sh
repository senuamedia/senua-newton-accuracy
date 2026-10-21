#!/usr/bin/env bash
# Run 051, a trace (not registered): XPBD's joint limit sized with the joint's anchor held. Run 050 traced F14's return
# to the limit's coupling to the anchor: XPBD sizes each of a joint's constraints alone, from the same state, and sums
# the corrections, so the limit's correction rotates the arm about its own centre, with its inertia there, and the
# anchor's correction turns most of it back; the return fell from 2.57 to 2.03 to 0.47 rad/s as the arm's centre came
# in from 0.3 to 0.1 to 0 m, and with no lever a full correction held the arm. With a lever a full correction threw it.
# The patch: patches/in_design/xpbd_joint_angle_v3.diff (sha256 c89335b616f1b628...), the second form plus, at switch
# value 3, a revolute joint's limit sized with the anchor's three rows eliminated: its effective inverse mass the Schur
# complement w = J M^-1 J^T - b^T K^-1 b (K the anchor's 3 x 3 inverse mass matrix, b = G M^-1 J^T) and its correction
# along M^-1 (J^T - G^T K^-1 b), which leaves the anchor in place to first order; for one body on a fixed joint, a
# rotation about the joint by the body's inertia there, I + m r^2 (the parallel-axis theorem). Every other constraint is
# the stock kernel's. Switch NEWTON_XPBD_JOINT_ANGLE_UNWRAP: unset as released; 1 run 035's patch; 2 run 050's; 3 this.
# Hypothesis: with the anchor held, a limit acts on the arm as on an arm with no lever, at every lever and angle: the
# limit's own projection, relaxation over two iterations, is all that is left.
# The arm: run 050's (1.5 kg, half-size 0.03 m), no gravity, set turning at 3 rad/s from L - 2.5 toward an upper limit
# L (lower limit L - 3), 1.4 s, at 1.6 and 0.32 ms; its centre 0.3 m from the joint unless named. The depth is the
# first turning point's angle less L (sx_contact swing); held is within 0.05 rad of the limit and slower than 0.1 rad/s
# at the end.
# Predicted, before the plays, with switch 3:
#   P1  at relaxation 0.4 and a limit at 2.5 rad (lower -0.5), the arms with their centre at 0.3 and 0.1 m end turning
#       back within 0.1 rad/s of the 0 m arm's speed, and go past the limit to within 10% of the 0 m arm's depth, at
#       both steps (with switch 2, run 050: 2.57 against 0.47 rad/s, 25 times as deep).
#   P2  at relaxation 1 the three arms at 2.5 rad are held, at both steps (with switch 2 the 0.3 m arm is thrown).
#   P3  at relaxation 1 the arm is held at each of the eight limits 2.7, 2.8, 2.9, 2.95, 3.05, 3.3, 3.8 and 4.5 rad,
#       three of them reached past pi, at both steps.
#   P4  at each step and relaxation (0.4 on those eight limits, 0.2 on 2.9, 2.95 and 3.05 rad) the largest and smallest
#       depths past the limit differ by at most 5% of the largest (with switch 2 up to 14%, run 050).
#   P5  at relaxation 0.4 each of the eight limits turns the arm back slower than 1 rad/s, at both steps (with switch 2,
#       2.56 to 2.67 rad/s).
#   Checks: C1 an arm turning from 0.2 to 4.4 rad, past pi, inside limits of -10 and 10 rad it never reaches: switch 3
#       is run 050's switch 2 byte for byte, both steps. C2 the third form's source with the switch unset is run 048's
#       release plays byte for byte (2.7 and 3.05 rad at relaxation 0.4), at 1 run 048's patched 3.8 rad plays, at 2
#       run 050's 3.05 rad and 0.3 m arm plays at relaxation 0.4, both steps.
#   Reported, not predicted: every arm's last angle and speed; the returns at relaxation 0.2; the free arm at
#       relaxation 1 with switch 3.
# usage: play.sh <sx_contact binary>   (repository root; V3_VENV set: Newton 1.6.1 with the patch above)
set -u
B="${1:?usage: play.sh <sx_contact binary>}"
O=validation/run_051_xpbd_limit_anchor_held; W=$O/runs; mkdir -p $W
R48=validation/run_048_xpbd_limit_gain/runs; R50=validation/run_050_xpbd_swing_gradient/runs
: > $W/log.txt
BASE="mass=1.5 radius=0.03 gravity=0 omega0=3 secs=1.4 solver=xpbd"
one() {  # <name> <unset|1|2|3> <arm> <relaxation> <L> <a0> <lo> <dt>
  local n=$1 sw=$2 arm=$3 r=$4 L=$5 a0=$6 lo=$7 dt=$8
  ( . "$V3_VENV/bin/activate"; unset NEWTON_XPBD_JOINT_ANGLE_UNWRAP; if [ $sw != unset ]; then export NEWTON_XPBD_JOINT_ANGLE_UNWRAP=$sw; fi
    python tools/nwt_joint.py $W/${n}_$dt.txt dt=$dt $BASE arm=$arm angle0=$a0 lo=$lo hi=$L opt.joint_angular_relaxation=$r > $W/${n}_$dt.stats 2>> $W/log.txt )
}
table() {  # <relaxation> <name tag> <dt>: the eight limits
  local r=$1 t=$2 dt=$3
  one s3_r${t}_L2.7 3 0.3 $r 2.7 0.2 -0.3 $dt & one s3_r${t}_L2.8 3 0.3 $r 2.8 0.3 -0.2 $dt & one s3_r${t}_L2.9 3 0.3 $r 2.9 0.4 -0.1 $dt & one s3_r${t}_L2.95 3 0.3 $r 2.95 0.45 -0.05 $dt & wait
  one s3_r${t}_L3.05 3 0.3 $r 3.05 0.55 0.05 $dt & one s3_r${t}_L3.3 3 0.3 $r 3.3 0.8 0.3 $dt & one s3_r${t}_L3.8 3 0.3 $r 3.8 1.3 0.8 $dt & one s3_r${t}_L4.5 3 0.3 $r 4.5 2 1.5 $dt & wait
}
date -u +%FT%TZ > $O/started.txt
for dt in 0.0016 0.00032; do
  table 0.4 0.4 $dt
  table 1.0 1 $dt
  one s3_r0.2_L2.9 3 0.3 0.2 2.9 0.4 -0.1 $dt & one s3_r0.2_L2.95 3 0.3 0.2 2.95 0.45 -0.05 $dt & one s3_r0.2_L3.05 3 0.3 0.2 3.05 0.55 0.05 $dt & wait
  one s3_arm0.3_r0.4_L2.5 3 0.3 0.4 2.5 0 -0.5 $dt & one s3_arm0.1_r0.4_L2.5 3 0.1 0.4 2.5 0 -0.5 $dt & one s3_arm0_r0.4_L2.5 3 0 0.4 2.5 0 -0.5 $dt & wait
  one s3_arm0.3_r1_L2.5 3 0.3 1.0 2.5 0 -0.5 $dt & one s3_arm0.1_r1_L2.5 3 0.1 1.0 2.5 0 -0.5 $dt & one s3_arm0_r1_L2.5 3 0 1.0 2.5 0 -0.5 $dt & wait
  one free_s3 3 0.3 0.4 10 0.2 -10 $dt & one free_s3_r1 3 0.3 1.0 10 0.2 -10 $dt & wait
  one off_r0.4_L2.7 unset 0.3 0.4 2.7 0.2 -0.3 $dt & one off_r0.4_L3.05 unset 0.3 0.4 3.05 0.55 0.05 $dt & one s1_r0.4_L3.8 1 0.3 0.4 3.8 1.3 0.8 $dt & wait
  one s2_r0.4_L3.05 2 0.3 0.4 3.05 0.55 0.05 $dt & one s2_arm0.3_r0.4_L2.5 2 0.3 0.4 2.5 0 -0.5 $dt & wait
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
    same $W/free_s3_$dt.txt $R50/free_s2_$dt.txt
    same $W/off_r0.4_L2.7_$dt.txt $R48/stock_r0.4_L2.7_$dt.txt
    same $W/off_r0.4_L3.05_$dt.txt $R48/stock_r0.4_L3.05_$dt.txt
    same $W/s1_r0.4_L3.8_$dt.txt $R48/on_r0.4_L3.8_$dt.txt
    same $W/s2_r0.4_L3.05_$dt.txt $R50/s2_r0.4_L3.05_$dt.txt
    same $W/s2_arm0.3_r0.4_L2.5_$dt.txt $R50/s2_arm0.3_r0.4_L2.5_$dt.txt
  done
} > $O/checks.txt
cat $O/reading.txt $O/checks.txt
