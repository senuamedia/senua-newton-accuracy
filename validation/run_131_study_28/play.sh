#!/usr/bin/env bash
# Run 131: the twenty-eighth registered study (preregistrations/PREREGISTRATION_28.md), played once on Newton 1.7.0: one
# model across engines, MuJoCo C (the MuJoCo solver's CPU path, MuJoCo's own mj_step, elliptic cone and noslip) as the
# reference, and Newton's own solvers as released and with the record's friction chains (issue 22). Each play into
# runs/, its error stream into runs/err_<play>.txt and its statistics into stats/, then the registered rules judged by
# sx_contact rule (rules.txt), the measured lines beside them (measured.txt). DRY=1 plays one throwaway play of each
# scene and setting (0.04 s), into dry/, to check that the runner runs to the end.
# usage: play.sh <sx_contact binary> <engine folder> [parallel plays a setting]   (repository root)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary> <engine folder>}")" && pwd)/$(basename "$1")"; E="$(cd "${2:?}" && pwd)"; P=${3:-2}
O=validation/run_131_study_28
if [ "${DRY:-0}" = 1 ]; then OUT=$O/dry; else OUT=$O; fi
sc() { [ "${DRY:-0}" = 1 ] && echo 0.04 || echo $1; }
F="mass=0.8 radius=0.045 h0=0 mu=0.45"
sv() { case $1 in xpbd) echo "solver=xpbd iterations=64";; mjc) echo "solver=mujoco opt.use_mujoco_cpu=true opt.cone=elliptic opt.noslip_iterations=10";;
  mjwarp) echo "solver=mujoco opt.cone=elliptic";; *) echo "solver=$1";; esac; }
THREE="xpbd semi featherstone"; DTS="d1:0.001 d05:0.0005"
scenes() {  # <name prefix> <engine> <solver>
  local q d t; for q in $DTS; do d=${q%%:*}; t=${q#*:}
    echo "$1_slide_$d $2 $F dt=$t vx0=0.9 secs=$(sc 0.6) $(sv $3)"
    echo "$1_hold_$d $2 $F dt=$t push=2.1168 pushat=0.3 secs=$(sc 1.2) $(sv $3)"
    echo "$1_push_$d $2 $F dt=$t push=5.292 pushat=0.3 secs=$(sc 1.2) $(sv $3)"; done; }
plays() { local s e; scenes mjc mjc mjc; for s in $THREE mjwarp vbd_alm vbd; do for e in stock chain; do scenes ${s}_$e $e $s; done; done; }
mkdir -p $OUT/runs $OUT/stats; date -u +%FT%TZ > $OUT/started.txt
for g in mjc stock chain; do
  ( . "$E/$g/bin/activate"
    export NEWTON_XPBD_NO_SPEED_FLOOR=1 NEWTON_XPBD_FRICTION_TOTAL=1 NEWTON_UNIT_FRICTION_DIRECTION=1 NEWTON_CONTACT_DAMPING_NO_PULL=1
    export NEWTON_SEMI_COULOMB_FRICTION=1 NEWTON_SEMI_COULOMB_FRICTION_ITERATIONS=64 NEWTON_FEATHERSTONE_COULOMB_FRICTION=64
    plays | awk -v g=$g '$2 == g { $2 = ""; print }' | xargs -P $P -L 1 bash -c 'python tools/nwt_contact.py '"$OUT"'/runs/$0.txt "$@" > '"$OUT"'/stats/$0.txt 2> '"$OUT"'/runs/err_$0.txt' ) &
done
wait; date -u +%FT%TZ > $OUT/finished.txt
grep -rlIF "$HOME" $OUT 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
pick() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
M=$OUT/measured.txt; : > $M
for n in $(plays | awk '{ print $1 }'); do st=$(pick nan_at_step < $OUT/stats/$n.txt)
  case $n in *_hold_*) m=creep;; *_slide_*) m=stop;; *) m=final;; esac
  echo "$n stops ${st:--1} $("$B" $m $OUT/runs/$n.txt < /dev/null | tail -1)" >> $M; done
[ "${DRY:-0}" = 1 ] && { echo "dry run: $(wc -l < $M | tr -d ' ') measured lines"; cat $M; exit 0; }
v() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $M; }
R=$OUT/rules.txt; : > $R
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $R; }
abs() { local x; for x in "$@"; do echo ${x#-}; done; }
ds() { local q; for q in $DTS; do echo ${q%%:*}; done; }
rule R1_reference_slide all_within 91837 100 $(for d in $(ds); do v mjc_slide_$d slid_um; done)
rule R1_reference_hold all_in -10 10 $(for d in $(ds); do v mjc_hold_$d mean_speed_ums; done)
# a CONTACT file's second column is the cube's speed along x: `final` names it speed_urads
rule R1_reference_push all_within 1984500 100 $(for d in $(ds); do v mjc_push_$d speed_urads; done)
dep=0; for d in $(ds); do r=$(v mjc_slide_$d slid_um); hit=0
  for s in $THREE; do x=$(v ${s}_stock_slide_$d slid_um); h=$(abs $(v ${s}_stock_hold_$d mean_speed_ums))
    [ $(abs $((x - r))) -ge $((r / 10)) ] && hit=1; [ $h -ge 100 ] && hit=1; done; dep=$((dep + hit)); done
rule R2_released_departs eq $dep 2
for s in $THREE; do for d in $(ds); do
  rule R3_${s}_${d}_slide within $(v ${s}_chain_slide_$d slid_um) $(v mjc_slide_$d slid_um) 100
  rule R5_${s}_${d}_push within $(v ${s}_chain_push_$d speed_urads) $(v mjc_push_$d speed_urads) 100; done; done
rule R4_held all_in -10 10 $(for s in $THREE; do for d in $(ds); do v ${s}_chain_hold_$d mean_speed_ums; done; done)
rule R6_numbers all_eq -1 $(plays | awk '{ print $1 }' | while read -r n; do v $n stops; done)
echo "rules: $(wc -l < $R | tr -d ' '), held: $(grep -c ': HELD$' $R)" >> $R
cat $R $M
