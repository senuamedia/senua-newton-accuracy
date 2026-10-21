#!/usr/bin/env bash
# Run 125: Study 22's free chain at the world's origin and 10 m along x on XPBD and SemiImplicit as released (with
# Newton's own joint_attach_kd=0 for SemiImplicit's chain, Study 9) and on Featherstone, at 0.375 and 0.09375 ms, on
# Newton 1.7.0: whether VBD's floor 10 m out at the smallest step (Study 22, run 121) is the 32-bit world positions'
# own, shared by the solvers whose state is the bodies' poses. A design probe whose predictions were pushed before the
# plays. Then measured.txt and checks.txt.
# usage: play.sh <sx_contact binary> [parallel plays]   (repository root; STOCK_VENV Newton 1.7.0)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"; P=${2:-4}
O=validation/run_125_far_chain_solvers
CHAIN="mass1=1.0 mass2=0.8 radius=0.04 arm1=0.22 len1=0.45 arm2=0.2 angle1=0 angle2=0.5 omega1=1.9 omega2=-0.9 gravity=0 secs=2"
sv() { case $1 in semi) echo "solver=semi opt.joint_attach_kd=0";; *) echo "solver=$1";; esac; }
plays() { local s x dt; for s in xpbd semi featherstone; do for x in 0 10; do for dt in 0.000375 0.00009375; do
  xs=""; [ $x = 0 ] || xs=" x0=$x"; echo "c_${s}_x${x}_$dt dt=$dt $CHAIN $(sv $s)$xs"; done; done; done; }
mkdir -p $O/runs $O/stats; date -u +%FT%TZ > $O/started.txt
( . "$STOCK_VENV/bin/activate"; plays | xargs -P $P -L 1 bash -c 'python tools/nwt_chain.py '"$O"'/runs/$0.txt "$@" > '"$O"'/stats/$0.txt 2> '"$O"'/runs/err_$0.txt' )
date -u +%FT%TZ > $O/finished.txt
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
pick() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
M=$O/measured.txt; : > $M
for n in $(plays | awk '{ print $1 }'); do st=$(pick nan_at_step < $O/stats/$n.txt); [ -n "$st" ] || st=$(pick out_of_range_at_step < $O/stats/$n.txt)
  l="$("$B" chain $O/runs/$n.txt < /dev/null | tail -1)"
  echo "$n stops ${st:--1} energy_largest_drift_ppm $(echo "$l" | pick energy_largest_drift_ppm)" >> $M; done
v() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $M; }
L() { v $1 energy_largest_drift_ppm; }
C=$O/checks.txt; : > $C
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $C; }
rule C0_numbers all_eq -1 $(plays | awk '{ print $1 }' | while read -r n; do v $n stops; done)
rule C0_featherstone_as_study_22 eq 4 $(k=0; for x in 0 10; do for dt in 0.000375 0.00009375; do cmp -s $O/runs/c_featherstone_x${x}_$dt.txt validation/run_114_study_22/runs/c_feather_x${x}_$dt.txt && k=$((k + 1)); done; done; echo $k)
for s in xpbd semi; do rule P1_${s}_10m_as_the_origin all_within $(L c_${s}_x0_0.00009375) 3 $(L c_${s}_x10_0.00009375); done
echo "checks: $(wc -l < $C | tr -d ' '), held: $(grep -c ': HELD$' $C)" >> $C
cat $C $M
