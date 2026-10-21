#!/usr/bin/env bash
# Run 120: issue 21's implicit MPM colliders (newton-physics/newton #4712) on Newton 1.7.0 as released, a design probe
# whose predictions were pushed before the plays: #4712's slab on a 60 degree slope with friction 3 at collider margins
# 0, 12.5, 25 and 50 mm (the voxel 50 mm), at 8 substeps and, at 0 and 50 mm, at 32; #4712's cup of liquid, its walls
# 4 mm thick, at margins 0, 2.5, 3, 5 and 10 mm (the voxel 10 mm); 1 s each (tools/nwt_mpm_collider.py). Then
# measured.txt and checks.txt.
# usage: play.sh <sx_contact binary> [parallel plays]   (repository root; STOCK_VENV Newton 1.7.0)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"; P=${2:-4}
O=validation/run_120_mpm_collider
plays() { local m; for m in 0 0.0125 0.025 0.05; do echo "slope_m$m scene=slope margin=$m"; done
  for m in 0 0.05; do echo "slope_m${m}_sub32 scene=slope margin=$m substeps=32"; done
  for m in 0 0.0025 0.003 0.005 0.01; do echo "cup_m$m scene=cup margin=$m"; done; }
mkdir -p $O/runs $O/stats; date -u +%FT%TZ > $O/started.txt
( . "$STOCK_VENV/bin/activate"; plays | xargs -P $P -L 1 bash -c 'python tools/nwt_mpm_collider.py '"$O"'/runs/$0.txt "$@" > '"$O"'/stats/$0.txt 2> '"$O"'/runs/err_$0.txt' )
date -u +%FT%TZ > $O/finished.txt
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
pick() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
M=$O/measured.txt; : > $M
for n in $(plays | awk '{ print $1 }'); do st=$(pick nan_at_step < $O/stats/$n.txt)
  case $n in slope*) m=stop;; *) m=final;; esac
  echo "$n stops ${st:--1} $("$B" $m $O/runs/$n.txt < /dev/null | tail -1)" >> $M; done
v() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $M; }
C=$O/checks.txt; : > $C
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $C; }
rule C0_numbers all_eq -1 $(plays | awk '{ print $1 }' | while read -r n; do v $n stops; done)
rule P1_slab_slides_at_no_margin ge $(v slope_m0 slid_um) 500000
rule P2_slab_slides_at_every_margin all_ge 10000 $(for n in slope_m0 slope_m0.0125 slope_m0.025 slope_m0.05 slope_m0_sub32 slope_m0.05_sub32; do v $n slid_um; done)
# the cup's count of particles outside its walls at the end is the first column of its last line, `final`'s angle_urad
rule P3_cup_leaks_at_no_margin ge $(v cup_m0 angle_urad) 100
rule P4_cup_holds_at_half_a_voxel eq $(v cup_m0.005 angle_urad) 0
echo "checks: $(wc -l < $C | tr -d ' '), held: $(grep -c ': HELD$' $C)" >> $C
cat $C $M
