#!/usr/bin/env bash
# Run 124: #4712's slab on a 60 degree slope with friction 3 (issue 21) on SolverImplicitMPM as released, at a collider
# margin of half a voxel (25 mm), at 8 and 32 substeps, with six of its own options whose values are words or that run
# 122 did not play: the collider basis Q1, GIMP integration, PIC transfers, the collider velocity read backward, no air
# drag, no warm start; and at the defaults at 16 substeps. A design probe whose predictions were pushed before the plays
# (run 122: neither the solve's tolerance nor its iterations moves the slide). Then measured.txt and checks.txt.
# usage: play.sh <sx_contact binary> [parallel plays]   (repository root; STOCK_VENV Newton 1.7.0)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"; P=${2:-4}
O=validation/run_124_mpm_slope_options_words
cfg() { case $1 in default) echo "";; q1) echo " opt.collider_basis=Q1";; gimp) echo " opt.integration_scheme=gimp";;
  pic) echo " opt.transfer_scheme=pic";; back) echo " opt.collider_velocity_mode=backward";; nodrag) echo " opt.air_drag=0";;
  nowarm) echo " opt.warmstart_mode=none";; esac; }
plays() { local c sub; echo "slope_default_sub16 scene=slope margin=0.025 substeps=16"; for c in q1 gimp pic back nodrag nowarm; do for sub in 8 32; do
  echo "slope_${c}_sub$sub scene=slope margin=0.025 substeps=$sub$(cfg $c)"; done; done; }
mkdir -p $O/runs $O/stats; date -u +%FT%TZ > $O/started.txt
( . "$STOCK_VENV/bin/activate"; plays | xargs -P $P -L 1 bash -c 'python tools/nwt_mpm_collider.py '"$O"'/runs/$0.txt "$@" > '"$O"'/stats/$0.txt 2> '"$O"'/runs/err_$0.txt' )
date -u +%FT%TZ > $O/finished.txt
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
pick() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
M=$O/measured.txt; : > $M
for n in $(plays | awk '{ print $1 }'); do st=$(pick nan_at_step < $O/stats/$n.txt)
  echo "$n stops ${st:--1} $("$B" stop $O/runs/$n.txt < /dev/null | tail -1)" >> $M; done
v() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $M; }
C=$O/checks.txt; : > $C
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $C; }
rule C0_numbers all_eq -1 $(plays | awk '{ print $1 }' | while read -r n; do v $n stops; done)
rule P1_default_slides_at_16_substeps ge $(v slope_default_sub16 slid_um) 10000
for c in q1 gimp pic back nodrag nowarm; do rule P2_${c}_holds_at_both all_le 10000 $(v slope_${c}_sub8 slid_um) $(v slope_${c}_sub32 slid_um); done
echo "checks: $(wc -l < $C | tr -d ' '), held: $(grep -c ': HELD$' $C)" >> $C
cat $C $M
