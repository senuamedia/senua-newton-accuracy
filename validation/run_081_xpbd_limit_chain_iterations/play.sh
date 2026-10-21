#!/usr/bin/env bash
# Run 081: XPBD's joint limit on a chain (issue 8), a design probe that decides nothing and states no prediction: run
# 061's chain (two links turning at 2 rad/s, the first joint's limits -1 and 3.3 rad) with the joint-angle patch's
# fourth form (NEWTON_XPBD_JOINT_ANGLE_UNWRAP=4, patches/in_design/xpbd_joint_angle_v4_on_1.7.0.diff) at 2, 8, 32 and
# 128 iterations and at relaxations of 1, at 2.5 and 0.625 ms, on Newton 1.7.0: does the Gauss-Seidel coupling between
# the limit and the outboard link, which run 061 named, hold the chain once it converges? Then measured.txt.
# usage: play.sh   (repository root; V4_VENV the patch's environment)
set -u
O=validation/run_081_xpbd_limit_chain_iterations
CH="mass1=1.2 mass2=0.6 radius=0.04 arm1=0.25 len1=0.5 arm2=0.2 gravity=0 angle1=0 angle2=0 omega1=2 omega2=0 secs=2.5 solver=xpbd lo1=-1 hi1=3.3"
plays() { local it dt r; for dt in 0.0025 0.000625; do for it in 2 8 32 128; do for r in default one; do
  o=""; [ $r = one ] && o="opt.joint_linear_relaxation=1 opt.joint_angular_relaxation=1"
  echo "chain_v4_it${it}_${r}_$dt dt=$dt $CH iterations=$it${o:+ $o}"; done; done; done; }
mkdir -p $O/runs $O/stats; date -u +%FT%TZ > $O/started.txt
( . "$V4_VENV/bin/activate"; export NEWTON_XPBD_JOINT_ANGLE_UNWRAP=4
  plays | xargs -P 4 -L 1 bash -c 'python tools/nwt_chain.py '"$O"'/runs/$0.txt "$@" > '"$O"'/stats/$0.txt 2> '"$O"'/runs/log_$0.txt' )
date -u +%FT%TZ > $O/finished.txt
pick_s() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
M=$O/measured.txt; : > $M
for n in $(plays | awk '{print $1}'); do st=$(pick_s nan_at_step < $O/stats/$n.txt); [ -n "$st" ] || st=$(pick_s out_of_range_at_step < $O/stats/$n.txt)
  echo "$n stops ${st:--1} $(tail -1 $O/runs/$n.txt | awk '{ print "joint1_angle_urad", $2, "joint1_speed_urads", $3, "joint2_angle_urad", $4, "joint2_speed_urads", $5 }')" >> $M; done
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
cat $M
