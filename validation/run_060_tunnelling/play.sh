#!/usr/bin/env bash
# Run 060: issue 20's tunnelling (N12) put to one cube dropped fast onto a thin static slab (tools/nwt_contact.py
# slab=), Newton 1.7.0, XPBD and Featherstone on Newton's collision pipeline, its speculative contacts off (Newton's
# default) and on (specgap=1: CollisionPipeline(speculative_contact_gap_max=1)); C0, run 008's XPBD and SemiImplicit
# slides byte for byte the record's with the rig's change. The README's predictions were pushed before these plays.
# Then reading.txt (the last step's height and speed, picked from each play's file and STATS line) and checks.txt.
# usage: play.sh <sx_contact binary>   (repository root; STOCK_VENV set: Newton 1.7.0 as released)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"
O=validation/run_060_tunnelling
plays() {  # <name> <settings...>
  local s d v dt sp
  echo "c0_slide_xpbd dt=0.00025 h0=0 vx0=1.3 mass=0.8 radius=0.045 mu=0.45 secs=1.2 solver=xpbd"
  echo "c0_slide_semi dt=0.00025 h0=0 vx0=1.3 mass=0.8 radius=0.045 mu=0.45 secs=1.2 solver=semi"
  for s in xpbd featherstone; do for d in 0.01 0.002; do for v in 20 60 150; do for dt in 0.001 0.004; do for sp in off on; do
    x=""; [ $sp = on ] && x="specgap=1"
    echo "drop_${s}_d${d}_v${v}_${dt}_spec$sp solver=$s dt=$dt h0=0.05 vz0=-$v mu=0.5 mass=1 radius=0.05 secs=0.1 slab=$d $x"
  done; done; done; done; done
}
date -u +%FT%TZ > $O/started.txt
X=$(mktemp -d); cp -R tools $X/; plays > $X/list.txt
(cd $X && . "$STOCK_VENV/bin/activate" && mkdir -p runs stats &&
 while read -r n rest; do python tools/nwt_contact.py runs/$n.txt $rest > stats/$n.txt 2>> runs/log.txt; done < list.txt)
mkdir -p $O/runs $O/stats; cp $X/runs/* $O/runs/; cp $X/stats/* $O/stats/; rm -rf $X
date -u +%FT%TZ > $O/finished.txt
# ---- reading: the last step's height of the cube's lowest face (nm) and its speed along z (um/s), and the STATS
# line's nan field
R=$O/reading.txt; : > $R
for n in $(plays | awk '{print $1}' | grep '^drop'); do
  st=$(awk '{ for (i = 1; i < NF; i++) if ($i == "nan_at_step") { print $i, $(i + 1); exit } }' $O/stats/$n.txt)
  echo "$n $(tail -1 $O/runs/$n.txt | awk '{ print "last_height_nm", $2, "last_vz_ums", $4 }') ${st:-number_throughout}" >> $R
done
pick() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $R; }
# ---- checks: above the slab at the end (the lowest face above the slab's bottom: height > -slab), and the play a number
C=$O/checks.txt; : > $C
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $C; }
same=0; for s in xpbd semi; do cmp -s $O/runs/c0_slide_$s.txt validation/run_008_study_01/stock/runs/slide_$s.txt && same=$((same + 1)); done
rule C0_rig_unchanged eq $same 2
for n in $(plays | awk '{print $1}' | grep '^drop'); do
  d=$(echo $n | sed 's/.*_d\([0-9.]*\)_v.*/\1/'); dn=$(case $d in 0.01) echo 10000000;; 0.002) echo 2000000;; esac)
  rule A_${n}_above all_ge -$dn $(pick $n last_height_nm)
  rule N_${n}_number eq $(grep -c "^$n .*number_throughout$" $R) 1
done
echo "checks: $(wc -l < $C | tr -d ' '), held: $(grep -c ': HELD$' $C)" >> $C
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
cat $C
