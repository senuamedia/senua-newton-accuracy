#!/usr/bin/env bash
# Run 061: the joint-angle patch's fourth form (patches/in_design/xpbd_joint_angle_v4_on_1.7.0.diff, switch
# NEWTON_XPBD_JOINT_ANGLE_UNWRAP=4: the third form, the limit sized with the joint's anchor held, its correction applied
# in full, not scaled by the joint's angular relaxation) on run 051's grid, Newton 1.7.0, one arm on one hinge
# (tools/nwt_joint.py), and a chain of two links with a limit on its first joint (tools/nwt_chain.py). The README's
# hypothesis and predictions were pushed before these plays. Then reading.txt (sx_contact final and swing; chain final
# angles) and checks.txt (byte checks against run 051's files).
# usage: play.sh <sx_contact binary>   (repository root; V4_VENV set: Newton 1.7.0 with the v4 patch's tree first on
#   the path)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"
O=validation/run_061_xpbd_limit_full; W=$O/runs; mkdir -p $W
R51=validation/run_051_xpbd_limit_anchor_held/runs
: > $W/log.txt
BASE="mass=1.5 radius=0.03 gravity=0 omega0=3 secs=1.4 solver=xpbd"
one() {  # <name> <unset|3|4> <arm> <relaxation> <L> <a0> <lo> <dt>
  local n=$1 sw=$2 arm=$3 r=$4 L=$5 a0=$6 lo=$7 dt=$8
  ( . "$V4_VENV/bin/activate"; unset NEWTON_XPBD_JOINT_ANGLE_UNWRAP; if [ $sw != unset ]; then export NEWTON_XPBD_JOINT_ANGLE_UNWRAP=$sw; fi
    python tools/nwt_joint.py $W/${n}_$dt.txt dt=$dt $BASE arm=$arm angle0=$a0 lo=$lo hi=$L opt.joint_angular_relaxation=$r > $W/${n}_$dt.stats 2>> $W/log.txt )
}
table() {  # <relaxation> <name tag> <dt>: run 051's eight limits under switch 4
  local r=$1 t=$2 dt=$3
  one s4_r${t}_L2.7 4 0.3 $r 2.7 0.2 -0.3 $dt & one s4_r${t}_L2.8 4 0.3 $r 2.8 0.3 -0.2 $dt & one s4_r${t}_L2.9 4 0.3 $r 2.9 0.4 -0.1 $dt & one s4_r${t}_L2.95 4 0.3 $r 2.95 0.45 -0.05 $dt & wait
  one s4_r${t}_L3.05 4 0.3 $r 3.05 0.55 0.05 $dt & one s4_r${t}_L3.3 4 0.3 $r 3.3 0.8 0.3 $dt & one s4_r${t}_L3.8 4 0.3 $r 3.8 1.3 0.8 $dt & one s4_r${t}_L4.5 4 0.3 $r 4.5 2 1.5 $dt & wait
}
CH="mass1=1.2 mass2=0.6 radius=0.04 arm1=0.25 len1=0.5 arm2=0.2 gravity=0 angle1=0 angle2=0 omega1=2 omega2=0 secs=2.5 solver=xpbd"
chain() {  # <name> <unset|3|4> <dt>: run 032's straight chain turning at 2 rad/s, the first joint's limits -1 and 3.3 rad
  local n=$1 sw=$2 dt=$3
  ( . "$V4_VENV/bin/activate"; unset NEWTON_XPBD_JOINT_ANGLE_UNWRAP; if [ $sw != unset ]; then export NEWTON_XPBD_JOINT_ANGLE_UNWRAP=$sw; fi
    python tools/nwt_chain.py $W/${n}_$dt.txt dt=$dt $CH lo1=-1 hi1=3.3 > $W/${n}_$dt.stats 2>> $W/log.txt )
}
date -u +%FT%TZ > $O/started.txt
for dt in 0.0016 0.00032; do
  table 0.4 0.4 $dt
  table 1.0 1 $dt
  one s4_r0.2_L2.9 4 0.3 0.2 2.9 0.4 -0.1 $dt & one s4_r0.2_L2.95 4 0.3 0.2 2.95 0.45 -0.05 $dt & one s4_r0.2_L3.05 4 0.3 0.2 3.05 0.55 0.05 $dt & wait
  one s4_arm0.3_r0.4_L2.5 4 0.3 0.4 2.5 0 -0.5 $dt & one s4_arm0.1_r0.4_L2.5 4 0.1 0.4 2.5 0 -0.5 $dt & one s4_arm0_r0.4_L2.5 4 0 0.4 2.5 0 -0.5 $dt & wait
  one s4_arm0.3_r1_L2.5 4 0.3 1.0 2.5 0 -0.5 $dt & one s4_arm0.1_r1_L2.5 4 0.1 1.0 2.5 0 -0.5 $dt & one s4_arm0_r1_L2.5 4 0 1.0 2.5 0 -0.5 $dt & wait
  one free_s4 4 0.3 0.4 10 0.2 -10 $dt &
done
wait
for dt in 0.0025 0.000625; do chain chain_stock unset $dt & chain chain_s3 3 $dt & chain chain_s4 4 $dt & wait; done
date -u +%FT%TZ > $O/finished.txt
{
  for f in $W/*_0*.txt; do
    s=$(grep -o 'out_of_range_at_step [0-9]*\|nan_at_step [0-9]*' ${f%.txt}.stats || echo "plays")
    case $(basename $f) in
      chain_*) echo "$(basename $f .txt) | $s | $(tail -1 $f | awk '{ print "joint1_angle_urad", $2, "joint1_speed_urads", $3, "joint2_angle_urad", $4, "joint2_speed_urads", $5 }')" ;;
      *) echo "$(basename $f .txt) | $s | $("$B" final $f < /dev/null | tail -1) | $("$B" swing $f < /dev/null | tail -1)" ;;
    esac
  done
} > $O/reading.txt
same() { if cmp -s "$1" "$2"; then echo "same $(basename $1) $(basename $2)"; else echo "DIFFERENT $(basename $1) $(basename $2)"; fi; }
{
  for dt in 0.0016 0.00032; do
    for L in 2.7 2.8 2.9 2.95 3.05 3.3 3.8 4.5; do same $W/s4_r1_L${L}_$dt.txt $R51/s3_r1_L${L}_$dt.txt; done
    for a in 0.3 0.1 0; do same $W/s4_arm${a}_r1_L2.5_$dt.txt $R51/s3_arm${a}_r1_L2.5_$dt.txt; done
    same $W/free_s4_$dt.txt $R51/free_s3_$dt.txt
  done
} > $O/checks.txt
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
cat $O/reading.txt $O/checks.txt
