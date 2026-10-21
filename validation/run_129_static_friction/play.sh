#!/usr/bin/env bash
# Run 129: Senua AI's static friction patch in design (patches/in_design/static_friction_on_chain.diff, on the record's
# validated friction chains with pull request #4306; NEWTON_STATIC_FRICTION=1) on a 1 kg cube of half-size 0.05 m, its
# and the plane's friction 0.4 and static friction 0.8, on Newton 1.7.0: held under a push of 5.88 N from 0.3 s
# (between the two limits), sliding from 0.5 m/s under the same push from the start, pushed at 8.82 N (above the static
# limit) from 0.3 s, and slid from 1 m/s with no push; on XPBD (no speed floor, friction on the step's totals, 64
# iterations: Study 15), SemiImplicit and Featherstone (the Coulomb friction pass at 64 sweeps: Study 18), and the
# MuJoCo solver and VBD-ALM, reported; at 0.5 ms (issue 18). A design probe whose predictions were pushed before the
# plays. Then measured.txt and checks.txt.
# usage: play.sh <sx_contact binary> <engine folder> [parallel plays a setting]   (repository root; the engine folder
#   made by this run's setup_engine.sh)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary> <engine folder>}")" && pwd)/$(basename "$1")"; E="$(cd "${2:?}" && pwd)"; P=${3:-3}
O=validation/run_129_static_friction
F="mass=1 radius=0.05 h0=0 mu=0.4 groundmu=0.4 mus=0.8 groundmus=0.8 dt=0.0005"
sv() { case $1 in xpbd) echo "solver=xpbd iterations=64";; vbd) echo "solver=vbd_alm";; *) echo "solver=$1";; esac; }
plays() { local s e; for s in xpbd semi featherstone mujoco vbd; do for e in chain off on; do
  echo "${s}_hold_$e $e $F push=5.88 pushat=0.3 secs=1.2 $(sv $s)"
  echo "${s}_kinetic_$e $e $F push=5.88 pushat=0 vx0=0.5 secs=1 $(sv $s)"
  echo "${s}_break_$e $e $F push=8.82 pushat=0.3 secs=1.2 $(sv $s)"
  echo "${s}_slide_$e $e $F vx0=1 secs=0.6 $(sv $s)"; done; done; }
mkdir -p $O/runs $O/stats; date -u +%FT%TZ > $O/started.txt
for g in chain off on; do
  ( v=$E/on; [ $g = chain ] && v=$E/chain; . "$v/bin/activate"
    export NEWTON_XPBD_NO_SPEED_FLOOR=1 NEWTON_XPBD_FRICTION_TOTAL=1 NEWTON_UNIT_FRICTION_DIRECTION=1 NEWTON_CONTACT_DAMPING_NO_PULL=1
    export NEWTON_SEMI_COULOMB_FRICTION=1 NEWTON_SEMI_COULOMB_FRICTION_ITERATIONS=64 NEWTON_FEATHERSTONE_COULOMB_FRICTION=64
    unset NEWTON_STATIC_FRICTION; [ $g = on ] && export NEWTON_STATIC_FRICTION=1
    plays | awk -v g=$g '$2 == g { $2 = ""; print }' | xargs -P $P -L 1 bash -c 'python tools/nwt_contact.py '"$O"'/runs/$0.txt "$@" > '"$O"'/stats/$0.txt 2> '"$O"'/runs/err_$0.txt' ) &
done
wait; date -u +%FT%TZ > $O/finished.txt
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
pick() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
M=$O/measured.txt; : > $M
for n in $(plays | awk '{ print $1 }'); do st=$(pick nan_at_step < $O/stats/$n.txt)
  case $n in *_hold_*) m=creep;; *_slide_*) m=stop;; *) m=final;; esac
  w=$(grep -c "does not apply a static friction coefficient" $O/runs/err_$n.txt)
  echo "$n stops ${st:--1} static_warnings $w $("$B" $m $O/runs/$n.txt < /dev/null | tail -1)" >> $M; done
v() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $M; }
C=$O/checks.txt; : > $C
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $C; }
rule C0_numbers all_eq -1 $(plays | awk '{ print $1 }' | while read -r n; do v $n stops; done)
same=0; tot=0; for n in $(plays | awk '$2 == "chain" { print $1 }'); do tot=$((tot + 1)); cmp -s $O/runs/$n.txt $O/runs/${n%_chain}_off.txt && same=$((same + 1)); done
rule P1_safe_when_off eq $same $tot
rule P2_released_slides all_ge 100000 $(for s in xpbd semi featherstone; do v ${s}_hold_chain mean_speed_ums; done)
rule P3_held all_in -10 10 $(for s in xpbd semi featherstone; do v ${s}_hold_on mean_speed_ums; done)
# a CONTACT file's second column is the cube's speed along x: `final` names it speed_urads
rule P4_kinetic_on_the_dynamic all_within 2460000 50 $(for s in xpbd semi featherstone; do v ${s}_kinetic_on speed_urads; done)
rule P5_breaks_away all_within 4410000 20 $(for s in xpbd semi featherstone; do v ${s}_break_on speed_urads; done)
for s in xpbd semi featherstone; do rule P6_${s}_slide_on_the_dynamic within $(v ${s}_slide_on slid_um) $(v ${s}_slide_chain slid_um) 50; done
rule P7_mujoco_says_so eq $(v mujoco_hold_on static_warnings) 1
echo "checks: $(wc -l < $C | tr -d ' '), held: $(grep -c ': HELD$' $C)" >> $C
cat $C $M
