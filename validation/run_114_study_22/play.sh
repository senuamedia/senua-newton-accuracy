#!/usr/bin/env bash
# Run 114: the twenty-second registered study (preregistrations/PREREGISTRATION_22.md), played once on Newton 1.7.0:
# VBD's rigid solve in displacement form (Senua AI's VBD displacement patch, NEWTON_VBD_DISPLACEMENT=1) on a spinning
# body (issue 13), a free chain at the world's origin, 10 m and 100 m out (issue 12's VBD part), and a hold and a slide
# (contacts kept). Each play into runs/, its error stream into runs/err_<play>.txt and its statistics into stats/, then
# the registered rules judged by sx_contact rule (rules.txt), the measured lines beside them (measured.txt). DRY=1
# plays one throwaway play of each scene and setting (0.02 s), into dry/, to check that the runner runs to the end.
# usage: play.sh <sx_contact binary> <engine folder> [parallel plays a setting]   (repository root)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary> <engine folder>}")" && pwd)/$(basename "$1")"; E="$(cd "${2:?}" && pwd)"; P=${3:-3}
O=validation/run_114_study_22
if [ "${DRY:-0}" = 1 ]; then OUT=$O/dry; SS=0.02; CS=0.02; HS=0.02; HP=0.01; LS=0.02; else OUT=$O; SS=1.5; CS=2; HS=1.6; HP=0.4; LS=0.5; fi
SPIN="mass=2.1 radius=0.035 h0=1 gravity=0 wz0=5 comx=0.025 secs=$SS"
CHAIN="mass1=1.0 mass2=0.8 radius=0.04 arm1=0.22 len1=0.45 arm2=0.2 angle1=0 angle2=0.5 omega1=1.9 omega2=-0.9 gravity=0 secs=$CS"
HOLD="mass=1.4 radius=0.04 h0=0 mu=0.6 push=4.53 pushat=$HP secs=$HS solver=vbd_alm opt.rigid_contact_history=true matching=sticky"
SLIDE="mass=1.1 radius=0.045 h0=0 mu=0.45 vx0=0.8 secs=$LS solver=vbd_alm"
SDT="0.0015 0.0003 0.000075"; CDT="0.0015 0.000375 0.00009375"; HDT="0.0015 0.000075"; X="0 10 100"
xo() { [ $1 = 0 ] || echo " x0=$1"; }
plays() { local e s dt x; for e in stock off on; do
  for s in vbd vbd_alm; do for dt in $SDT; do echo "s_${s}_${e}_$dt $e nwt_contact dt=$dt $SPIN solver=$s"; done; done
  for x in $X; do for dt in $CDT; do echo "c_vbd_${e}_x${x}_$dt $e nwt_chain dt=$dt $CHAIN solver=vbd$(xo $x)"
    [ $e = stock ] && echo "c_feather_x${x}_$dt stock nwt_chain dt=$dt $CHAIN solver=featherstone$(xo $x)"; done; done
  for dt in $HDT; do echo "h_${e}_$dt $e nwt_contact dt=$dt $HOLD"; echo "l_${e}_$dt $e nwt_contact dt=$dt $SLIDE"; done; done; }
mkdir -p $OUT/runs $OUT/stats; date -u +%FT%TZ > $OUT/started.txt
for g in stock off on; do
  ( v=$E/on; [ $g = stock ] && v=$E/stock; . "$v/bin/activate"; unset NEWTON_VBD_DISPLACEMENT; [ $g = on ] && export NEWTON_VBD_DISPLACEMENT=1
    plays | awk -v g=$g '$2 == g { $2 = ""; print }' | xargs -P $P -L 1 bash -c 'python tools/$1.py '"$OUT"'/runs/$0.txt "${@:2}" > '"$OUT"'/stats/$0.txt 2> '"$OUT"'/runs/err_$0.txt' ) &
done
wait; date -u +%FT%TZ > $OUT/finished.txt
grep -rlIF "$HOME" $OUT 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
pick() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
M=$OUT/measured.txt; : > $M
for n in $(plays | awk '{ print $1 }'); do st=$(pick nan_at_step < $OUT/stats/$n.txt); [ -n "$st" ] || st=$(pick out_of_range_at_step < $OUT/stats/$n.txt)
  case $n in c_*) m=chain;; l_*) m=stop;; *) m=creep;; esac
  echo "$n stops ${st:--1} $("$B" $m $OUT/runs/$n.txt < /dev/null | tail -1)" >> $M; done
[ "${DRY:-0}" = 1 ] && { echo "dry run: $(wc -l < $M | tr -d ' ') measured lines"; cat $M; exit 0; }
v() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $M; }
L() { v $1 energy_largest_drift_ppm; }
abs() { echo ${1#-}; }
R=$OUT/rules.txt; : > $R
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $R; }
same=0; tot=0; for n in $(plays | awk '$2 == "stock" && $1 !~ /^c_feather/ { print $1 }'); do tot=$((tot + 1)); cmp -s $OUT/runs/$n.txt $OUT/runs/${n/_stock_/_off_}.txt && same=$((same + 1)); done
rule R1_safe_when_off eq $same $tot
rule R2_spin_drifts_as_released ge $(abs $(v s_vbd_alm_stock_0.000075 mean_speed_ums)) 100
rule R2_chain_loss_grows_as_released ge $(L c_vbd_stock_x0_0.00009375) $(L c_vbd_stock_x0_0.000375)
rule R2_chain_far_worse_as_released ge $(L c_vbd_stock_x10_0.000375) $(( 5 * $(L c_vbd_stock_x0_0.000375) ))
rule R3_centre_still all_in -3 3 $(for s in vbd vbd_alm; do for dt in $SDT; do v s_${s}_on_$dt mean_speed_ums; done; done)
rule R4_loss_falls_with_the_step all_ge 0 $(echo $(( 2 * $(L c_vbd_on_x0_0.0015) - 5 * $(L c_vbd_on_x0_0.000375) )) $(( 2 * $(L c_vbd_on_x0_0.000375) - 5 * $(L c_vbd_on_x0_0.00009375) )))
for dt in $CDT; do rule R5_10m_as_the_origin_at_$dt all_within $(L c_vbd_on_x0_$dt) 3 $(L c_vbd_on_x10_$dt); done
rule R5_100m_falls_with_the_step all_ge 0 $(echo $(( $(L c_vbd_on_x100_0.0015) - $(L c_vbd_on_x100_0.000375) )) $(( $(L c_vbd_on_x100_0.000375) - $(L c_vbd_on_x100_0.00009375) )))
rule R6_hold_still all_in -10 10 $(for dt in $HDT; do v h_on_$dt mean_speed_ums; done)
for dt in $HDT; do rule R6_slide_kept_at_$dt all_within $(v l_stock_$dt slid_um) 100 $(v l_on_$dt slid_um); done
rule R7_numbers all_eq -1 $(plays | awk '{ print $1 }' | while read -r n; do v $n stops; done)
echo "rules: $(wc -l < $R | tr -d ' '), held: $(grep -c ': HELD$' $R)" >> $R
cat $R
