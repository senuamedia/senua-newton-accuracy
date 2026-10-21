#!/usr/bin/env bash
# Run 102: the eighteenth registered study (preregistrations/PREREGISTRATION_18.md), played once on Newton 1.7.0:
# SemiImplicit's and Featherstone's friction as Coulomb's law at the step's end (issues 6 and 9). Each play into runs/
# and stats/, the suites into suites/, then the registered rules judged by sx_contact rule (rules.txt), the measured
# lines beside them (measured.txt). DRY=1 plays one throwaway play of each scene, solver and setting (no suite), into
# dry/, to check that the runner runs to the end.
# usage: play.sh <folder holding sx_contact and sx_contact_suite.sh> <engine folder>   (repository root)
set -u
M="$(cd "${1:?usage: play.sh <measure folder> <engine folder>}" && pwd)"; B=$M/sx_contact; E="$(cd "${2:?}" && pwd)"
O=validation/run_102_study_18
HCUBE="mass=0.6 radius=0.035 h0=0 mu=0.4"; NCUBE="mass=0.8 radius=0.04 h0=0 mu=0.6"
if [ "${DRY:-0}" = 1 ]; then OUT=$O/dry; HS="0.004"; NS="0.004"; HSEC=0.6; NSEC=0.7; SSEC=0.2
else OUT=$O; HS="0.0015 0.0004 0.0001"; NS="0.002 0.0016"; HSEC=1.6; NSEC=1.5; SSEC=0.6; fi
plays() { local s e dt; for s in semi featherstone; do for e in stock off on; do
  for dt in $HS; do echo "h_${s}_${e}_$dt $s $e dt=$dt $HCUBE push=1.6464 pushat=0.4 secs=$HSEC solver=$s"
    echo "s_${s}_${e}_$dt $s $e dt=$dt $HCUBE vx0=0.8 secs=$SSEC solver=$s"; done
  for dt in $NS; do echo "n_${s}_${e}_$dt $s $e dt=$dt $NCUBE push=2.352 pushat=0.5 secs=$NSEC solver=$s"; done; done; done; }
envof() { case $1 in stock) echo "$E/stock";; *) echo "$E/on";; esac; }
setsw() { unset NEWTON_CONTACT_DAMPING_NO_PULL NEWTON_SEMI_COULOMB_FRICTION NEWTON_SEMI_COULOMB_FRICTION_ITERATIONS NEWTON_FEATHERSTONE_COULOMB_FRICTION
  [ "$2" = on ] || return 0; export NEWTON_CONTACT_DAMPING_NO_PULL=1
  case $1 in semi) export NEWTON_SEMI_COULOMB_FRICTION=1 NEWTON_SEMI_COULOMB_FRICTION_ITERATIONS=64;; featherstone) export NEWTON_FEATHERSTONE_COULOMB_FRICTION=64;; esac; }
mkdir -p $OUT/runs $OUT/stats; date -u +%FT%TZ > $OUT/started.txt
group() { local s=$1 e=$2
  ( . "$(envof $e)/bin/activate"; setsw $s $e
    plays | awk -v s=$s -v e=$e '$2 == s && $3 == e { $2 = ""; $3 = ""; print }' | xargs -P 1 -L 1 bash -c 'python tools/nwt_contact.py '"$OUT"'/runs/$0.txt "$@" > '"$OUT"'/stats/$0.txt 2> '"$OUT"'/runs/log_$0.txt' ) ; }
suite() { local s=$1 e=$2 l=$1_$2
  ( . "$(envof $e)/bin/activate"; setsw $s $e; bash tools/contact_suite.sh study18_$l solver=$s > $OUT/runs/log_suite_$l.txt 2>&1 )
  mkdir -p $OUT/suites; rm -rf "${OUT:?}/suites/${l:?}"; mv suites/1/study18_$l $OUT/suites/$l
  bash "$M/sx_contact_suite.sh" $OUT/suites/$l $OUT/suites/$l/verdicts.txt > /dev/null 2>> $OUT/runs/log_suite_$l.txt; }
