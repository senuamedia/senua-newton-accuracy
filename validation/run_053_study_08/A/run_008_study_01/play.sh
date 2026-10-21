#!/usr/bin/env bash
# Run 008: the first registered study (preregistrations/PREREGISTRATION_01.md), played once. Three arms, each in its
# own scratch folder: stock (Newton 1.6.1 from PyPI), off (the patched source, switch unset), on
# (NEWTON_UNIT_FRICTION_DIRECTION=1). Each plays the registered scenes at 0.25 ms; then every registered rule is judged
# by sx_contact rule. DRY=1 plays throwaway parameters on the stock arm only, into dry/, to check that the runner runs
# to the end; no rule is read from it.
# usage: play.sh <sx_contact binary>   (repository root; STOCK_VENV and PATCHED_VENV set to the two environments)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"
O=validation/run_008_study_01; ROOT=$(pwd); dt=0.00025
if [ "${DRY:-0}" = 1 ]; then
  OUT=$O/dry; ARMS="stock"
  CUBE="mass=1 radius=0.05 mu=0.4"; V=1; PLATE="mass=1 radius=0.05 hz=0.005 mu=0.4 h0=0.002 kick=1 kickat=0.3 secs=1.3"
  IMPACT="mass=1 radius=0.05 h0=0.05 vx0=2 mu=0.3 secs=0.5"; REST="mass=1 radius=0.05 h0=0.02 mu=0.5 secs=1"
  DROP="mass=1 radius=0.05 h0=0.1 mu=0 secs=1"
else
  OUT=$O; ARMS="stock off on"
  CUBE="mass=0.8 radius=0.045 mu=0.45"; V=1.3; PLATE="mass=0.6 radius=0.06 hz=0.004 mu=0.3 h0=0.0015 kick=0.7 kickat=0.25 secs=1.1"
  IMPACT="mass=0.8 radius=0.045 h0=0.04 vx0=1.5 mu=0.25 secs=0.4"; REST="mass=0.8 radius=0.045 h0=0.015 mu=0.45 secs=1"
  DROP="mass=0.8 radius=0.045 h0=0.08 mu=0 secs=1"
fi
mkdir -p $OUT
play_arm() {  # every registered play of one arm into runs/, its STATS line into stats/
  local s
  mkdir -p runs stats
  for s in semi featherstone; do
    { python tools/nwt_contact.py runs/slide_$s.txt dt=$dt h0=0 vx0=$V $CUBE secs=1.2 solver=$s > stats/slide_$s.txt
      python tools/nwt_contact.py runs/plate_${s}_1.0.txt dt=$dt $PLATE solver=$s > stats/plate_${s}_1.0.txt
      python tools/nwt_contact.py runs/plate_${s}_0.05.txt dt=$dt $PLATE solver=$s opt.friction_smoothing=0.05 > stats/plate_${s}_0.05.txt
      python tools/nwt_contact.py runs/impact_$s.txt dt=$dt $IMPACT solver=$s > stats/impact_$s.txt
      python tools/nwt_contact.py runs/rest_$s.txt dt=$dt $REST solver=$s > stats/rest_$s.txt
      python tools/nwt_contact.py runs/drop_$s.txt dt=$dt $DROP solver=$s > stats/drop_$s.txt
    } 2> runs/log_$s.txt &
  done
  for s in xpbd mujoco; do
    python tools/nwt_contact.py runs/slide_$s.txt dt=$dt h0=0 vx0=$V $CUBE secs=1.2 solver=$s > stats/slide_$s.txt 2> runs/log_$s.txt
  done
  wait
}
arm() {  # <name> <venv> [switch]
  local name=$1 venv=$2 sw=${3:-} X
  X=$(mktemp -d); cp -R tools $X/
  (cd $X && . "$venv/bin/activate" && if [ -n "$sw" ]; then export NEWTON_UNIT_FRICTION_DIRECTION=$sw; else unset NEWTON_UNIT_FRICTION_DIRECTION; fi && play_arm)
  rm -rf $ROOT/$OUT/$name; mkdir -p $ROOT/$OUT/$name; cp -R $X/runs $X/stats $ROOT/$OUT/$name/; rm -rf $X
}
for a in $ARMS; do
  case $a in stock) arm stock "$STOCK_VENV";; off) arm off "$PATCHED_VENV";; on) arm on "$PATCHED_VENV" 1;; esac
