#!/usr/bin/env bash
# Run 034: the fourth registered study (preregistrations/PREREGISTRATION_04.md), played once. Three arms, each in its
# own scratch folder: stock (Newton 1.6.1 from PyPI), off (the patched source, no switch), on
# (NEWTON_VBD_CARRIED_VELOCITY=2), on VBD and VBD-ALM; and SemiImplicit's fall from stock, the reference. Then every
# registered rule is judged by sx_contact rule.
# DRY=1 plays the on arm only with throwaway parameters, into dry/, to check that the runner runs to the end; no rule is
# read from it.
# usage: play.sh <sx_contact binary>   (repository root; STOCK_VENV and VBD_VENV set, VBD_SRC to record the source)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"
O=validation/run_034_study_04; ROOT=$(pwd)
ARMSC="mass1=1.2 mass2=0.6 radius=0.04 arm1=0.25 len1=0.5 arm2=0.2"
if [ "${DRY:-0}" = 1 ]; then
  OUT=$O/dry; ARMS="on"; STEPS="0.00125"; CUBE="mass=2 radius=0.04"; WEIGHT=19600; MU10K=4000
  FALL="h0=1 mu=0 secs=0.1"; SLIDE="h0=0 vx0=1 mu=0.4 secs=0.2"; REST="h0=0 mu=0.4 secs=0.3"
  LIFT="h0=0 lift=58.8 liftat=0.1 secs=0.2"; HOLD="h0=0 mu=0.5 push=5.88 pushat=0.1 secs=0.3"
  CHAIN="gravity=0 angle2=-0.9 omega1=2.5 omega2=1.5 secs=0.2"
else
  OUT=$O; ARMS="stock off on"; STEPS="0.0002 0.00005"; CUBE="mass=1.6 radius=0.03"; WEIGHT=15680; MU10K=3000
  FALL="h0=6 mu=0 secs=0.3"; SLIDE="h0=0 vx0=1.4 mu=0.3 secs=0.3"; REST="h0=0 mu=0.3 secs=1"
  LIFT="h0=0 lift=47.04 liftat=0.2 secs=0.4"; HOLD="h0=0 mu=0.55 push=5.1744 pushat=0.3 secs=1"
  CHAIN="gravity=0 angle2=-0.9 omega1=2.5 omega2=1.5 secs=2"
fi
mkdir -p $OUT
play_solver() {  # <solver>: every registered play of one solver into runs/, STATS lines into stats/
  local s=$1 dt X
  mkdir -p runs stats
  if [ $s = vbd ]; then X="solver=vbd"; else X="solver=vbd opt.rigid_compliant_alm=true"; fi
  for dt in $STEPS; do
    { python tools/nwt_contact.py runs/fall_${s}_$dt.txt dt=$dt $CUBE $FALL solver=$s > stats/fall_${s}_$dt.txt
      python tools/nwt_contact.py runs/slide_${s}_$dt.txt dt=$dt $CUBE $SLIDE solver=$s > stats/slide_${s}_$dt.txt
      python tools/nwt_contact.py runs/rest_${s}_$dt.txt dt=$dt $CUBE $REST solver=$s > stats/rest_${s}_$dt.txt
      python tools/nwt_contact.py runs/lift_${s}_$dt.txt dt=$dt $CUBE $LIFT solver=$s > stats/lift_${s}_$dt.txt
      python tools/nwt_contact.py runs/hold_${s}_$dt.txt dt=$dt $CUBE $HOLD solver=$s > stats/hold_${s}_$dt.txt
      python tools/nwt_chain.py runs/chain_${s}_$dt.txt dt=$dt $ARMSC $CHAIN $X > stats/chain_${s}_$dt.txt
    } 2>> runs/log_$s.txt
  done
}
lane() {  # <arm> <solver>
  local name=$1 s=$2 venv X
  case $name in stock) venv="$STOCK_VENV";; *) venv="$VBD_VENV";; esac
  X=$(mktemp -d); cp -R tools $X/
  (cd $X && . "$venv/bin/activate" && unset NEWTON_VBD_CARRIED_VELOCITY &&
   if [ $name = on ]; then export NEWTON_VBD_CARRIED_VELOCITY=2; fi && play_solver $s)
  mkdir -p $ROOT/$OUT/$name; cp -R $X/runs $X/stats $ROOT/$OUT/$name/; rm -rf $X
}
reference() {  # SemiImplicit's falls from stock
  local X dt; X=$(mktemp -d); cp -R tools $X/
  (cd $X && . "$STOCK_VENV/bin/activate" && mkdir -p runs stats &&
   for dt in $STEPS; do python tools/nwt_contact.py runs/fall_semi_$dt.txt dt=$dt $CUBE $FALL solver=semi > stats/fall_semi_$dt.txt 2>> runs/log_semi.txt; done)
  mkdir -p $ROOT/$OUT/reference; cp -R $X/runs $X/stats $ROOT/$OUT/reference/; rm -rf $X
}
date -u +%FT%TZ > $OUT/started.txt
if [ -n "${VBD_SRC:-}" ]; then
  { git -C "$VBD_SRC" status --short
    (cd "$VBD_SRC" && sha256sum newton/_src/solvers/vbd/solver_vbd.py newton/_src/solvers/vbd/rigid_velocity_carried.py newton/_src/solvers/vbd/rigid_vbd_kernels.py)
  } > $OUT/patched_source.txt
