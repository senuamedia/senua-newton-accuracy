#!/usr/bin/env bash
# Run 112: issue 21's coupled cloth (#4698) on Newton 1.7.0 as released, a design probe whose predictions were pushed
# before the plays: a 0.5 kg box on the MuJoCo solver's CPU path, a 45 g VBD cloth dropped onto it, coupled two-way
# through SolverCoupledProxy with the box a lagged proxy in VBD (tools/nwt_cloth_proxy.py), one-way (the harvested
# wrench recorded, then zeroed) and two-way, at 10, 40 and 100 VBD iterations, 0.6 s. Then measured.txt and checks.txt.
# usage: play.sh <sx_contact binary>   (repository root; STOCK_VENV Newton 1.7.0)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"
O=validation/run_112_cloth_proxy
plays() { local fb it; for fb in 0 1; do for it in 10 40 100; do echo "cloth_fb${fb}_it$it secs=0.6 feedback=$fb iterations=$it"; done; done; }
mkdir -p $O/runs $O/stats; date -u +%FT%TZ > $O/started.txt
( . "$STOCK_VENV/bin/activate"; plays | xargs -P 6 -L 1 bash -c 'python tools/nwt_cloth_proxy.py '"$O"'/runs/$0.txt "$@" > '"$O"'/stats/$0.txt 2> '"$O"'/runs/log_$0.txt' )
date -u +%FT%TZ > $O/finished.txt
# a play's readings, read from its file: over the last third of the coupled steps, the mean harvested wrench and the mean
# force the cloth receives (mN, z), and the box's largest speed over the play (um/s)
M=$O/measured.txt; : > $M
for n in $(plays | awk '{print $1}'); do
  awk -v n=$n 'NR == 1 { for (i = 2; i < NF; i++) if ($i == "steps") s = $(i + 1); next }
    { if ($5 > top) top = $5; if ($1 >= s - int(s / 3)) { w += $2; c += $3; k++ } }
    END { printf "%s harvested_mN %d cloth_mN %d box_top_speed_ums %d\n", n, (k ? w / k : 0), (k ? c / k : 0), top }' $O/runs/$n.txt >> $M; done
v() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $M; }
C=$O/checks.txt; : > $C
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $C; }
# the cloth's weight, 45 g at 9.81 m/s^2: 441 mN
rule P1_cloth_receives_its_weight all_within 441 20 $(for it in 10 40 100; do v cloth_fb0_it$it cloth_mN; done)
rule P2_harvest_ten_times_too_large le 4410 $(h=$(v cloth_fb0_it10 harvested_mN); echo ${h#-})
rule P3_harvest_falls_with_iterations all_ge 0 $(a=$(v cloth_fb0_it10 harvested_mN); b=$(v cloth_fb0_it40 harvested_mN); c=$(v cloth_fb0_it100 harvested_mN); echo $(( ${a#-} - ${b#-} )) $(( ${b#-} - ${c#-} )))
echo "checks: $(wc -l < $C | tr -d ' '), held: $(grep -c ': HELD$' $C)" >> $C
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
cat $C $M
