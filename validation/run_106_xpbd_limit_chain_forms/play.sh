#!/usr/bin/env bash
# Run 106: XPBD's joint limit on a chain against the converged right answer (issue 8), a design probe that decides
# nothing and states no prediction: run 105's chain on XPBD as released (form 0) and under each form of the joint-angle
# patch (NEWTON_XPBD_JOINT_ANGLE_UNWRAP=1 to 4, patches/in_design/xpbd_joint_angle_v4_on_1.7.0.diff), at XPBD's default
# relaxations and at 1, at 2, 16 and 128 iterations, at 0.625 ms, on Newton 1.7.0; read at run 105's instants beside
# run 105's reference (MuJoCo's own engine, its 0.2 ms limit). Then measured.txt.
# usage: play.sh   (repository root; STOCK_VENV Newton 1.7.0, V4_VENV the patch's tree)
set -u
O=validation/run_106_xpbd_limit_chain_forms
CH="mass1=1.2 mass2=0.6 radius=0.04 arm1=0.25 len1=0.5 arm2=0.2 gravity=0 angle1=0 angle2=0 omega1=2 omega2=0 secs=2.5 lo1=-1 hi1=3.3"
TS="1.8 2.0 2.1 2.2 2.5"
plays() { local f r it o; for f in 0 1 2 3 4; do for r in default one; do for it in 2 16 128; do
  o=""; [ $r = one ] && o=" opt.joint_linear_relaxation=1 opt.joint_angular_relaxation=1"
  echo "f${f}_${r}_it$it $f dt=0.000625 $CH solver=xpbd iterations=$it$o"; done; done; done; }
mkdir -p $O/runs $O/stats; date -u +%FT%TZ > $O/started.txt
for f in 0 1 2 3 4; do
  ( v=$V4_VENV; [ $f = 0 ] && v=$STOCK_VENV; . "$v/bin/activate"; unset NEWTON_XPBD_JOINT_ANGLE_UNWRAP; [ $f = 0 ] || export NEWTON_XPBD_JOINT_ANGLE_UNWRAP=$f
    plays | awk -v f=$f '$2 == f { $2 = ""; print }' | xargs -P 2 -L 1 bash -c 'python tools/nwt_chain.py '"$O"'/runs/$0.txt "$@" > '"$O"'/stats/$0.txt 2> '"$O"'/runs/log_$0.txt' ) &
done
wait; date -u +%FT%TZ > $O/finished.txt
at() { awk -v t=$2 '$1 == "CHAIN" { for (i = 2; i < NF; i++) if ($i == "dt_ns") dt = $(i + 1) / 1e9; next }
  dt > 0 && $1 == sprintf("%d", t / dt - 1 + 0.5) - 0 { print "j1_urad", $2, "j1_urads", $3, "j2_urads", $5; exit }' $1; }
M=$O/measured.txt; : > $M
R=validation/run_105_xpbd_limit_chain_reference/runs/ref_0.0002.txt
for t in $TS; do echo "reference t $t $(at $R $t)" >> $M; done
for n in $(plays | awk '{print $1}'); do for t in $TS; do echo "$n t $t $(at $O/runs/$n.txt $t)" >> $M; done; done
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
awk '$3 == "2.5" || $3 == "2.0"' $M
