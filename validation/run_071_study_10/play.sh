#!/usr/bin/env bash
# Run 071: the tenth registered study (preregistrations/PREREGISTRATION_10.md), played once on Newton 1.7.0: XPBD's
# speed floor (17), its relaxations (25), its drive (26), and a joint past pi (7). Scenes A to D, each play into this
# run's runs/ and stats/, the suite into suites/, then every registered rule judged by sx_contact rule (rules.txt), the
# measured lines beside them (measured.txt).
# DRY=1 plays one throwaway play of each scene (no suite), into dry/, to check that the runner runs to the end.
# usage: play.sh <folder holding sx_contact and sx_contact_suite.sh> <engine folder>   (repository root; the engine
#   folder made by validation/run_065_xpbd_floor_relaxation_drive/setup_engine.sh)
set -u
M="$(cd "${1:?usage: play.sh <measure folder> <engine folder>}" && pwd)"; B=$M/sx_contact; E="$(cd "${2:?}" && pwd)"
O=validation/run_071_study_10; ROOT=$(pwd)
ARMB="mass=1.6 radius=0.04 arm=0.35"
D7="mass=2 radius=0.035 arm=0.25 gravity=0 omega0=3.5 secs=1.4"
if [ "${DRY:-0}" = 1 ]; then
  OUT=$O/dry; BS="0.0005"; CI="2"; DS="0.004"; A2S="0.004"
else
  OUT=$O; BS="0.0002 0.00004"; CI="1 3 6 12"; DS="0.0016 0.0004"; A2S="0.002 0.005"