for s in semi featherstone; do for e in stock off on; do group $s $e & done; done
if [ "${DRY:-0}" != 1 ]; then for s in semi featherstone; do for e in stock on; do suite $s $e & done; done; fi
wait; date -u +%FT%TZ > $OUT/finished.txt
pick_s() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
MS=$OUT/measured.txt; : > $MS
for n in $(plays | awk '{print $1}'); do st=$(pick_s nan_at_step < $OUT/stats/$n.txt); [ -n "$st" ] || st=$(pick_s out_of_range_at_step < $OUT/stats/$n.txt)
  case $n in s_*) r=stop;; *) r=creep;; esac
  echo "$n stops ${st:--1} $("$B" $r $OUT/runs/$n.txt < /dev/null | tail -1) most_tilt_urad $(pick_s most_tilt_urad < $OUT/stats/$n.txt)" >> $MS; done
[ "${DRY:-0}" = 1 ] && { echo "dry run: $(wc -l < $MS | tr -d ' ') measured lines"; cat $MS; exit 0; }
v() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $MS; }
verdict() { grep "^$2 " $OUT/suites/$1/verdicts.txt | awk '{print $NF}'; }
# a suite line's readings: the numbers after its last "): ", up to " ;" or " :"
nums() { grep "^$2 " $OUT/suites/$1/verdicts.txt | awk '{ s = $0; while ((i = index(s, "): ")) > 0) s = substr(s, i + 3); sub(/ [;:].*$/, "", s); print s }'; }
R=$OUT/rules.txt; : > $R
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $R; }
s=0; t=0; for n in $(plays | awk '$3 == "stock" { print $1 }'); do t=$((t + 1)); cmp -s $OUT/runs/$n.txt $OUT/runs/${n/_stock_/_off_}.txt && s=$((s + 1)); done
rule R1_safe_when_off eq $s $t
for s in semi featherstone; do
  rule R2_fault_there_$s all_ge 100 $(for dt in $HS; do x=$(v h_${s}_stock_$dt mean_speed_ums); echo ${x#-}; done)
  rule R3_held_$s all_in -10 10 $(for dt in $HS; do v h_${s}_on_$dt mean_speed_ums; done)
  rule R4_issue9_held_$s all_in -10 10 $(for dt in $NS; do v n_${s}_on_$dt mean_speed_ums; done)
  rule R4_issue9_turned_$s all_le 10000 $(for dt in $NS; do v n_${s}_on_$dt most_tilt_urad; done)
  rule R5_coulomb_slide_$s all_within 81633 100 $(for dt in $HS; do v s_${s}_on_$dt slid_um; done)
  case $s in semi) from=2;; featherstone) from=3;; esac
  rule R6_T05_$s all_within 4000 100 $(nums ${s}_on T05 | cut -d' ' -f$from-)
  rule R6_T10_$s all_within 4000 100 $(nums ${s}_on T10 | cut -d' ' -f$from-)
  lost=0; for tt in T01 T02 T03 T04 T05 T06 T07 T08 T09 T10; do [ "$(verdict ${s}_stock $tt)" = PASS ] && [ "$(verdict ${s}_on $tt)" != PASS ] && lost=$((lost + 1)); done
  rule R7_nothing_lost_$s eq $lost 0
  rule R8_numbers_$s all_eq -1 $(plays | awk -v s=$s '$2 == s && $3 == "on" { print $1 }' | while read -r n; do v $n stops; done); done
grep -rlIF "$HOME" $OUT 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
echo "rules: $(wc -l < $R | tr -d ' '), held: $(grep -c ': HELD$' $R)" >> $R
cat $R; for l in semi_stock semi_on featherstone_stock featherstone_on; do echo "$l: $(grep '^SUITE' $OUT/suites/$l/verdicts.txt)"; done
