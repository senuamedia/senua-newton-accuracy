#!/usr/bin/env bash
# Run 117: the twenty-third registered study (preregistrations/PREREGISTRATION_23.md), played once on Newton 1.7.0:
# VBD's spinning body still and its contacts settling in displacement form (Senua AI's VBD displacement patch,
# NEWTON_VBD_DISPLACEMENT=1), issue 13. Each play into runs/, its error stream into runs/err_<play>.txt and its
# statistics into stats/, then the registered rules judged by sx_contact rule (rules.txt), the measured lines beside
# them (measured.txt). DRY=1 plays one throwaway play of each scene and setting (0.02 s), into dry/, to check that the
# runner runs to the end.
# usage: play.sh <sx_contact binary> <engine folder> [parallel plays a setting]   (repository root)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary> <engine folder>}")" && pwd)/$(basename "$1")"; E="$(cd "${2:?}" && pwd)"; P=${3:-3}
O=validation/run_117_study_23
if [ "${DRY:-0}" = 1 ]; then OUT=$O/dry; SS=0.02; L1S=0.02; L2S=0.02; HS=0.02; HP=0.01; else OUT=$O; SS=1.2; L1S=0.6; L2S=0.4; HS=1.2; HP=0.3; fi
SPIN="mass=1.7 radius=0.045 h0=1 gravity=0 wz0=3.5 comx=0.03 secs=$SS"
L1="mass=0.8 radius=0.04 h0=0 mu=0.4 vx0=1.0 secs=$L1S solver=vbd_alm"
L2="mass=1.5 radius=0.05 h0=0 mu=0.55 vx0=0.6 secs=$L2S solver=vbd_alm"
HOLD="mass=0.9 radius=0.035 h0=0 mu=0.5 push=2.2 pushat=$HP secs=$HS solver=vbd_alm opt.rigid_contact_history=true matching=sticky"
SDT="0.0012 0.00024 0.00006"; LDT="0.0012 0.00024 0.00006 0.00003"; HDT="0.0012 0.00006"
plays() { local e s dt; for e in stock off on; do
  for s in vbd vbd_alm; do for dt in $SDT; do echo "s_${s}_${e}_$dt $e dt=$dt $SPIN solver=$s"; done; done
  for dt in $LDT; do echo "l1_${e}_$dt $e dt=$dt $L1"; echo "l2_${e}_$dt $e dt=$dt $L2"; done
  for dt in $HDT; do echo "h_${e}_$dt $e dt=$dt $HOLD"; done; done; }
mkdir -p $OUT/runs $OUT/stats; date -u +%FT%TZ > $OUT/started.txt
for g in stock off on; do
  ( v=$E/on; [ $g = stock ] && v=$E/stock; . "$v/bin/activate"; unset NEWTON_VBD_DISPLACEMENT; [ $g = on ] && export NEWTON_VBD_DISPLACEMENT=1
    plays | awk -v g=$g '$2 == g { $2 = ""; print }' | xargs -P $P -L 1 bash -c 'python tools/nwt_contact.py '"$OUT"'/runs/$0.txt "$@" > '"$OUT"'/stats/$0.txt 2> '"$OUT"'/runs/err_$0.txt' ) &
done
wait; date -u +%FT%TZ > $OUT/finished.txt
grep -rlIF "$HOME" $OUT 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
pick() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
M=$OUT/measured.txt; : > $M
for n in $(plays | awk '{ print $1 }'); do st=$(pick nan_at_step < $OUT/stats/$n.txt); [ -n "$st" ] || st=$(pick out_of_range_at_step < $OUT/stats/$n.txt)
  case $n in l1_*|l2_*) m=stop;; *) m=creep;; esac
  echo "$n stops ${st:--1} $("$B" $m $OUT/runs/$n.txt < /dev/null | tail -1)" >> $M; done
[ "${DRY:-0}" = 1 ] && { echo "dry run: $(wc -l < $M | tr -d ' ') measured lines"; cat $M; exit 0; }
v() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $M; }
abs() { echo ${1#-}; }
R=$OUT/rules.txt; : > $R
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $R; }
same=0; tot=0; for n in $(plays | awk '$2 == "stock" { print $1 }'); do tot=$((tot + 1)); cmp -s $OUT/runs/$n.txt $OUT/runs/${n/_stock_/_off_}.txt && same=$((same + 1)); done
rule R1_safe_when_off eq $same $tot
rule R2_spin_drifts_as_released ge $(abs $(v s_vbd_alm_stock_0.00006 mean_speed_ums)) 100
rule R3_centre_still all_in -3 3 $(for s in vbd vbd_alm; do for dt in $SDT; do v s_${s}_on_$dt mean_speed_ums; done; done)
for l in l1 l2; do rule R4_${l}_settles all_within $(v ${l}_on_0.00003 slid_um) 200 $(v ${l}_on_0.00024 slid_um) $(v ${l}_on_0.00006 slid_um); done
rule R5_hold_kept all_in -10 10 $(for dt in $HDT; do v h_on_$dt mean_speed_ums; done)
rule R6_numbers all_eq -1 $(plays | awk '{ print $1 }' | while read -r n; do v $n stops; done)
echo "rules: $(wc -l < $R | tr -d ' '), held: $(grep -c ': HELD$' $R)" >> $R
cat $R
