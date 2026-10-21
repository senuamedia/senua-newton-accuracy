#!/usr/bin/env bash
# Run 119: the twenty-fourth registered study (preregistrations/PREREGISTRATION_24.md), played once on Newton 1.7.0: a
# light cloth and a box coupled two-way through SolverCoupledProxy (issue 21, #4698), by Senua AI's VBD proxy coupling
# patch's third form (NEWTON_VBD_PROXY_COUPLING=1 the rewind, =2 that and the realized harvest). Each play into runs/
# (with the box's and the cloth's CONTACT files), its error stream into runs/err_<play>.txt and its statistics into
# stats/, then the registered rules judged by sx_contact rule (rules.txt), the measured lines beside them
# (measured.txt). DRY=1 plays one throwaway play of each scene and setting (0.04 s), into dry/, to check that the runner
# runs to the end.
# usage: play.sh <sx_contact binary> <engine folder> [parallel plays a setting]   (repository root)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary> <engine folder>}")" && pwd)/$(basename "$1")"; E="$(cd "${2:?}" && pwd)"; P=${3:-2}
O=validation/run_119_study_24
if [ "${DRY:-0}" = 1 ]; then OUT=$O/dry; S6=0.04; S3=0.04; S2=0.04; else OUT=$O; S6=0.6; S3=0.3; S2=2; fi
RB="cloth_mass=0.06 box_hx=0.09 box_hz=0.03 box_mass=0.3"
TB="cloth_mass=0.06 box_hx=0.09 box_hz=0.09 box_mass=0.3"
WB="scene=throw cloth_mass=0.05 cloth_vz=-0.7"
HB="scene=hammock cloth_mass=0.05 box_hx=0.04 box_hz=0.02 box_mass=0.15"
plays() { local e it; for e in stock off p1 p2; do for it in 15 50; do
  echo "r_fb1_${e}_it$it $e secs=$S6 feedback=1 iterations=$it $RB"
  echo "t_fb0_${e}_it$it $e secs=$S6 feedback=0 iterations=$it $TB"
  echo "t_fb1_${e}_it$it $e secs=$S6 feedback=1 iterations=$it $TB"
  echo "w_${e}_it$it $e secs=$S3 iterations=$it $WB"
  echo "h_${e}_it$it $e secs=$S2 iterations=$it $HB"; done; done; }
mkdir -p $OUT/runs $OUT/stats; date -u +%FT%TZ > $OUT/started.txt
for g in stock off p1 p2; do
  ( v=$E/on; [ $g = stock ] && v=$E/stock; . "$v/bin/activate"; unset NEWTON_VBD_PROXY_COUPLING
    [ $g = p1 ] && export NEWTON_VBD_PROXY_COUPLING=1; [ $g = p2 ] && export NEWTON_VBD_PROXY_COUPLING=2
    plays | awk -v g=$g '$2 == g { $2 = ""; print }' | xargs -P $P -L 1 bash -c 'python tools/nwt_cloth_proxy.py '"$OUT"'/runs/$0.txt "$@" box='"$OUT"'/runs/$0.box.txt cloth='"$OUT"'/runs/$0.cloth.txt > '"$OUT"'/stats/$0.txt 2> '"$OUT"'/runs/err_$0.txt' ) &
done
wait; date -u +%FT%TZ > $OUT/finished.txt
grep -rlIF "$HOME" $OUT 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
pick() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
M=$OUT/measured.txt; : > $M
# per play: the box's and the cloth's REST lines (the mean feedback on the box, and the mean force the cloth receives,
# up, over the second half), then the box's STOP line (its largest speed over the last third) or, for the throw, the
# pair's PAIRG line
for n in $(plays | awk '{ print $1 }'); do st=$(pick nan_at_step < $OUT/stats/$n.txt)
  r=$OUT/runs/$n; l="$n stops ${st:--1} box $("$B" rest $r.box.txt < /dev/null | tail -1) cloth $("$B" rest $r.cloth.txt < /dev/null | tail -1)"
  case $n in w_*) l="$l $("$B" pairg $r.box.txt $r.cloth.txt < /dev/null | tail -1)";; *) l="$l $("$B" stop $r.box.txt < /dev/null | tail -1)";; esac
  echo "$l" >> $M; done
[ "${DRY:-0}" = 1 ] && { echo "dry run: $(wc -l < $M | tr -d ' ') measured lines"; cat $M; exit 0; }
v() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $M; }
bf() { awk -v n="$1" '$1 == n { for (i = 2; i < NF; i++) if ($i == "mean_ground_force_mN") { print $(i + 1); exit } }' $M; }
cf() { awk -v n="$1" '$1 == n { k = 0; for (i = 2; i < NF; i++) if ($i == "mean_ground_force_mN") { k++; if (k == 2) { print $(i + 1); exit } } }' $M; }
mass() { head -1 "$1" | awk '{ for (i = 1; i < NF; i++) if ($i == "mass_g") { print $(i + 1); exit } }'; }
mom() { local n=$1 r=$OUT/runs/$1; echo $(( ( $(mass $r.box.txt) * $(v $n final_speed_a_ums) + $(mass $r.cloth.txt) * $(v $n final_speed_b_ums) ) / 10 )); }
R=$OUT/rules.txt; : > $R
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $R; }
same=0; tot=0; for n in $(plays | awk '$2 == "stock" { print $1 }'); do tot=$((tot + 1)); cmp -s $OUT/runs/$n.txt $OUT/runs/${n/_stock_/_off_}.txt && same=$((same + 1)); done
rule R1_safe_when_off eq $same $tot
for it in 15 50; do b=$(bf t_fb0_stock_it$it); c=$(cf t_fb0_stock_it$it); rule R2_released_feedback_too_large_it$it ge ${b#-} $(( 10 * ${c#-} ))
  p0=$(v w_stock_it$it momentum_at_release); pe=$(mom w_stock_it$it); rule R2_released_momentum_grows_it$it ge ${pe#-} $(( 2 * ${p0#-} )); done
for it in 15 50; do rule R3_feedback_the_cloths_it$it within $(( 0 - $(bf t_fb0_p2_it$it) )) $(cf t_fb0_p2_it$it) 20; done
rule R4_box_at_rest all_le 10 $(for s in r t; do for it in 15 50; do v ${s}_fb1_p2_it$it largest_speed_last_third_ums; done; done)
for it in 15 50; do rule R5_momentum_kept_it$it within $(mom w_p2_it$it) $(v w_p2_it$it momentum_at_release) 50; done
rule R6_held_cloth_no_faster_than_landing all_le 767000 $(for it in 15 50; do v h_p2_it$it largest_speed_last_third_ums; done)
for it in 15 50; do rule R6_held_cloth_carries_the_box_it$it within $(bf h_p2_it$it) 3983 10; done
rule R7_numbers all_eq -1 $(plays | awk '{ print $1 }' | while read -r n; do v $n stops; done)
echo "rules: $(wc -l < $R | tr -d ' '), held: $(grep -c ': HELD$' $R)" >> $R
cat $R
