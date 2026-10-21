#!/usr/bin/env bash
# Run 033: the third registered study (preregistrations/PREREGISTRATION_03.md), played once. Four arms, each in its own
# scratch folder: stock (Newton 1.6.1 from PyPI), off (the patched source, no switch), unit (Study 1's switch only),
# on (Study 1's switch and NEWTON_CONTACT_DAMPING_NO_PULL=1); SemiImplicit and Featherstone; and XPBD's drop, stock and
# with both switches. Then every registered rule is judged by sx_contact rule.
# DRY=1 plays the on arm only with throwaway parameters, into dry/, to check that the runner runs to the end; no rule is
# read from it.
# usage: play.sh <sx_contact binary>   (repository root; STOCK_VENV and NORMAL_VENV set to the two environments,
#        NORMAL_SRC to the patched source, to record it)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"
O=validation/run_033_study_03; ROOT=$(pwd)
if [ "${DRY:-0}" = 1 ]; then
  OUT=$O/dry; ARMS="on"; CUBE="mass=2 radius=0.04"; WEIGHT=19600
  DRULED="0.005 0.00125"; DREPORT="0.01"; CSTEPS="0.005 0.00125"; HRULED="0.00125"; HREPORT="0.005"
  DROP="h0=0.08 mu=0 secs=0.5"; SLIDE="h0=0 vx0=1 mu=0.4 secs=0.2"; REST="h0=0 mu=0.4 secs=0.5"
  LIFT="h0=0 lift=58.8 liftat=0.2 secs=0.3"; HOLD="h0=0 mu=0.5 push=5.88 pushat=0.2 secs=0.6"; MU10K=4000; CREEP=1470
else
  OUT=$O; ARMS="stock off unit on"; CUBE="mass=3 radius=0.06"; WEIGHT=29400
  DRULED="0.006 0.003 0.0015 0.00075 0.000375"; DREPORT="0.012 0.015"; CSTEPS="0.0015 0.000375"
  HRULED="0.0002 0.0001"; HREPORT="0.00075"
  DROP="h0=0.07 mu=0 secs=0.5"; SLIDE="h0=0 vx0=1.2 mu=0.35 secs=0.3"; REST="h0=0 mu=0.35 secs=1"
  LIFT="h0=0 lift=88.2 liftat=0.3 secs=0.4"; HOLD="h0=0 mu=0.45 push=7.938 pushat=0.4 secs=1.5"; MU10K=3500; CREEP=1985
fi
mkdir -p $OUT
play_arm() {  # every registered play of one arm, both solvers, into runs/; STATS lines into stats/
  local s dt
  mkdir -p runs stats
  for s in semi featherstone; do
    { for dt in $DRULED $DREPORT; do python tools/nwt_contact.py runs/drop_${s}_$dt.txt dt=$dt $CUBE $DROP solver=$s > stats/drop_${s}_$dt.txt; done
      for dt in $CSTEPS; do
        python tools/nwt_contact.py runs/slide_${s}_$dt.txt dt=$dt $CUBE $SLIDE solver=$s > stats/slide_${s}_$dt.txt
        python tools/nwt_contact.py runs/rest_${s}_$dt.txt dt=$dt $CUBE $REST solver=$s > stats/rest_${s}_$dt.txt
        python tools/nwt_contact.py runs/lift_${s}_$dt.txt dt=$dt $CUBE $LIFT solver=$s > stats/lift_${s}_$dt.txt
      done
      for dt in $HRULED $HREPORT; do python tools/nwt_contact.py runs/hold_${s}_$dt.txt dt=$dt $CUBE $HOLD solver=$s > stats/hold_${s}_$dt.txt; done
    } 2>> runs/log.txt
  done
}
arm() {  # <name>
  local name=$1 venv u n X
  case $name in stock) venv="$STOCK_VENV";; *) venv="$NORMAL_VENV";; esac
  case $name in unit|on) u=1;; *) u="";; esac
  case $name in on) n=1;; *) n="";; esac
  X=$(mktemp -d); cp -R tools $X/
  (cd $X && . "$venv/bin/activate" && unset NEWTON_UNIT_FRICTION_DIRECTION NEWTON_CONTACT_DAMPING_NO_PULL &&
   if [ -n "$u" ]; then export NEWTON_UNIT_FRICTION_DIRECTION=1; fi &&
   if [ -n "$n" ]; then export NEWTON_CONTACT_DAMPING_NO_PULL=1; fi && play_arm)
  mkdir -p $ROOT/$OUT/$name; cp -R $X/runs $X/stats $ROOT/$OUT/$name/; rm -rf $X
}
xpbd() {  # <name> <venv> <switches 0|1>: XPBD's drop at 1.5 ms (the study only)
  local X; X=$(mktemp -d); cp -R tools $X/
  (cd $X && . "$2/bin/activate" && unset NEWTON_UNIT_FRICTION_DIRECTION NEWTON_CONTACT_DAMPING_NO_PULL &&
   if [ "$3" = 1 ]; then export NEWTON_UNIT_FRICTION_DIRECTION=1 NEWTON_CONTACT_DAMPING_NO_PULL=1; fi &&
   mkdir -p runs stats && python tools/nwt_contact.py runs/drop_xpbd_0.0015.txt dt=0.0015 $CUBE $DROP solver=xpbd > stats/drop_xpbd_0.0015.txt 2>> runs/log.txt)
  mkdir -p $ROOT/$OUT/$1; cp -R $X/runs $X/stats $ROOT/$OUT/$1/; rm -rf $X
}
date -u +%FT%TZ > $OUT/started.txt
if [ -n "${NORMAL_SRC:-}" ]; then
  { git -C "$NORMAL_SRC" status --short
    (cd "$NORMAL_SRC" && sha256sum newton/_src/solvers/semi_implicit/kernels_contact.py newton/_src/solvers/semi_implicit/kernels_contact_unit.py newton/_src/solvers/semi_implicit/kernels_contact_normal.py newton/_src/solvers/featherstone/solver_featherstone.py)
  } > $OUT/patched_source.txt
