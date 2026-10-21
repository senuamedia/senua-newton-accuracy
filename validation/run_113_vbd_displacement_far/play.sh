#!/usr/bin/env bash
# Run 113: Senua AI's VBD displacement patch in design (patches/in_design/vbd_displacement_on_1.7.0.diff,
# NEWTON_VBD_DISPLACEMENT=1) on run 111's free chain moved 10 m and 100 m along the world's x (the chain rig's x0), on
# VBD as released and with the patch, and on Featherstone as released (a joint-space state, what 32-bit world positions
# cost a solver that does not keep its bodies' poses), at 2, 0.5 and 0.125 ms, on Newton 1.7.0. The README's
# predictions were pushed before these plays. Then measured.txt and checks.txt.
# usage: play.sh <sx_contact binary> [parallel plays]   (repository root; STOCK_VENV Newton 1.7.0, DISP_VENV the patch's
#   tree first on the path)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"; P=${2:-4}
O=validation/run_113_vbd_displacement_far
CHAIN="mass1=0.7 mass2=1.3 radius=0.04 arm1=0.25 len1=0.5 arm2=0.22 angle1=0 angle2=-0.4 omega1=2.2 omega2=-1.1 secs=2 gravity=0"
plays() { local e x dt; for e in stock on; do for x in 0 10 100; do for dt in 0.002 0.0005 0.000125; do
  xs="x0=$x"; [ $x = 0 ] && xs=""
  echo "chain_vbd_${e}_x${x}_$dt $e nwt_chain dt=$dt $CHAIN solver=vbd $xs"
  [ $e = stock ] && echo "chain_feather_x${x}_$dt stock nwt_chain dt=$dt $CHAIN solver=featherstone $xs"; done; done; done; }
mkdir -p $O/runs $O/stats; date -u +%FT%TZ > $O/started.txt
for g in stock on; do
  ( v=$DISP_VENV; [ $g = stock ] && v=$STOCK_VENV; . "$v/bin/activate"; unset NEWTON_VBD_DISPLACEMENT; [ $g = on ] && export NEWTON_VBD_DISPLACEMENT=1
    plays | awk -v g=$g '$2 == g { $2 = ""; print }' | xargs -P $P -L 1 bash -c 'python tools/$1.py '"$O"'/runs/$0.txt "${@:2}" > '"$O"'/stats/$0.txt 2> '"$O"'/runs/log_$0.txt' ) &
done
wait; date -u +%FT%TZ > $O/finished.txt
pick() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
M=$O/measured.txt; : > $M
for n in $(plays | awk '{print $1}'); do st=$(pick nan_at_step < $O/stats/$n.txt); [ -n "$st" ] || st=$(pick out_of_range_at_step < $O/stats/$n.txt)
  l="$("$B" chain $O/runs/$n.txt < /dev/null | tail -1)"
  echo "$n stops ${st:--1} energy_drift_ppm $(echo "$l" | pick energy_drift_ppm_of_most_kinetic) energy_largest_drift_ppm $(echo "$l" | pick energy_largest_drift_ppm)" >> $M; done
v() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $M; }
C=$O/checks.txt; : > $C
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $C; }
L=energy_largest_drift_ppm
rule C0_numbers all_eq -1 $(plays | awk '{ print $1 }' | while read -r n; do v $n stops; done)
rule C0_same_as_run_111 eq 3 $(k=0; for dt in 0.002 0.0005 0.000125; do cmp -s $O/runs/chain_vbd_on_x0_$dt.txt validation/run_111_vbd_displacement/runs/chain_vbd_on_$dt.txt && k=$((k + 1)); done; echo $k)
rule P1_released_far_worse ge $(v chain_vbd_stock_x100_0.0005 $L) $(( 5 * $(v chain_vbd_stock_x0_0.0005 $L) ))
rule P2_patch_far_alike all_ge 0 $(for dt in 0.002 0.0005 0.000125; do echo $(( 2 * $(v chain_vbd_on_x0_$dt $L) - $(v chain_vbd_on_x100_$dt $L) )); done)
echo "checks: $(wc -l < $C | tr -d ' '), held: $(grep -c ': HELD$' $C)" >> $C
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
cat $C $M
