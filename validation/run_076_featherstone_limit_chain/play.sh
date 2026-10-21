#!/usr/bin/env bash
# Run 076: Featherstone's joint limit on a serial arm (issue 28), a design probe that decides nothing and states no
# prediction: a chain of two light links (0.05 kg each, half-size 0.01 m) under gravity, its first joint released
# level onto its lower limit at -0.5 rad (upper 0.5), the second free, 0.3 s, on Featherstone as released and with the
# limit patch's forms =1, =2 and =3 (patches/in_design/featherstone_limit_v2_on_1.7.0.diff), at 1/240 s, 1 ms, 250 us,
# 50 us and 20 us, on Newton 1.7.0; then measured.txt (sx_contact final and chain, each play's statistics line).
# usage: play.sh <sx_contact binary>   (repository root; STOCK_VENV Newton 1.7.0, LIMIT_VENV the patch's tree first)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"
O=validation/run_076_featherstone_limit_chain
ARM="mass1=0.05 mass2=0.05 radius=0.01 arm1=0.02 len1=0.04 arm2=0.02 angle1=0 angle2=0 gravity=1 secs=0.3 lo1=-0.5 hi1=0.5 solver=featherstone"
plays() { local e dt; for e in stock 1 2 3; do for dt in 0.0041666667 0.001 0.00025 0.00005 0.00002; do echo "chain_${e}_$dt $e dt=$dt $ARM"; done; done; }
mkdir -p $O/runs $O/stats; date -u +%FT%TZ > $O/started.txt
for g in stock 1 2 3; do
  ( v=$LIMIT_VENV; [ $g = stock ] && v=$STOCK_VENV; . "$v/bin/activate"; unset NEWTON_FEATHERSTONE_LIMIT; [ $g != stock ] && export NEWTON_FEATHERSTONE_LIMIT=$g
    plays | awk -v g=$g '$2 == g { $2 = ""; print }' | while read -r n rest; do python tools/nwt_chain.py $O/runs/$n.txt $rest > $O/stats/$n.txt 2>> $O/runs/log_$g.txt; done ) &
done
wait; date -u +%FT%TZ > $O/finished.txt
pick_s() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
M=$O/measured.txt; : > $M
for n in $(plays | awk '{print $1}'); do st=$(pick_s nan_at_step < $O/stats/$n.txt); [ -n "$st" ] || st=$(pick_s out_of_range_at_step < $O/stats/$n.txt)
  echo "$n stops ${st:--1} $(tail -1 $O/runs/$n.txt | awk '{print "last_line", $1, $2, $3, $4, $5}')" >> $M; done
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
cat $M
