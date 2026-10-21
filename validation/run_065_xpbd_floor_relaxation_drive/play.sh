#!/usr/bin/env bash
# Run 065: XPBD's speed floor (issue 17, Senua AI's patch in design), its unequal relaxations (issue 25, pull requests
# #4317 and #4318) and its drive by its iteration count (issue 26, #4318's PD drive), on Newton 1.7.0, against closed
# forms; and Study 5's four joint scenes on #4318 (issues 7 and 8), reported. The README's predictions were pushed
# before these plays. Then measured.txt (sx_contact final and creep, each play) and checks.txt (sx_contact rule).
# usage: play.sh <sx_contact binary> <engine folder>   (repository root; the engine folder made by setup_engine.sh)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary> <engine folder>}")" && pwd)/$(basename "$1")"
E="$(cd "${2:?}" && pwd)"
O=validation/run_065_xpbd_floor_relaxation_drive; ROOT=$(pwd)
FREE="gravity=0 h0=1 secs=1 solver=xpbd"
HOLD="mass=1 radius=0.05 h0=0 pushat=0.5 secs=2 solver=xpbd mu=0.5 iterations=32"
ARM="mass=1 radius=0.05 arm=0.5"
S5="mass=1.5 radius=0.03 arm=0.3 gravity=0 omega0=3 solver=xpbd"
plays() {  # the play list: <name> <environment> <rig> <settings...>
  local e dt it m
  for e in stock off on; do  # A, issue 17: the floor (off: the patch's tree, its switch unset)
    echo "a1_free_$e $e nwt_contact dt=0.001 $FREE vx0=0.00005"
    for dt in 0.001 0.004; do echo "a2_push_${e}_$dt $e nwt_contact dt=$dt $FREE push=0.05"; done
    echo "a3_turn_$e $e nwt_joint dt=0.001 $ARM gravity=0 omega0=0.00005 secs=1 solver=xpbd"
    echo "a4_hold_${e}_0.000125 $e nwt_contact dt=0.000125 $HOLD push=2.94"
    echo "a4_half_${e}_0.0005 $e nwt_contact dt=0.0005 $HOLD push=1.47"
    echo "a4_hold_${e}_0.002 $e nwt_contact dt=0.002 $HOLD push=2.94"
  done
  for dt in 0.0001 0.00005; do  # B, issue 25: a joint torque and gravity at the default relaxations
    for e in stock on 4317 4317on 4318 4318on; do
      echo "b_torque_${e}_$dt $e nwt_joint dt=$dt $ARM gravity=0 torque=1 secs=0.05 solver=xpbd"
      echo "b_gravity_${e}_$dt $e nwt_joint dt=$dt $ARM gravity=1 secs=0.05 solver=xpbd"
    done
    for it in 1 2 4 8 16; do  # C, issue 26: the drive at each iteration count
      echo "c_drive_compliance_it${it}_$dt stock nwt_joint dt=$dt $ARM gravity=0 angle0=0.2 drivek=10 target=0 secs=0.1 solver=xpbd iterations=$it"
      for m in pd implicit; do
        echo "c_drive_${m}_it${it}_$dt 4318 nwt_joint dt=$dt $ARM gravity=0 angle0=0.2 drivek=10 target=0 secs=0.1 solver=xpbd iterations=$it opt.joint_drive_mode=$m"
      done
    done
    echo "c_effort_compliance_$dt stock nwt_joint dt=$dt $ARM gravity=0 angle0=0.2 drivek=10 target=0 secs=0.1 solver=xpbd iterations=2 elimit=0.5"
    echo "c_effort_pd_$dt 4318 nwt_joint dt=$dt $ARM gravity=0 angle0=0.2 drivek=10 target=0 secs=0.1 solver=xpbd iterations=2 elimit=0.5 opt.joint_drive_mode=pd"
  done
  for dt in 0.0016 0.00032; do  # D, issues 7 and 8: Study 5's scenes on #4318, reported
    echo "d_none_4318_$dt 4318 nwt_joint dt=$dt $S5 secs=1.6"
    echo "d_inside_4318_$dt 4318 nwt_joint dt=$dt $S5 secs=1.6 lo=-0.5 hi=5"
    echo "d_reach_4318_$dt 4318 nwt_joint dt=$dt $S5 secs=1.6 lo=-0.5 hi=3.6"
    echo "d_below_4318_$dt 4318 nwt_joint dt=$dt $S5 secs=1.4 lo=-0.5 hi=2.5"
  done
}
group() {  # <environment>: its plays, in a scratch folder
  local g=$1 venv sw X
  case $g in
    stock) venv=$E/stock; sw=0;; off) venv=$E/nofloor; sw=0;; on) venv=$E/nofloor; sw=1;;
    4317) venv=$E/pr4317; sw=0;; 4317on) venv=$E/pr4317_nofloor; sw=1;;
    4318) venv=$E/pr4318; sw=0;; 4318on) venv=$E/pr4318_nofloor; sw=1;;
  esac
  X=$(mktemp -d); cp -R tools $X/
  plays | awk -v g=$g '$2 == g' > $X/list.txt
  (cd $X && . "$venv/bin/activate" && unset NEWTON_XPBD_NO_SPEED_FLOOR && { [ $sw = 1 ] && export NEWTON_XPBD_NO_SPEED_FLOOR=1 || true; } &&
   mkdir -p runs stats &&
   while read -r n e rig rest; do python tools/$rig.py runs/$n.txt $rest > stats/$n.txt 2>> runs/log_$g.txt; done < list.txt)
  mkdir -p $ROOT/$O/runs $ROOT/$O/stats; cp $X/runs/* $ROOT/$O/runs/; cp $X/stats/* $ROOT/$O/stats/; rm -rf $X
}
date -u +%FT%TZ > $O/started.txt
for g in stock off on 4317 4317on 4318 4318on; do group $g & done
wait
date -u +%FT%TZ > $O/finished.txt
# ---- measuring
M=$O/measured.txt; : > $M
for n in $(plays | awk '{print $1}'); do
  f=$O/runs/$n.txt; l="$n $("$B" final $f < /dev/null | tail -1)"
  case $n in a1_*|a2_*|a4_*) l="$l $("$B" creep $f < /dev/null | tail -1)";; esac
  echo "$l" >> $M
done
pick() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $M; }
# ---- checks
C=$O/checks.txt; : > $C
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $C; }
same=0; for n in a1_free a2_push_X_0.001 a2_push_X_0.004 a3_turn a4_hold_X_0.000125 a4_half_X_0.0005 a4_hold_X_0.002; do
  case $n in *_X_*) s=${n/_X_/_stock_}; f=${n/_X_/_off_};; *) s=${n}_stock; f=${n}_off;; esac
  cmp -s $O/runs/$s.txt $O/runs/$f.txt && same=$((same + 1)); done
rule A0_safe_when_off eq $same 7
rule A1_free_stock_stopped all_eq 0 $(pick a1_free_stock speed_urads)
rule A1_free_on_kept all_within 50 50 $(pick a1_free_on speed_urads)
rule A2_push_stock_1ms_stopped all_eq 0 $(pick a2_push_stock_0.001 speed_urads)
rule A2_push_stock_4ms_moves all_within 50000 1000 $(pick a2_push_stock_0.004 speed_urads)
rule A2_push_on all_within 50000 1000 $(pick a2_push_on_0.001 speed_urads) $(pick a2_push_on_0.004 speed_urads)
rule A3_turn_stock_stopped all_eq 0 $(pick a3_turn_stock speed_urads)
rule A3_turn_on_kept all_within 50 10 $(pick a3_turn_on speed_urads)
rule A4_floor_hidden_stock all_eq 0 $(pick a4_hold_stock_0.000125 mean_speed_ums) $(pick a4_half_stock_0.0005 mean_speed_ums)
rule A4_floor_shown_on_lo all_ge 50 $(pick a4_hold_on_0.000125 mean_speed_ums) $(pick a4_half_on_0.0005 mean_speed_ums)
rule A4_floor_shown_on_hi all_le 200 $(pick a4_hold_on_0.000125 mean_speed_ums) $(pick a4_half_on_0.0005 mean_speed_ums)
rule A4_2ms_unchanged all_within $(pick a4_hold_stock_0.002 mean_speed_ums) 100 $(pick a4_hold_on_0.002 mean_speed_ums)
for dt in 0.0001 0.00005; do
  rule B1_torque_stock_wrong_$dt all_ge 7450 $(pick b_torque_stock_$dt angle_urad)
  rule B1_torque_on_wrong_$dt all_ge 7450 $(pick b_torque_on_$dt angle_urad)
  rule B2_torque_right_$dt all_within 4967 100 $(pick b_torque_4317on_$dt angle_urad) $(pick b_torque_4318on_$dt angle_urad)
  rule B3_gravity_right_$dt all_within -24338 100 $(for e in 4317 4317on 4318 4318on; do pick b_gravity_${e}_$dt angle_urad; done)
  rule C1_compliance_soft_it1_$dt all_ge 165000 $(pick c_drive_compliance_it1_$dt angle_urad)
  rule C1_compliance_stiff_it16_$dt all_le 0 $(pick c_drive_compliance_it16_$dt angle_urad)
  rule C2_pd_right_$dt all_within 161563 400 $(for it in 1 2 4 8 16; do pick c_drive_pd_it${it}_$dt angle_urad; done)
  rule C3_effort_pd_$dt all_within 190066 400 $(pick c_effort_pd_$dt angle_urad)
  cmp -s $O/runs/c_effort_compliance_$dt.txt $O/runs/c_drive_compliance_it2_$dt.txt && ign=1 || ign=0
  rule C4_effort_ignored_compliance_$dt eq $ign 1
done
rule B4_torque_4317_held_0.00005 all_le 497 $(pick b_torque_4317_0.00005 angle_urad) $(pick b_torque_4318_0.00005 angle_urad)
rule B5_torque_4317_right_0.0001 all_within 4967 100 $(pick b_torque_4317_0.0001 angle_urad) $(pick b_torque_4318_0.0001 angle_urad)
echo "checks: $(wc -l < $C | tr -d ' '), held: $(grep -c ': HELD$' $C)" >> $C
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
cat $C