fi
for a in $ARMS; do arm $a & done
if [ "${DRY:-0}" != 1 ]; then xpbd xpbd_stock "$STOCK_VENV" 0 & xpbd xpbd_on "$NORMAL_VENV" 1 & fi
wait
date -u +%FT%TZ > $OUT/finished.txt
# ---- measuring
pick() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
M=$OUT/measured.txt; : > $M
for a in $ARMS; do
  d=$OUT/$a/runs
  for s in semi featherstone; do
    for dt in $DRULED $DREPORT; do echo "$a $s drop $dt rebound_per_10000 $("$B" bounce $d/drop_${s}_$dt.txt | tail -1 | pick rebound_per_10000)" >> $M; done
    for dt in $CSTEPS; do
      echo "$a $s slide $dt friction_over_normal_per_10000 $("$B" creep $d/slide_${s}_$dt.txt | tail -1 | pick friction_over_normal_per_10000)" >> $M
      echo "$a $s rest $dt mean_ground_force_mN $("$B" rest $d/rest_${s}_$dt.txt | tail -1 | pick mean_ground_force_mN)" >> $M
      echo "$a $s lift $dt lowest_ground_force_mN $("$B" pull $d/lift_${s}_$dt.txt | tail -1 | pick lowest_ground_force_mN)" >> $M
    done
    for dt in $HRULED $HREPORT; do echo "$a $s hold $dt mean_speed_ums $("$B" creep $d/hold_${s}_$dt.txt | tail -1 | pick mean_speed_ums)" >> $M; done
  done
  echo "$a nan_plays $(cat $OUT/$a/stats/*.txt | grep -c nan_at_step)" >> $M
done
[ "${DRY:-0}" = 1 ] && { echo "dry run: $(wc -l < $M | tr -d ' ') measured lines"; cat $M; exit 0; }
val() { grep "^$1 $2 $3 $4 " $M | awk '{ print $NF }'; }
# ---- the rules
R=$OUT/rules.txt; : > $R
rule() { "$B" rule "$@" | tail -1 >> $R; }
n=0; same=0
for f in $(cd $OUT/stock/runs && ls *_0*.txt); do n=$((n + 1)); cmp -s $OUT/off/runs/$f $OUT/stock/runs/$f && same=$((same + 1)); done
rule R1_safe_when_off eq $same $n
rule R2_rebound_there all_ge 20 $(for s in semi featherstone; do for dt in 0.00075 0.000375; do val unit $s drop $dt; done; done)
rule R3_no_rebound all_le 10 $(for s in semi featherstone; do for dt in $DRULED; do val on $s drop $dt; done; done)
rule R4_slide all_within $MU10K 100 $(for s in semi featherstone; do for dt in $CSTEPS; do val on $s slide $dt; done; done)
rule R5_rest all_within $WEIGHT 100 $(for s in semi featherstone; do for dt in $CSTEPS; do val on $s rest $dt; done; done)
rule R6_lift all_ge 0 $(for s in semi featherstone; do for dt in $CSTEPS; do val on $s lift $dt; done; done)
rule R7_hold all_within $CREEP 100 $(for s in semi featherstone; do for dt in $HRULED; do val on $s hold $dt; done; done)
if cmp -s $OUT/xpbd_on/runs/drop_xpbd_0.0015.txt $OUT/xpbd_stock/runs/drop_xpbd_0.0015.txt; then x=1; else x=0; fi
rule R8_other_solvers eq $x 1
rule R9_no_nan eq $(( $(grep "^unit nan_plays" $M | awk '{print $NF}') + $(grep "^on nan_plays" $M | awk '{print $NF}') )) 0
echo "rules: $(wc -l < $R | tr -d ' '), held: $(grep -c ': HELD$' $R)" >> $R
cat $R
