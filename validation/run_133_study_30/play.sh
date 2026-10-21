#!/usr/bin/env bash
# Run 133: the thirtieth registered study (preregistrations/PREREGISTRATION_30.md), played once on Newton 1.7.0: a
# static friction coefficient imported from USD and applied (issue 18), by pull request #4306 and Senua AI's static
# friction patch and its XPBD friction slip patch (NEWTON_STATIC_FRICTION=1, NEWTON_XPBD_FRICTION_SLIP=1). Each play into
# runs/, its error stream into runs/err_<play>.txt and its
# statistics into stats/, then the registered rules judged by sx_contact rule (rules.txt), the measured lines beside them
# (measured.txt). DRY=1 plays one throwaway play of each scene and setting (0.04 s), into dry/, to check that the runner
# runs to the end.
# usage: play.sh <sx_contact binary> <engine folder> [parallel plays a setting]   (repository root)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary> <engine folder>}")" && pwd)/$(basename "$1")"; E="$(cd "${2:?}" && pwd)"; P=${3:-2}
O=validation/run_133_study_30
if [ "${DRY:-0}" = 1 ]; then OUT=$O/dry; else OUT=$O; fi
sc() { [ "${DRY:-0}" = 1 ] && echo 0.04 || echo $1; }
F="mass=0.75 radius=0.045 h0=0 mu=0.35"; ST="mus=0.75 groundmus=0.75"
sv() { case $1 in xpbd) echo "solver=xpbd iterations=64";; *) echo "solver=$1";; esac; }
SOLVERS="xpbd semi featherstone mujoco vbd_alm vbd"; THREE="xpbd semi featherstone"; DTS="d1:0.001 d025:0.00025"
plays() { local s q d t e; for s in $SOLVERS; do for q in $DTS; do d=${q%%:*}; t=${q#*:}; for e in stock chain off on; do
  echo "${s}_hold_${d}_$e $e $F $ST dt=$t push=4.0425 pushat=0.3 secs=$(sc 1.2) $(sv $s)"
  echo "${s}_import_${d}_$e $e $F mus=0.75 usd=1 dt=$t push=3.3075 pushat=0.3 secs=$(sc 1.2) $(sv $s)"
  [ $e = stock ] && continue
  echo "${s}_kinetic_${d}_$e $e $F $ST dt=$t push=4.0425 pushat=0 vx0=0.3 secs=$(sc 1) $(sv $s)"
  echo "${s}_break_${d}_$e $e $F $ST dt=$t push=6.2475 pushat=0.3 secs=$(sc 1.2) $(sv $s)"
  echo "${s}_slide_${d}_$e $e $F $ST dt=$t vx0=0.9 secs=$(sc 0.6) $(sv $s)"; done; done; done; }
mkdir -p $OUT/runs $OUT/stats; date -u +%FT%TZ > $OUT/started.txt
for g in stock chain off on; do
  ( . "$E/$( [ $g = off ] && echo on || echo $g )/bin/activate"
    export NEWTON_XPBD_NO_SPEED_FLOOR=1 NEWTON_XPBD_FRICTION_TOTAL=1 NEWTON_UNIT_FRICTION_DIRECTION=1 NEWTON_CONTACT_DAMPING_NO_PULL=1
    export NEWTON_SEMI_COULOMB_FRICTION=1 NEWTON_SEMI_COULOMB_FRICTION_ITERATIONS=64 NEWTON_FEATHERSTONE_COULOMB_FRICTION=64
    unset NEWTON_STATIC_FRICTION NEWTON_XPBD_FRICTION_SLIP; [ $g = on ] && export NEWTON_STATIC_FRICTION=1 NEWTON_XPBD_FRICTION_SLIP=1
    plays | awk -v g=$g '$2 == g { $2 = ""; print }' | xargs -P $P -L 1 bash -c 'python tools/nwt_contact.py '"$OUT"'/runs/$0.txt "$@" > '"$OUT"'/stats/$0.txt 2> '"$OUT"'/runs/err_$0.txt' ) &
done
wait; date -u +%FT%TZ > $OUT/finished.txt
grep -rlIF "$HOME" $OUT 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
pick() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
M=$OUT/measured.txt; : > $M
for n in $(plays | awk '{ print $1 }'); do st=$(pick nan_at_step < $OUT/stats/$n.txt); im=$(pick shape_mu_static < $OUT/stats/$n.txt)
  case $n in *_hold_*|*_import_*) m=creep;; *_slide_*) m=stop;; *) m=final;; esac
  w=$(grep -c "does not apply a static friction coefficient" $OUT/runs/err_$n.txt)
  echo "$n stops ${st:--1} static_warnings $w imported_mu_static ${im:--} $("$B" $m $OUT/runs/$n.txt < /dev/null | tail -1)" >> $M; done
[ "${DRY:-0}" = 1 ] && { echo "dry run: $(wc -l < $M | tr -d ' ') measured lines"; cat $M; exit 0; }
v() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $M; }
each() { local k=$1 sc=$2 e=$3 s q; shift 3; for s in "$@"; do for q in $DTS; do v ${s}_${sc}_${q%%:*}_$e $k; done; done; }
R=$OUT/rules.txt; : > $R
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $R; }
abs() { local x; for x in "$@"; do echo ${x#-}; done; }
same=0; tot=0; for n in $(plays | awk '$2 == "chain" { print $1 }'); do tot=$((tot + 1)); cmp -s $OUT/runs/$n.txt $OUT/runs/${n%_chain}_off.txt && same=$((same + 1)); done
rule R1_safe_when_off eq $same $tot
rule R2_released_departs all_ge 100 $(abs $(each mean_speed_ums hold stock $THREE) $(each mean_speed_ums import stock $THREE))
dropped=0; tot=0; for s in $SOLVERS; do for q in $DTS; do tot=$((tot + 1)); [ "$(v ${s}_import_${q%%:*}_stock imported_mu_static)" = none ] && dropped=$((dropped + 1)); done; done
rule R2_released_drops_the_import eq $dropped $tot
rule R3_held all_in -10 10 $(each mean_speed_ums hold on $THREE)
# a CONTACT file's second column is the cube's speed along x: `final` names it speed_urads
rule R4_kinetic_on_the_dynamic all_within 2260000 50 $(each speed_urads kinetic on $THREE)
rule R5_breaks_away all_within 4410000 20 $(each speed_urads break on $THREE)
for s in $THREE; do for q in $DTS; do d=${q%%:*}
  rule R6_${s}_${d}_slides_on_the_dynamic within $(v ${s}_slide_${d}_on slid_um) $(v ${s}_slide_${d}_chain slid_um) 50; done; done
got=0; tot=0; for s in $SOLVERS; do for q in $DTS; do for e in chain on; do tot=$((tot + 1)); [ "$(v ${s}_import_${q%%:*}_$e imported_mu_static)" = 0.75 ] && got=$((got + 1)); done; done; done
rule R7_imported eq $got $tot
rule R7_imported_held all_in -10 10 $(each mean_speed_ums import on $THREE)
ok=0; tot=0; for n in $(plays | awk '{ print $1 }'); do tot=$((tot + 1)); x=0
  case $n in mujoco_*_on|vbd_alm_*_on|vbd_*_on) x=1;; esac
  [ "$(v $n static_warnings)" = $x ] && ok=$((ok + 1)); done
rule R8_the_others_say_so eq $ok $tot
rule R9_numbers all_eq -1 $(plays | awk '{ print $1 }' | while read -r n; do v $n stops; done)
echo "rules: $(wc -l < $R | tr -d ' '), held: $(grep -c ': HELD$' $R)" >> $R
cat $R $M