fi
plays() {  # <name> <environment> <rig> <settings...>
  local e dt it
  for e in stock off on; do
    echo "a1_free_$e $e nwt_contact dt=0.002 mass=2 gravity=0 h0=1 secs=1.5 vx0=0.00003 solver=xpbd"
    for dt in $A2S; do echo "a2_push_${e}_$dt $e nwt_contact dt=$dt mass=2 gravity=0 h0=1 secs=1.5 push=0.07 solver=xpbd"; done
    echo "a3_turn_$e $e nwt_joint dt=0.002 mass=0.8 radius=0.04 arm=0.3 gravity=0 omega0=0.00004 secs=1.5 solver=xpbd"
  done
  for dt in $BS; do
    for e in stock 4317 4317on 4318on on; do
      echo "b_torque_${e}_$dt $e nwt_joint dt=$dt $ARMB gravity=0 torque=0.7 secs=0.04 solver=xpbd"
      echo "b_gravity_${e}_$dt $e nwt_joint dt=$dt $ARMB gravity=1 secs=0.04 solver=xpbd"
    done
    for it in $CI; do
      echo "c_drive_stock_it${it}_$dt stock nwt_joint dt=$dt $ARMB gravity=0 angle0=0.15 drivek=25 target=0 secs=0.08 solver=xpbd iterations=$it"
      echo "c_drive_pd_it${it}_$dt 4318 nwt_joint dt=$dt $ARMB gravity=0 angle0=0.15 drivek=25 target=0 secs=0.08 solver=xpbd iterations=$it opt.joint_drive_mode=pd"
    done
    echo "c_free_stock_$dt stock nwt_joint dt=$dt $ARMB gravity=0 angle0=0.15 drivek=25 target=0 secs=0.08 solver=xpbd"
    echo "c_effort_stock_$dt stock nwt_joint dt=$dt $ARMB gravity=0 angle0=0.15 drivek=25 target=0 secs=0.08 solver=xpbd elimit=1.2"
    echo "c_effort_pd_$dt 4318 nwt_joint dt=$dt $ARMB gravity=0 angle0=0.15 drivek=25 target=0 secs=0.08 solver=xpbd elimit=1.2 opt.joint_drive_mode=pd"
  done
  for dt in $DS; do
    echo "d_none_xpbd_$dt stock nwt_joint dt=$dt $D7 solver=xpbd"
    echo "d_inside_xpbd_$dt stock nwt_joint dt=$dt $D7 lo=-0.6 hi=5.6 solver=xpbd"
    echo "d_none_4318_$dt 4318 nwt_joint dt=$dt $D7 solver=xpbd"
    echo "d_inside_4318_$dt 4318 nwt_joint dt=$dt $D7 lo=-0.6 hi=5.6 solver=xpbd"
    echo "d_none_vbd_$dt stock nwt_joint dt=$dt $D7 solver=vbd place=first"
    echo "d_inside_vbd_$dt stock nwt_joint dt=$dt $D7 lo=-0.6 hi=5.6 solver=vbd place=first"
  done
}
envof() {  # <environment>: its venv and switch
  case $1 in
    stock) echo "$E/stock 0";; off) echo "$E/nofloor 0";; on) echo "$E/nofloor 1";; 4317) echo "$E/pr4317 0";;
    4317on) echo "$E/pr4317_nofloor 1";; 4318) echo "$E/pr4318 0";; 4318on) echo "$E/pr4318_nofloor 1";;
  esac
}
group() {  # <environment>: its plays
  local g=$1 venv sw; set -- $(envof $g); venv=$1; sw=$2
  ( . "$venv/bin/activate"; unset NEWTON_XPBD_NO_SPEED_FLOOR; [ $sw = 1 ] && export NEWTON_XPBD_NO_SPEED_FLOOR=1
    plays | awk -v g=$g '$2 == g { $2 = ""; print }' | while read -r n rig rest; do
      python tools/$rig.py $OUT/runs/$n.txt $rest > $OUT/stats/$n.txt 2>> $OUT/runs/log_$g.txt; done )
}
suite() {  # <label> <environment>: the contact suite on XPBD, its verdicts
  local l=$1 venv sw; set -- $(envof $2); venv=$1; sw=$2
  ( . "$venv/bin/activate"; unset NEWTON_XPBD_NO_SPEED_FLOOR; [ $sw = 1 ] && export NEWTON_XPBD_NO_SPEED_FLOOR=1
    bash tools/contact_suite.sh study10_$l solver=xpbd > $OUT/runs/log_suite_$l.txt 2>&1 )
  mkdir -p $OUT/suites; rm -rf $OUT/suites/$l; mv suites/1/study10_$l $OUT/suites/$l
  bash "$M/sx_contact_suite.sh" $OUT/suites/$l $OUT/suites/$l/verdicts.txt > /dev/null 2>> $OUT/runs/log_suite_$l.txt
}
mkdir -p $OUT/runs $OUT/stats
date -u +%FT%TZ > $OUT/started.txt
for g in stock off on 4317 4317on 4318 4318on; do group $g & done
if [ "${DRY:-0}" != 1 ]; then for l in stock off on; do suite $l $l & done; fi
wait
date -u +%FT%TZ > $OUT/finished.txt
# ---- measuring
pick_s() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
MS=$OUT/measured.txt; : > $MS
for n in $(plays | awk '{print $1}'); do
  st=$(pick_s nan_at_step < $OUT/stats/$n.txt); [ -n "$st" ] || st=$(pick_s out_of_range_at_step < $OUT/stats/$n.txt)
  echo "$n stops ${st:--1} $("$B" final $OUT/runs/$n.txt < /dev/null | tail -1)" >> $MS
done
[ "${DRY:-0}" = 1 ] && { echo "dry run: $(wc -l < $MS | tr -d ' ') measured lines"; cat $MS; exit 0; }
v() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $MS; }
# ---- the rules
R=$OUT/rules.txt; : > $R
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $R; }
abs() { for x in "$@"; do echo "${x#-}"; done; }
same=0; for n in a1_free a2_push_X_0.002 a2_push_X_0.005 a3_turn; do
  case $n in *_X_*) s=${n/_X_/_stock_}; f=${n/_X_/_off_};; *) s=${n}_stock; f=${n}_off;; esac
  cmp -s $OUT/runs/$s.txt $OUT/runs/$f.txt && same=$((same + 1)); done
