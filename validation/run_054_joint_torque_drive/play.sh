#!/usr/bin/env bash
# Run 054: one arm on one hinge (tools/nwt_joint.py) under a joint torque and a joint drive, on Newton 1.7.0, against
# closed forms: issue 25 (XPBD's joints answering a torque and gravity with unequal relaxations; #4317 beside it),
# issue 26 (XPBD's drive by its iteration count), issue 27 (a driven joint held at rest past pi; #4316 beside XPBD).
# The README's predictions were pushed before these plays. Then reading.txt (sx_contact final, each play) and
# checks.txt (sx_contact rule).
# usage: play.sh <sx_contact binary>   (repository root; STOCK_VENV, PR4316_VENV and PR4317_VENV set: Newton 1.7.0 as
#   released, and with each pull request's tree first on the path, run 053's engines)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"
O=validation/run_054_joint_torque_drive; ROOT=$(pwd)
ARM="mass=1 radius=0.05 arm=0.5"
plays() {  # the play list: <name> <environment: stock, 4316 or 4317> <settings...>
  local dt a it t
  # C0: the rig unchanged for a play without the new settings (run 037's stock none and reach at 1.6 ms)
  echo "c0_none_0.0016 stock dt=0.0016 mass=1.5 radius=0.03 arm=0.3 gravity=0 omega0=3 secs=1.6 solver=xpbd"
  echo "c0_reach_0.0016 stock dt=0.0016 mass=1.5 radius=0.03 arm=0.3 gravity=0 omega0=3 secs=1.6 lo=-0.5 hi=3.6 solver=xpbd"
  for dt in 0.0001 0.00005; do
    for a in xpbd xpbd_eq xpbd_4317 featherstone mujoco; do
      case $a in
        xpbd) e="stock solver=xpbd";; xpbd_eq) e="stock solver=xpbd opt.joint_angular_relaxation=0.7";;
        xpbd_4317) e="4317 solver=xpbd";; *) e="stock solver=$a";;
      esac
      echo "torque_${a}_$dt $e dt=$dt $ARM gravity=0 torque=1 secs=0.05"
      echo "gravity_${a}_$dt $e dt=$dt $ARM gravity=1 secs=0.05"
    done
    for it in 1 2 4 8 16; do echo "drive_xpbd_it${it}_$dt stock solver=xpbd iterations=$it dt=$dt $ARM gravity=0 angle0=0.2 drivek=10 target=0 secs=0.1"; done
    for a in featherstone mujoco; do echo "drive_${a}_$dt stock solver=$a dt=$dt $ARM gravity=0 angle0=0.2 drivek=10 target=0 secs=0.1"; done
    for t in 2.5 3.5; do for a in semi xpbd xpbd_4316 vbd featherstone mujoco; do
      case $a in xpbd_4316) e="4316 solver=xpbd";; *) e="stock solver=$a";; esac
      echo "hold_${a}_${t}_$dt $e dt=$dt $ARM gravity=0 angle0=$t drivek=100 drived=10 target=$t secs=1"
    done; done
  done
}
group() {  # <environment>: its plays, in a scratch folder
  local g=$1 venv X n e rest
  case $g in stock) venv="$STOCK_VENV";; 4316) venv="$PR4316_VENV";; 4317) venv="$PR4317_VENV";; esac
  X=$(mktemp -d); cp -R tools $X/
  plays | awk -v g=$g '$2 == g' > $X/list.txt
  (cd $X && . "$venv/bin/activate" && mkdir -p runs stats &&
   while read -r n e rest; do python tools/nwt_joint.py runs/$n.txt $rest > stats/$n.txt 2>> runs/log_$g.txt; done < list.txt)
  mkdir -p $ROOT/$O/runs $ROOT/$O/stats; cp $X/runs/* $ROOT/$O/runs/; cp $X/stats/* $ROOT/$O/stats/; rm -rf $X
}
date -u +%FT%TZ > $O/started.txt
for g in stock 4316 4317; do group $g & done
wait
date -u +%FT%TZ > $O/finished.txt
# ---- reading
R=$O/reading.txt; : > $R
for n in $(plays | awk '{print $1}'); do echo "$n $("$B" final $O/runs/$n.txt < /dev/null | tail -1)" >> $R; done
pick() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $R; }
# ---- checks
C=$O/checks.txt; : > $C
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $C; }
same=0; for f in none reach; do cmp -s $O/runs/c0_${f}_0.0016.txt validation/run_037_study_05/stock/runs/${f}_0.0016.txt && same=$((same + 1)); done
rule C0_rig_unchanged eq $same 2
for dt in 0.0001 0.00005; do
  for a in xpbd xpbd_eq xpbd_4317 featherstone mujoco; do
    rule P1_torque_${a}_$dt all_within 4967 100 $(pick torque_${a}_$dt angle_urad)
    rule P1_gravity_${a}_$dt all_within -24338 100 $(pick gravity_${a}_$dt angle_urad)
  done
  for a in xpbd_it1 xpbd_it2 xpbd_it4 xpbd_it8 xpbd_it16 featherstone mujoco; do
    rule P2_drive_${a}_$dt all_within 161563 400 $(pick drive_${a}_$dt angle_urad)
  done
  for t in 2500000 3500000; do for a in semi xpbd xpbd_4316 vbd featherstone mujoco; do
    n=hold_${a}_$(echo $t | sed 's/00000$//; s/^\(.\)/\1./')_$dt
    rule P3_hold_${a}_${t}_$dt all_within $t 1000 $(pick $n angle_urad)
    rule P3_still_${a}_${t}_$dt all_le 10000 $(pick $n speed_urads)
    rule P3_still_lo_${a}_${t}_$dt all_ge -10000 $(pick $n speed_urads)
  done; done
done
echo "checks: $(wc -l < $C | tr -d ' '), held: $(grep -c ': HELD$' $C)" >> $C
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
cat $C
