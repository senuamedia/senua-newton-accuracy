#!/usr/bin/env bash
# Run 115: VBD-ALM's slide and hold as the step shrinks, as released and with Senua AI's VBD displacement patch in design
# (patches/in_design/vbd_displacement_on_1.7.0.diff, NEWTON_VBD_DISPLACEMENT=1): Study 22's slide and a second, and
# Study 22's hold, at 1.5, 0.3, 0.075 and 0.0375 ms, on Newton 1.7.0. The README's predictions were pushed before
# these plays. Then measured.txt and checks.txt.
# usage: play.sh <sx_contact binary> <engine folder> [parallel plays a setting]   (repository root; the engine folder
#   made by run 114's setup_engine.sh: stock/ and on/)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary> <engine folder>}")" && pwd)/$(basename "$1")"; E="$(cd "${2:?}" && pwd)"; P=${3:-4}
O=validation/run_115_vbd_displacement_slide
SL1="mass=1.1 radius=0.045 h0=0 mu=0.45 vx0=0.8 secs=0.5 solver=vbd_alm"
SL2="mass=0.6 radius=0.03 h0=0 mu=0.3 vx0=1.2 secs=0.8 solver=vbd_alm"
HOLD="mass=1.4 radius=0.04 h0=0 mu=0.6 push=4.53 pushat=0.4 secs=1.6 solver=vbd_alm opt.rigid_contact_history=true matching=sticky"
DT="0.0015 0.0003 0.000075 0.0000375"
plays() { local e dt; for e in stock on; do for dt in $DT; do
  echo "l1_${e}_$dt $e dt=$dt $SL1"; echo "l2_${e}_$dt $e dt=$dt $SL2"; echo "h_${e}_$dt $e dt=$dt $HOLD"; done; done; }
mkdir -p $O/runs $O/stats; date -u +%FT%TZ > $O/started.txt
for g in stock on; do
  ( v=$E/on; [ $g = stock ] && v=$E/stock; . "$v/bin/activate"; unset NEWTON_VBD_DISPLACEMENT; [ $g = on ] && export NEWTON_VBD_DISPLACEMENT=1
    plays | awk -v g=$g '$2 == g { $2 = ""; print }' | xargs -P $P -L 1 bash -c 'python tools/nwt_contact.py '"$O"'/runs/$0.txt "$@" > '"$O"'/stats/$0.txt 2> '"$O"'/runs/err_$0.txt' ) &
done
wait; date -u +%FT%TZ > $O/finished.txt
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
pick() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
M=$O/measured.txt; : > $M
for n in $(plays | awk '{ print $1 }'); do st=$(pick nan_at_step < $O/stats/$n.txt); [ -n "$st" ] || st=$(pick out_of_range_at_step < $O/stats/$n.txt)
  case $n in h_*) m=creep;; *) m=stop;; esac
  echo "$n stops ${st:--1} $("$B" $m $O/runs/$n.txt < /dev/null | tail -1)" >> $M; done
v() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $M; }
C=$O/checks.txt; : > $C
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $C; }
rule C0_numbers all_eq -1 $(plays | awk '{ print $1 }' | while read -r n; do v $n stops; done)
rule C0_as_study_22 eq 4 $(k=0; for e in stock on; do for dt in 0.0015 0.000075; do cmp -s $O/runs/l1_${e}_$dt.txt validation/run_114_study_22/runs/l_${e}_$dt.txt && k=$((k + 1)); done; done; echo $k)
for l in l1 l2; do
  rule P1_${l}_released_moves all_ge 0 $(a=$(v ${l}_stock_0.0003 slid_um); b=$(v ${l}_stock_0.0000375 slid_um); echo $(( ${b#-} - ${a#-} - ${a#-} / 100 )))
  rule P2_${l}_patch_settles all_within $(v ${l}_on_0.0000375 slid_um) 200 $(v ${l}_on_0.0003 slid_um) $(v ${l}_on_0.000075 slid_um); done
echo "checks: $(wc -l < $C | tr -d ' '), held: $(grep -c ': HELD$' $C)" >> $C
cat $C