done
# ---- measuring
pick() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
M=$OUT/measured.txt; : > $M
for a in $ARMS; do
  d=$OUT/$a
  for s in semi featherstone; do
    echo "$a $s slide slid_um $("$B" stop $d/runs/slide_$s.txt | tail -1 | pick slid_um) most_tilt_urad $(pick most_tilt_urad < $d/stats/slide_$s.txt)" >> $M
    for w in 1.0 0.05; do
      echo "$a $s plate_$w slid_um $("$B" stop $d/runs/plate_${s}_$w.txt | tail -1 | pick slid_um) decel_260_300 $("$B" accel $d/runs/plate_${s}_$w.txt 260 300 | tail -1 | pick mean_acceleration_mm_s2)" >> $M
    done
    echo "$a $s impact ratio_per_10000 $("$B" impact $d/runs/impact_$s.txt | tail -1 | pick ratio_per_10000)" >> $M
  done
  echo "$a nan_plays $(cat $d/stats/*.txt | grep -c nan_at_step)" >> $M
done
[ "${DRY:-0}" = 1 ] && { echo "dry run: $(wc -l < $M) measured lines"; cat $M; exit 0; }
get() { grep "^$1 " $M | pick "$2"; }
abs() { local x=$1; echo "${x#-}"; }
# ---- the rules
R=$OUT/rules.txt; : > $R
rule() { "$B" rule "$@" | tail -1 >> $R; }
n=0; same=0; for f in $(cd $OUT/stock && find runs stats -type f ! -name 'log_*' | sort); do n=$((n + 1)); cmp -s $OUT/stock/$f $OUT/off/$f && same=$((same + 1)); done
rule R1_safe_when_off eq $same $n
rule R2_stock_slide_short all_le 114966 $(get "stock semi slide" slid_um) $(get "stock featherstone slide" slid_um)
rule R2_stock_plate_over all_ge 4410 $(abs $(get "stock semi plate_1.0" decel_260_300)) $(abs $(get "stock featherstone plate_1.0" decel_260_300))
rule R3_slide all_within 191610 50 $(get "on semi slide" slid_um) $(get "on featherstone slide" slid_um)
rule R3_plate all_within 83333 100 $(for s in semi featherstone; do for w in 1.0 0.05; do get "on $s plate_$w" slid_um; done; done)
rule R4_impact all_within 2500 100 $(get "on semi impact" ratio_per_10000) $(get "on featherstone impact" ratio_per_10000)
for s in semi featherstone; do
  if cmp -s $OUT/on/runs/plate_${s}_1.0.txt $OUT/on/runs/plate_${s}_0.05.txt; then w=1; else w=0; fi
  rule R5_width_free_$s eq $w 1
done
rule R6_no_tip all_le 30000 $(get "on semi slide" most_tilt_urad) $(get "on featherstone slide" most_tilt_urad)
n=0; same=0
for f in runs/rest_semi.txt runs/rest_featherstone.txt runs/drop_semi.txt runs/drop_featherstone.txt runs/slide_xpbd.txt runs/slide_mujoco.txt; do
  n=$((n + 1)); cmp -s $OUT/stock/$f $OUT/on/$f && same=$((same + 1))
done
rule R7_nothing_else eq $same $n
rule R8_no_nan eq $(get "on nan_plays" nan_plays) 0
echo "rules: $(wc -l < $R), held: $(grep -c ': HELD$' $R)" | tee -a $R