fi
reference
n=0
for a in $ARMS; do for s in vbd vbd_alm; do
  lane $a $s & n=$((n + 1)); if [ $((n % 4)) = 0 ]; then wait; fi
done; done
wait
# the two solvers' plays of one arm into one folder
date -u +%FT%TZ > $OUT/finished.txt
# ---- measuring
pick() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
M=$OUT/measured.txt; : > $M
for a in $ARMS; do
  d=$OUT/$a/runs
  for s in vbd vbd_alm; do for dt in $STEPS; do
    echo "$a $s fall $dt gap_to_semi_um $("$B" gap 10000000 $d/fall_${s}_$dt.txt $OUT/reference/runs/fall_semi_$dt.txt | tail -1 | pick summed_height_difference_um)" >> $M
    echo "$a $s slide $dt friction_over_normal_per_10000 $("$B" creep $d/slide_${s}_$dt.txt | tail -1 | pick friction_over_normal_per_10000)" >> $M
    echo "$a $s rest $dt mean_ground_force_mN $("$B" rest $d/rest_${s}_$dt.txt | tail -1 | pick mean_ground_force_mN)" >> $M
    echo "$a $s lift $dt lowest_ground_force_mN $("$B" pull $d/lift_${s}_$dt.txt | tail -1 | pick lowest_ground_force_mN)" >> $M
    echo "$a $s hold $dt mean_speed_ums $("$B" creep $d/hold_${s}_$dt.txt | tail -1 | pick mean_speed_ums)" >> $M
    echo "$a $s chain $dt kinetic_end_per_million_of_start $("$B" chain $d/chain_${s}_$dt.txt | tail -1 | pick kinetic_end_per_million_of_start)" >> $M
  done; done
  echo "$a nan_plays $(cat $OUT/$a/stats/*.txt | grep -c nan_at_step)" >> $M
done
[ "${DRY:-0}" = 1 ] && { echo "dry run: $(wc -l < $M | tr -d ' ') measured lines"; cat $M; exit 0; }
val() { grep "^$1 $2 $3 $4 " $M | awk '{ print $NF }'; }
# ---- the rules
R=$OUT/rules.txt; : > $R; T=$OUT/tests.txt; : > $T
rule() { "$B" rule "$@" | tail -1 >> $R; }
test_line() { "$B" rule "$@" | tail -1 >> $T; }
n=0; same=0
for f in $(cd $OUT/stock/runs && ls *_0*.txt); do n=$((n + 1)); cmp -s $OUT/off/runs/$f $OUT/stock/runs/$f && same=$((same + 1)); done
rule R1_safe_when_off eq $same $n
rule R2_defect_there all_ge 100000 $(for s in vbd vbd_alm; do for dt in $STEPS; do val stock $s fall $dt; done; done)
n=0; same=0
for s in vbd vbd_alm; do for dt in $STEPS; do n=$((n + 1)); cmp -s $OUT/on/runs/fall_${s}_$dt.txt $OUT/reference/runs/fall_semi_$dt.txt && same=$((same + 1)); done; done
rule R3_fall eq $same $n
# R4: each test judged for stock and for on by its own rule lines (tests.txt); count the tests stock holds and on fails
for a in stock on; do for s in vbd vbd_alm; do for dt in $STEPS; do
  test_line T_${a}_${s}_slide_$dt all_within $MU10K 100 $(val $a $s slide $dt)
  test_line T_${a}_${s}_rest_$dt all_within $WEIGHT 100 $(val $a $s rest $dt)
  test_line T_${a}_${s}_lift_$dt all_ge 0 $(val $a $s lift $dt)
  test_line T_${a}_${s}_holdhi_$dt all_le 10 $(val $a $s hold $dt)
  test_line T_${a}_${s}_holdlo_$dt all_ge -10 $(val $a $s hold $dt)
done; done; done
held() { grep -q "^RULE $1 .*: HELD$" $T && echo 1 || echo 0; }
bad=0
for s in vbd vbd_alm; do for dt in $STEPS; do for k in slide rest lift hold; do
  if [ $k = hold ]; then
    sh=$(( $(held T_stock_${s}_holdhi_$dt) * $(held T_stock_${s}_holdlo_$dt) )); oh=$(( $(held T_on_${s}_holdhi_$dt) * $(held T_on_${s}_holdlo_$dt) ))
  else
    sh=$(held T_stock_${s}_${k}_$dt); oh=$(held T_on_${s}_${k}_$dt)
  fi
  echo "TEST $s $k $dt stock_holds $sh on_holds $oh" >> $T
  if [ $sh = 1 ] && [ $oh = 0 ]; then bad=$((bad + 1)); fi
done; done; done
rule R4_what_passes_still_passes eq $bad 0
rule R5_no_nan eq $(grep "^on nan_plays" $M | awk '{print $NF}') 0
echo "rules: $(wc -l < $R | tr -d ' '), held: $(grep -c ': HELD$' $R)" >> $R
cat $R
