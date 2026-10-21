#!/usr/bin/env bash
# Run 037: the fifth registered study (preregistrations/PREREGISTRATION_05.md), played once. Three arms, each in its own
# scratch folder: stock (Newton 1.6.1 from PyPI), off (the patched source, no switch), on
# (NEWTON_XPBD_JOINT_ANGLE_UNWRAP=1); XPBD; one arm on one hinge (tools/nwt_joint.py). Then every registered rule is
# judged by sx_contact rule.
# DRY=1 plays the on arm only with throwaway parameters, into dry/, to check that the runner runs to the end; no rule is
# read from it.
# usage: play.sh <sx_contact binary>   (repository root; STOCK_VENV and XLIM_VENV set, XLIM_SRC to record the source)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"
O=validation/run_037_study_05; ROOT=$(pwd)
if [ "${DRY:-0}" = 1 ]; then
  OUT=$O/dry; ARMS="on"; STEPS="0.0025"; ARM="mass=1 radius=0.05 arm=0.5 gravity=0 omega0=3"
else
  OUT=$O; ARMS="stock off on"; STEPS="0.0016 0.00032"; ARM="mass=1.5 radius=0.03 arm=0.3 gravity=0 omega0=3"
fi
mkdir -p $OUT
play_arm() {
  local dt
  mkdir -p runs stats
  for dt in $STEPS; do
    { python tools/nwt_joint.py runs/none_$dt.txt dt=$dt $ARM secs=1.6 solver=xpbd > stats/none_$dt.txt
      python tools/nwt_joint.py runs/inside_$dt.txt dt=$dt $ARM secs=1.6 lo=-0.5 hi=5 solver=xpbd > stats/inside_$dt.txt
      python tools/nwt_joint.py runs/reach_$dt.txt dt=$dt $ARM secs=1.6 lo=-0.5 hi=3.6 solver=xpbd > stats/reach_$dt.txt
      python tools/nwt_joint.py runs/below_$dt.txt dt=$dt $ARM secs=1.4 lo=-0.5 hi=2.5 solver=xpbd > stats/below_$dt.txt
    } 2>> runs/log.txt
  done
}
arm() {  # <name>
  local name=$1 venv X
  case $name in stock) venv="$STOCK_VENV";; *) venv="$XLIM_VENV";; esac
  X=$(mktemp -d); cp -R tools $X/
  (cd $X && . "$venv/bin/activate" && unset NEWTON_XPBD_JOINT_ANGLE_UNWRAP &&
   if [ $name = on ]; then export NEWTON_XPBD_JOINT_ANGLE_UNWRAP=1; fi && play_arm)
  mkdir -p $ROOT/$OUT/$name; cp -R $X/runs $X/stats $ROOT/$OUT/$name/; rm -rf $X
}
date -u +%FT%TZ > $OUT/started.txt
if [ -n "${XLIM_SRC:-}" ]; then
  { git -C "$XLIM_SRC" status --short
    (cd "$XLIM_SRC" && sha256sum newton/_src/solvers/xpbd/solver_xpbd.py newton/_src/solvers/xpbd/joint_angle_unwrap_kernels.py newton/_src/solvers/xpbd/kernels.py)
  } > $OUT/patched_source.txt
fi
for a in $ARMS; do arm $a & done
wait
date -u +%FT%TZ > $OUT/finished.txt
# ---- measuring
pick() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
M=$OUT/measured.txt; : > $M
for a in $ARMS; do
  for dt in $STEPS; do for sc in none inside reach below; do
    l=$("$B" final $OUT/$a/runs/${sc}_$dt.txt | tail -1)
    echo "$a $sc $dt angle_urad $(echo "$l" | pick angle_urad) speed_urads $(echo "$l" | pick speed_urads)" >> $M
  done; done
  echo "$a nan_plays $(cat $OUT/$a/stats/*.txt | grep -c nan_at_step)" >> $M
done
[ "${DRY:-0}" = 1 ] && { echo "dry run: $(wc -l < $M | tr -d ' ') measured lines"; cat $M; exit 0; }
# ---- the rules
R=$OUT/rules.txt; : > $R
rule() { "$B" rule "$@" | tail -1 >> $R; }
cnt() {  # <dir a> <dir b> <files...>: how many of the files are byte-identical in the two folders
  local a=$1 b=$2 n=0 f; shift 2
  for f in "$@"; do cmp -s $a/$f $b/$f && n=$((n + 1)); done; echo $n
}
n=0; same=0
for f in $(cd $OUT/stock/runs && ls *_0*.txt); do n=$((n + 1)); cmp -s $OUT/off/runs/$f $OUT/stock/runs/$f && same=$((same + 1)); done
rule R1_safe_when_off eq $same $n
s2=0; for dt in $STEPS; do cmp -s $OUT/stock/runs/inside_$dt.txt $OUT/stock/runs/none_$dt.txt && s2=$((s2 + 1)); done
rule R2_fault_there eq $s2 0
s3=0; for dt in $STEPS; do cmp -s $OUT/on/runs/inside_$dt.txt $OUT/on/runs/none_$dt.txt && s3=$((s3 + 1)); done
rule R3_inside_as_none eq $s3 2
rule R4_reach_angle all_within 3600000 139 $(for dt in $STEPS; do grep "^on reach $dt " $M | pick angle_urad; done)
rule R4_reach_speed_hi all_le 100000 $(for dt in $STEPS; do grep "^on reach $dt " $M | pick speed_urads; done)
rule R4_reach_speed_lo all_ge -100000 $(for dt in $STEPS; do grep "^on reach $dt " $M | pick speed_urads; done)
s5=$(cnt $OUT/on/runs $OUT/stock/runs $(for dt in $STEPS; do echo none_$dt.txt below_$dt.txt; done))
rule R5_nothing_else eq $s5 4
rule R6_no_nan eq $(grep "^on nan_plays" $M | awk '{print $NF}') 0
echo "rules: $(wc -l < $R | tr -d ' '), held: $(grep -c ': HELD$' $R)" >> $R
cat $R
