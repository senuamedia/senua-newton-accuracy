#!/usr/bin/env bash
# Run 128: the twenty-sixth registered study (preregistrations/PREREGISTRATION_26.md), played once on Newton 1.7.0:
# two shapes' frictions combined by one rule on every solver (issue 18), by Senua AI's friction combination patch
# (NEWTON_FRICTION_COMBINE=1). Each play into runs/, its error stream into runs/err_<play>.txt and its statistics into
# stats/, then the registered rules judged by sx_contact rule (rules.txt), the measured lines beside them
# (measured.txt). DRY=1 plays one throwaway play of each scene and setting (0.04 s), into dry/, to check that the
# runner runs to the end.
# usage: play.sh <sx_contact binary> <engine folder> [parallel plays a setting]   (repository root)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary> <engine folder>}")" && pwd)/$(basename "$1")"; E="$(cd "${2:?}" && pwd)"; P=${3:-3}
O=validation/run_128_study_26
if [ "${DRY:-0}" = 1 ]; then OUT=$O/dry; SECS=0.04; else OUT=$O; SECS=0.7; fi
A="mass=0.7 radius=0.04 h0=0 vx0=0.8 secs=$SECS dt=0.001"
pairs="A:0.35:0.75 B:0.6:0.15"
prio() { case $1 in none) echo "";; eq) echo " register=1 prio=0 groundprio=0";; cube) echo " register=1 prio=1 groundprio=0";; plane) echo " register=1 prio=0 groundprio=1";; esac; }
plays() { local s e p q c g k; for s in xpbd semi featherstone vbd mujoco; do
  for k in 0.35 0.75 0.6 0.15; do echo "${s}_one$k stock $A mu=$k solver=$s"; done
  for q in $pairs; do p=${q%%:*}; c=$(echo $q | cut -d: -f2); g=$(echo $q | cut -d: -f3)
    for e in stock off on; do for r in none eq cube plane; do echo "${s}_${p}_${r}_$e $e $A mu=$c groundmu=$g$(prio $r) solver=$s"; done; done; done; done; }
mkdir -p $OUT/runs $OUT/stats; date -u +%FT%TZ > $OUT/started.txt
for g in stock off on; do
  ( v=$E/on; [ $g = stock ] && v=$E/stock; . "$v/bin/activate"; unset NEWTON_FRICTION_COMBINE; [ $g = on ] && export NEWTON_FRICTION_COMBINE=1
    plays | awk -v g=$g '$2 == g { $2 = ""; print }' | xargs -P $P -L 1 bash -c 'python tools/nwt_contact.py '"$OUT"'/runs/$0.txt "$@" > '"$OUT"'/stats/$0.txt 2> '"$OUT"'/runs/err_$0.txt' ) &
done
wait; date -u +%FT%TZ > $OUT/finished.txt
grep -rlIF "$HOME" $OUT 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
pick() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
M=$OUT/measured.txt; : > $M
for n in $(plays | awk '{ print $1 }'); do st=$(pick nan_at_step < $OUT/stats/$n.txt)
  echo "$n stops ${st:--1} $("$B" stop $OUT/runs/$n.txt < /dev/null | tail -1)" >> $M; done
[ "${DRY:-0}" = 1 ] && { echo "dry run: $(wc -l < $M | tr -d ' ') measured lines"; cat $M; exit 0; }
v() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $M; }
d() { v $1 slid_um; }
# the rule's coefficient for a pairing (cube, plane) and a priority: the cube's when its priority is higher, the plane's
# when the plane's is, else the larger
rc() { local c=$1 g=$2 r=$3; case $r in cube) echo $c;; plane) echo $g;; *) awk -v a=$c -v b=$g 'BEGIN { print (a > b) ? a : b }';; esac; }
R=$OUT/rules.txt; : > $R
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $R; }
same=0; tot=0; for n in $(plays | awk '$2 == "stock" && $1 ~ /_stock$/ { print $1 }'); do tot=$((tot + 1)); cmp -s $OUT/runs/$n.txt $OUT/runs/${n%_stock}_off.txt && same=$((same + 1)); done
rule R1_safe_when_off eq $same $tot
rule R2_fault_there all_ge 0 $(for s in xpbd vbd; do a=$(d ${s}_A_none_stock); b=$(d ${s}_one0.75); x=$(( a - b )); echo $(( ${x#-} - b / 10 )); done)
for s in xpbd semi featherstone vbd mujoco; do for q in $pairs; do p=${q%%:*}; c=$(echo $q | cut -d: -f2); g=$(echo $q | cut -d: -f3)
  for r in none eq cube plane; do rule R3_${s}_${p}_${r} within $(d ${s}_${p}_${r}_on) $(d ${s}_one$(rc $c $g $r)) 100; done; done; done
same=0; tot=0; for n in $(plays | awk '$1 ~ /^mujoco_/ && $1 ~ /_on$/ { print $1 }'); do tot=$((tot + 1)); cmp -s $OUT/runs/$n.txt $OUT/runs/${n%_on}_stock.txt && same=$((same + 1)); done
rule R4_mujoco_kept eq $same $tot
rule R5_numbers all_eq -1 $(plays | awk '{ print $1 }' | while read -r n; do v $n stops; done)
echo "rules: $(wc -l < $R | tr -d ' '), held: $(grep -c ': HELD$' $R)" >> $R
cat $R
