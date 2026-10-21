#!/usr/bin/env bash
# Run 126: the twenty-fifth registered study (preregistrations/PREREGISTRATION_25.md), played once on Newton 1.7.0:
# MuJoCo's recommended configuration (the elliptic cone with the noslip solver) on the MuJoCo solver's Warp path, by
# Senua AI's MuJoCo Warp noslip patch with the record's Newton noslip patch (issue 15), beside the CPU path. Each play
# into runs/, its error stream into runs/err_<play>.txt and its statistics into stats/, then the registered rules judged
# by sx_contact rule (rules.txt), the measured lines beside them (measured.txt). DRY=1 plays one throwaway play of each
# scene and setting (0.04 s), into dry/, to check that the runner runs to the end.
# usage: play.sh <sx_contact binary> <engine folder> [parallel plays a setting]   (repository root)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary> <engine folder>}")" && pwd)/$(basename "$1")"; E="$(cd "${2:?}" && pwd)"; P=${3:-3}
O=validation/run_126_study_25
if [ "${DRY:-0}" = 1 ]; then OUT=$O/dry; HS=0.04; HP=0.02; LS=0.04; DS=0.04; else OUT=$O; HS=1.4; HP=0.3; LS=0.8; DS=0.8; fi
HOLD="mass=1.2 radius=0.045 h0=0 mu=0.7 push=5.36 pushat=$HP secs=$HS solver=mujoco opt.cone=elliptic"
SLIDE="mass=0.9 radius=0.035 h0=0 mu=0.5 vx0=1.1 secs=$LS solver=mujoco opt.cone=elliptic"
DROP="mass=1.4 radius=0.05 h0=0.03 mu=0.4 secs=$DS solver=mujoco opt.cone=elliptic"
CPU="opt.use_mujoco_cpu=true"; NS="opt.noslip_iterations=5"
plays() { local dt s; for dt in 0.002 0.0005; do for s in hold slide drop; do
  case $s in hold) a=$HOLD;; slide) a=$SLIDE;; drop) a=$DROP;; esac
  echo "${s}_stock_$dt stock dt=$dt $a"
  echo "${s}_off_$dt on dt=$dt $a"
  echo "${s}_cpuoff_$dt on dt=$dt $a $CPU"
  echo "${s}_on_$dt on dt=$dt $a $NS"
  echo "${s}_cpuon_$dt on dt=$dt $a $NS $CPU"; done; done; }
mkdir -p $OUT/runs $OUT/stats; date -u +%FT%TZ > $OUT/started.txt
for g in stock on; do
  ( . "$E/$g/bin/activate"
    plays | awk -v g=$g '$2 == g { $2 = ""; print }' | xargs -P $P -L 1 bash -c 'python tools/nwt_contact.py '"$OUT"'/runs/$0.txt "$@" > '"$OUT"'/stats/$0.txt 2> '"$OUT"'/runs/err_$0.txt' ) &
done
wait; date -u +%FT%TZ > $OUT/finished.txt
grep -rlIF "$HOME" $OUT 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
pick() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
M=$OUT/measured.txt; : > $M
for n in $(plays | awk '{ print $1 }'); do st=$(pick nan_at_step < $OUT/stats/$n.txt)
  case $n in hold*) m=creep;; slide*) m=stop;; *) m=rest;; esac
  echo "$n stops ${st:--1} $("$B" $m $OUT/runs/$n.txt < /dev/null | tail -1)" >> $M; done
[ "${DRY:-0}" = 1 ] && { echo "dry run: $(wc -l < $M | tr -d ' ') measured lines"; cat $M; exit 0; }
v() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $M; }
R=$OUT/rules.txt; : > $R
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $R; }
same=0; tot=0; for n in $(plays | awk '$2 == "stock" { print $1 }'); do tot=$((tot + 1)); cmp -s $OUT/runs/$n.txt $OUT/runs/${n/_stock_/_off_}.txt && same=$((same + 1)); done
rule R1_safe_when_off eq $same $tot
rule R2_warp_creeps_as_released all_ge 100 $(for dt in 0.002 0.0005; do s=$(v hold_stock_$dt mean_speed_ums); echo ${s#-}; done)
rule R3_held all_in -10 10 $(for dt in 0.002 0.0005; do v hold_on_$dt mean_speed_ums; done)
for dt in 0.002 0.0005; do
  rule R4_hold_as_mujoco_c_$dt near $(v hold_on_$dt mean_speed_ums) $(v hold_cpuon_$dt mean_speed_ums) 10
  rule R4_slide_as_mujoco_c_$dt within $(v slide_on_$dt slid_um) $(v slide_cpuon_$dt slid_um) 100
  rule R4_weight_as_mujoco_c_$dt within $(v drop_on_$dt mean_ground_force_mN) $(v drop_cpuon_$dt mean_ground_force_mN) 100
  rule R5_slide_kept_$dt within $(v slide_on_$dt slid_um) $(v slide_off_$dt slid_um) 20
  rule R5_weight_kept_$dt within $(v drop_on_$dt mean_ground_force_mN) $(v drop_off_$dt mean_ground_force_mN) 100; done
rule R6_numbers all_eq -1 $(plays | awk '{ print $1 }' | while read -r n; do v $n stops; done)
echo "rules: $(wc -l < $R | tr -d ' '), held: $(grep -c ': HELD$' $R)" >> $R
cat $R
