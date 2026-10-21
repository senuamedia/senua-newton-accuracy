#!/usr/bin/env bash
# Run 127: Senua AI's friction combination patch in design (patches/in_design/friction_combine_on_1.7.0.diff;
# NEWTON_FRICTION_COMBINE=1: MuJoCo's rule for two shapes' frictions on Newton's own solvers, the larger, or the
# higher-priority shape's when MuJoCo's geom priority is registered and differs), on run 059's slide (a 1 kg cube of
# half-size 0.05 m sent at 1 m/s, the cube's friction 0.2 and the plane's 0.9, 0.5 ms, 0.6 s) on XPBD, SemiImplicit,
# Featherstone, VBD and the MuJoCo solver (issue 18). A design probe whose predictions were pushed before the plays.
# Then measured.txt and checks.txt.
# usage: play.sh <sx_contact binary> <engine folder> [parallel plays a setting]   (repository root; the engine folder
#   made by this run's setup_engine.sh)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary> <engine folder>}")" && pwd)/$(basename "$1")"; E="$(cd "${2:?}" && pwd)"; P=${3:-4}
O=validation/run_127_friction_combine
A="mass=1 radius=0.05 h0=0 vx0=1 secs=0.6 dt=0.0005"
MIX="mu=0.2 groundmu=0.9"
plays() { local s e; for s in xpbd semi featherstone vbd mujoco; do
  echo "${s}_one02 stock $A mu=0.2 solver=$s"; echo "${s}_one09 stock $A mu=0.9 solver=$s"
  for e in stock off on; do
    echo "${s}_mix_$e $e $A $MIX solver=$s"
    echo "${s}_mixeq_$e $e $A $MIX register=1 prio=0 groundprio=0 solver=$s"
    echo "${s}_mixcube_$e $e $A $MIX register=1 prio=1 groundprio=0 solver=$s"
    echo "${s}_mixplane_$e $e $A $MIX register=1 prio=0 groundprio=1 solver=$s"; done; done; }
mkdir -p $O/runs $O/stats; date -u +%FT%TZ > $O/started.txt
for g in stock off on; do
  ( v=$E/on; [ $g = stock ] && v=$E/stock; . "$v/bin/activate"; unset NEWTON_FRICTION_COMBINE; [ $g = on ] && export NEWTON_FRICTION_COMBINE=1
    plays | awk -v g=$g '$2 == g { $2 = ""; print }' | xargs -P $P -L 1 bash -c 'python tools/nwt_contact.py '"$O"'/runs/$0.txt "$@" > '"$O"'/stats/$0.txt 2> '"$O"'/runs/err_$0.txt' ) &
done
wait; date -u +%FT%TZ > $O/finished.txt
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
pick() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
M=$O/measured.txt; : > $M
for n in $(plays | awk '{ print $1 }'); do st=$(pick nan_at_step < $O/stats/$n.txt)
  echo "$n stops ${st:--1} $("$B" stop $O/runs/$n.txt < /dev/null | tail -1)" >> $M; done
v() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $M; }
d() { v $1 slid_um; }
C=$O/checks.txt; : > $C
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $C; }
rule C0_numbers all_eq -1 $(plays | awk '{ print $1 }' | while read -r n; do v $n stops; done)
same=0; tot=0; for n in $(plays | awk '$2 == "stock" && $1 ~ /_stock$/ { print $1 }'); do tot=$((tot + 1)); cmp -s $O/runs/$n.txt $O/runs/${n%_stock}_off.txt && same=$((same + 1)); done
rule P1_safe_when_off eq $same $tot
rule P2_released_xpbd_not_mujocos_rule ge $(( $(d xpbd_mix_stock) - $(d xpbd_one09) )) $(( $(d xpbd_one09) / 10 ))
for s in xpbd semi featherstone vbd mujoco; do
  rule P3_${s}_mujocos_rule all_within $(d ${s}_one09) 100 $(d ${s}_mix_on) $(d ${s}_mixeq_on) $(d ${s}_mixplane_on)
  rule P3_${s}_priority within $(d ${s}_mixcube_on) $(d ${s}_one02) 100; done
echo "checks: $(wc -l < $C | tr -d ' '), held: $(grep -c ': HELD$' $C)" >> $C
cat $C $M