rule R1_safe_when_off_plays eq $same 4
ns=0; nf=0; for f in $OUT/suites/stock/*.txt; do b=$(basename $f); case $b in stats.txt|verdicts.txt) continue;; esac
  nf=$((nf + 1)); cmp -s $f $OUT/suites/off/$b && ns=$((ns + 1)); done
rule R1_safe_when_off_suite eq $ns $nf
rule R2_fault_there_17 all_eq 0 $(v a1_free_stock speed_urads) $(v a2_push_stock_0.002 speed_urads)
rule R3_kept_17_free all_within 30 30 $(v a1_free_on speed_urads)
rule R3_kept_17_push all_within 52500 1000 $(v a2_push_on_0.002 speed_urads) $(v a2_push_on_0.005 speed_urads) $(v a2_push_stock_0.005 speed_urads)
rule R4_turn_stock all_eq 0 $(v a3_turn_stock speed_urads)
rule R4_turn_on all_within 40 10 $(v a3_turn_on speed_urads)
vd=0; for t in 01 02 03 04 05 06 07 08 09 10; do a=$(grep "^T$t " $OUT/suites/stock/verdicts.txt | awk '{print $NF}'); b=$(grep "^T$t " $OUT/suites/on/verdicts.txt | awk '{print $NF}'); [ -n "$a" ] && [ "$a" = "$b" ] && vd=$((vd + 1)); done
rule R5_nothing_else_17 eq $vd 10
rule R6_fault_there_25 all_ge 4249 $(v b_torque_stock_0.0002 angle_urad)
rule R7_right_25_torque all_within 2832 100 $(v b_torque_4317_0.0002 angle_urad) $(for dt in $BS; do v b_torque_4317on_$dt angle_urad; v b_torque_4318on_$dt angle_urad; done)
rule R7_right_25_gravity all_within -22207 100 $(for dt in $BS; do v b_gravity_4317_$dt angle_urad; v b_gravity_4317on_$dt angle_urad; v b_gravity_4318on_$dt angle_urad; done)
rule R8_fault_there_26 all_le 0 $(for dt in $BS; do v c_drive_stock_it12_$dt angle_urad; done)
rule R9_right_26 all_within 93289 400 $(for dt in $BS; do for it in $CI; do v c_drive_pd_it${it}_$dt angle_urad; done; done)
rule R10_effort_pd all_within 130577 400 $(for dt in $BS; do v c_effort_pd_$dt angle_urad; done)
ig=0; for dt in $BS; do cmp -s $OUT/runs/c_effort_stock_$dt.txt $OUT/runs/c_free_stock_$dt.txt && ig=$((ig + 1)); done
rule R10_effort_ignored_released eq $ig 2
rule R11_fault_there_7 all_ge 100000000 $(abs $(for dt in $DS; do v d_inside_xpbd_$dt speed_urads; done))
# R12 and R13: inside's last angle and speed within 10 urad and 10 urad/s of none's (sx_contact rule near)
for dt in $DS; do
  rule R12_kept_7_xpbd_angle_$dt near $(v d_inside_4318_$dt angle_urad) $(v d_none_4318_$dt angle_urad) 10
  rule R12_kept_7_xpbd_speed_$dt near $(v d_inside_4318_$dt speed_urads) $(v d_none_4318_$dt speed_urads) 10
  rule R13_kept_7_vbd_angle_$dt near $(v d_inside_vbd_$dt angle_urad) $(v d_none_vbd_$dt angle_urad) 10
  rule R13_kept_7_vbd_speed_$dt near $(v d_inside_vbd_$dt speed_urads) $(v d_none_vbd_$dt speed_urads) 10
done
grep -rlIF "$HOME" $OUT 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
echo "rules: $(wc -l < $R | tr -d ' '), held: $(grep -c ': HELD$' $R)" >> $R
cat $R
