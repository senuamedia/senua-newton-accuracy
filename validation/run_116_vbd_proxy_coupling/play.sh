#!/usr/bin/env bash
# Run 116: Senua AI's VBD proxy coupling patch in design (patches/in_design/vbd_proxy_coupling_on_1.7.0.diff; switch
# NEWTON_VBD_PROXY_COUPLING=1: a proxy body rewound by its gravity only, #4698's (B); =2: that and the realized harvest,
# #4698's (A)) on the coupled cloth of tools/nwt_cloth_proxy.py: #4698's scene, the same on a box tall enough that the
# cloth touches nothing else, a box dropped onto a hammock, and a cloth thrown at a free box without gravity, at 10 and
# 40 VBD iterations, on Newton 1.7.0. The README's predictions were pushed before these plays. Then measured.txt and
# checks.txt.
# usage: play.sh <sx_contact binary> <engine folder> [parallel plays a setting]   (repository root; the engine folder
#   made by this run's setup_engine.sh)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary> <engine folder>}")" && pwd)/$(basename "$1")"; E="$(cd "${2:?}" && pwd)"; P=${3:-3}
O=validation/run_116_vbd_proxy_coupling
plays() { local e it; for e in stock off p1 p2; do for it in 10 40; do
  echo "rest_fb0_${e}_it$it $e secs=0.6 feedback=0 iterations=$it"
  echo "rest_fb1_${e}_it$it $e secs=0.6 feedback=1 iterations=$it"
  echo "tall_fb0_${e}_it$it $e secs=0.6 feedback=0 iterations=$it box_hz=0.08"
  echo "tall_fb1_${e}_it$it $e secs=0.6 feedback=1 iterations=$it box_hz=0.08"
  echo "hammock_${e}_it$it $e secs=0.6 iterations=$it scene=hammock box_hx=0.05 box_mass=0.2"
  echo "throw_${e}_it$it $e secs=0.3 iterations=$it scene=throw cloth_vz=-1"; done; done; }
mkdir -p $O/runs $O/stats; date -u +%FT%TZ > $O/started.txt
for g in stock off p1 p2; do
  ( v=$E/on; [ $g = stock ] && v=$E/stock; . "$v/bin/activate"; unset NEWTON_VBD_PROXY_COUPLING
    [ $g = p1 ] && export NEWTON_VBD_PROXY_COUPLING=1; [ $g = p2 ] && export NEWTON_VBD_PROXY_COUPLING=2
    plays | awk -v g=$g '$2 == g { $2 = ""; print }' | xargs -P $P -L 1 bash -c 'python tools/nwt_cloth_proxy.py '"$O"'/runs/$0.txt "$@" box='"$O"'/runs/$0.box.txt cloth='"$O"'/runs/$0.cloth.txt > '"$O"'/stats/$0.txt 2> '"$O"'/runs/err_$0.txt' ) &
done
wait; date -u +%FT%TZ > $O/finished.txt
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
pick() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
M=$O/measured.txt; : > $M
for n in $(plays | awk '{ print $1 }'); do st=$(pick nan_at_step < $O/stats/$n.txt)
  r=$O/runs/$n; l="$n stops ${st:--1} box $("$B" rest $r.box.txt < /dev/null | tail -1) cloth $("$B" rest $r.cloth.txt < /dev/null | tail -1)"
  case $n in throw_*) l="$l $("$B" pairg $r.box.txt $r.cloth.txt < /dev/null | tail -1)";; *) l="$l $("$B" fastest $r.box.txt 50 < /dev/null | tail -1)";; esac
  echo "$l" >> $M; done
v() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $M; }
# the harvested force on the box, up, and the force the cloth receives, up: each the first, and the second, field of
# that name on the play's line (the box's file read first)
bf() { awk -v n="$1" '$1 == n { for (i = 2; i < NF; i++) if ($i == "mean_ground_force_mN") { print $(i + 1); exit } }' $M; }
cf() { awk -v n="$1" '$1 == n { k = 0; for (i = 2; i < NF; i++) if ($i == "mean_ground_force_mN") { k++; if (k == 2) { print $(i + 1); exit } } }' $M; }
C=$O/checks.txt; : > $C
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $C; }
rule C0_numbers all_eq -1 $(plays | awk '{ print $1 }' | while read -r n; do v $n stops; done)
same=0; tot=0; for n in $(plays | awk '$2 == "stock" { print $1 }'); do tot=$((tot + 1)); cmp -s $O/runs/$n.txt $O/runs/${n/_stock_/_off_}.txt && same=$((same + 1)); done
rule P1_safe_when_off eq $same $tot
rule C0_as_run_112 eq 4 $(k=0; for fb in 0 1; do for it in 10 40; do cmp -s $O/runs/rest_fb${fb}_stock_it$it.txt validation/run_112_cloth_proxy/runs/cloth_fb${fb}_it$it.txt && k=$((k + 1)); done; done; echo $k)
for it in 10 40; do b=$(bf tall_fb0_stock_it$it); c=$(cf tall_fb0_stock_it$it)
  rule P2_released_tall_harvest_too_large_it$it ge ${b#-} $(( 10 * ${c#-} ))
  rule P2_realized_tall_harvest_the_cloths_it$it within $(( 0 - $(bf tall_fb0_p2_it$it) )) $(cf tall_fb0_p2_it$it) 20; done
rule P3_realized_rest_box_still all_le 1000 $(for it in 10 40; do v rest_fb1_p2_it$it fastest_ums; done)
rule P4_released_hammock_box_thrown all_ge 100000 $(for it in 10 40; do v hammock_stock_it$it fastest_ums; done)
rule P4_realized_hammock_box_held all_le 10000 $(for it in 10 40; do v hammock_p2_it$it fastest_ums; done)
for it in 10 40; do rule P4_realized_hammock_carries_the_box_it$it within $(bf hammock_p2_it$it) 1960 10; done
for e in stock p2; do for it in 10 40; do n=throw_${e}_it$it; p0=$(v $n momentum_at_release)
  pe=$(( 500 * $(v $n final_speed_a_ums) / 10 + 45 * $(v $n final_speed_b_ums) / 10 ))
  [ $e = stock ] && rule P5_released_throw_momentum_grows_it$it ge ${pe#-} $(( 3 * ${p0#-} / 2 ))
  [ $e = p2 ] && rule P5_realized_throw_momentum_kept_it$it within $pe $p0 20; done; done
echo "checks: $(wc -l < $C | tr -d ' '), held: $(grep -c ': HELD$' $C)" >> $C
cat $C
