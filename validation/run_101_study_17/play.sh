#!/usr/bin/env bash
# Run 101: the seventeenth registered study (preregistrations/PREREGISTRATION_17.md), played once on Newton 1.7.0: VBD
# holds a load at rest with its contacts carried from step to step (issue 6's VBD part), by Newton's own
# rigid_contact_history with the collision pipeline's sticky contact matching. Each play into runs/ and stats/, then the
# registered rules judged by sx_contact rule (rules.txt), the measured lines beside them (measured.txt). DRY=1 plays one
# throwaway play of each scene, path and setting, into dry/, to check that the runner runs to the end.
# usage: play.sh <sx_contact binary> [parallel plays]   (repository root; STOCK_VENV Newton 1.7.0)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"; P=${2:-4}
O=validation/run_101_study_17
CUBE="mass=1.4 radius=0.045 h0=0 mu=0.45"
if [ "${DRY:-0}" = 1 ]; then OUT=$O/dry; ST="0.004"; HS=0.4; SS=0.2; else OUT=$O; ST="0.0015 0.0003 0.00008"; HS=1.5; SS=0.5; fi
plays() { local p c dt o; for p in vbd vbd_alm; do for c in cold carried; do for dt in $ST; do
  o=""; [ $c = carried ] && o=" opt.rigid_contact_history=true matching=sticky"
  echo "h_${p}_${c}_$dt dt=$dt $CUBE push=4.0131 pushat=0.3 secs=$HS solver=$p$o"
  echo "s_${p}_${c}_$dt dt=$dt $CUBE vx0=0.9 secs=$SS solver=$p$o"; done; done; done; }
mkdir -p $OUT/runs $OUT/stats; date -u +%FT%TZ > $OUT/started.txt
( . "$STOCK_VENV/bin/activate"; plays | xargs -P $P -L 1 bash -c 'python tools/nwt_contact.py '"$OUT"'/runs/$0.txt "$@" > '"$OUT"'/stats/$0.txt 2> '"$OUT"'/runs/log_$0.txt' )
date -u +%FT%TZ > $OUT/finished.txt
pick_s() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
MS=$OUT/measured.txt; : > $MS
for n in $(plays | awk '{print $1}'); do st=$(pick_s nan_at_step < $OUT/stats/$n.txt); [ -n "$st" ] || st=$(pick_s out_of_range_at_step < $OUT/stats/$n.txt)
  case $n in h_*) r=creep;; s_*) r=stop;; esac
  echo "$n stops ${st:--1} $("$B" $r $OUT/runs/$n.txt < /dev/null | tail -1) most_tilt_urad $(pick_s most_tilt_urad < $OUT/stats/$n.txt)" >> $MS; done
[ "${DRY:-0}" = 1 ] && { echo "dry run: $(wc -l < $MS | tr -d ' ') measured lines"; cat $MS; exit 0; }
v() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $MS; }
abs() { for x in "$@"; do echo "${x#-}"; done; }
R=$OUT/rules.txt; : > $R
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $R; }
rule R1_fault_there_vbd all_ge 1000 $(abs $(for dt in $ST; do v h_vbd_cold_$dt mean_speed_ums; done))
rule R1_fault_there_vbd_alm ge $(abs $(v h_vbd_alm_cold_0.00008 mean_speed_ums)) 10
for p in vbd vbd_alm; do rule R2_held_$p all_in -10 10 $(for dt in $ST; do v h_${p}_carried_$dt mean_speed_ums; done)
  for dt in $ST; do rule R3_slide_kept_${p}_$dt within $(v s_${p}_carried_$dt slid_um) $(v s_${p}_cold_$dt slid_um) 100; done; done
rule R4_numbers all_eq -1 $(plays | awk '{ print $1 }' | while read -r n; do v $n stops; done)
grep -rlIF "$HOME" $OUT 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
echo "rules: $(wc -l < $R | tr -d ' '), held: $(grep -c ': HELD$' $R)" >> $R
cat $R
