#!/usr/bin/env bash
# Run 043: the sixth registered study (preregistrations/PREREGISTRATION_06.md), played once. Three arms, each in its own
# scratch folder: stock (Newton 1.6.1 from PyPI), off (the patched source, no switch), on
# (NEWTON_MUJOCO_LIMIT_FORCE_SPACE=1); the MuJoCo solver; one arm on one hinge (tools/nwt_joint.py). Then every
# registered rule is judged by sx_contact rule.
# DRY=1 plays the on arm only with throwaway parameters, into dry/, to check that the runner runs to the end; no rule is
# read from it.
# usage: play.sh <sx_contact binary>   (repository root; STOCK_VENV and MJLIM_VENV set, MJLIM_SRC to record the source)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"
O=validation/run_043_study_06; ROOT=$(pwd)
if [ "${DRY:-0}" = 1 ]; then
  OUT=$O/dry; ARMS="on"; STEPS="0.0025"; MASSES="1"; ARM="radius=0.04 arm=0.4 secs=1"; LIM="lo=-1 hi=1"; EXTRA=""
else
  OUT=$O; ARMS="stock off on"; STEPS="0.0008 0.00016"; MASSES="0.3 3"; ARM="radius=0.035 arm=0.35 secs=1.5"
  LIM="lo=-0.8 hi=1"; EXTRA="0.01"
fi
mkdir -p $OUT
play_arm() {
  local dt m
  mkdir -p runs stats
  for m in $MASSES; do
    for dt in $STEPS $EXTRA; do python tools/nwt_joint.py runs/struck_m${m}_$dt.txt dt=$dt mass=$m $ARM $LIM solver=mujoco > stats/struck_m${m}_$dt.txt 2>> runs/log.txt; done
    for dt in $STEPS; do python tools/nwt_joint.py runs/free_m${m}_$dt.txt dt=$dt mass=$m $ARM solver=mujoco > stats/free_m${m}_$dt.txt 2>> runs/log.txt; done
  done
}
arm() {  # <name>
  local name=$1 venv X
  case $name in stock) venv="$STOCK_VENV";; *) venv="$MJLIM_VENV";; esac
  X=$(mktemp -d); cp -R tools $X/
  (cd $X && . "$venv/bin/activate" && unset NEWTON_MUJOCO_LIMIT_FORCE_SPACE &&
   if [ $name = on ]; then export NEWTON_MUJOCO_LIMIT_FORCE_SPACE=1; fi && play_arm)
  mkdir -p $ROOT/$OUT/$name; cp -R $X/runs $X/stats $ROOT/$OUT/$name/; rm -rf $X
}
date -u +%FT%TZ > $OUT/started.txt
if [ -n "${MJLIM_SRC:-}" ]; then
  { git -C "$MJLIM_SRC" status --short
    (cd "$MJLIM_SRC" && sha256sum newton/_src/solvers/mujoco/solver_mujoco.py newton/_src/solvers/mujoco/limit_force_space_kernels.py newton/_src/solvers/mujoco/kernels.py)
  } > $OUT/patched_source.txt
fi
for a in $ARMS; do arm $a & done
wait
date -u +%FT%TZ > $OUT/finished.txt
# ---- measuring: the first turning point is how far past the limit the arm went, the second where it turned back
nth() { awk -v k="$1" -v n="$2" '{ c = 0; for (i = 1; i < NF; i++) if ($i == k) { c++; if (c == n) { print $(i + 1); exit } } }'; }
M=$OUT/measured.txt; : > $M
for a in $ARMS; do
  for m in $MASSES; do for dt in $STEPS $EXTRA; do
    l=$("$B" swing $OUT/$a/runs/struck_m${m}_$dt.txt | tail -1)
    echo "$a struck $m $dt deepest_urad $(echo "$l" | nth turn_urad 1) turned_back_urad $(echo "$l" | nth turn_urad 2)" >> $M
  done; done
  echo "$a bad_plays $(cat $OUT/$a/stats/*.txt | grep -c 'nan_at_step\|out_of_range_at_step')" >> $M
done
[ "${DRY:-0}" = 1 ] && { echo "dry run: $(wc -l < $M | tr -d ' ') measured lines"; cat $M; exit 0; }
tb() { grep "^$1 struck $2 $3 " $M | nth turned_back_urad 1; }
# ---- the rules
R=$OUT/rules.txt; : > $R
rule() { "$B" rule "$@" | tail -1 >> $R; }
n=0; same=0
for f in $(cd $OUT/stock/runs && ls *_0*.txt); do n=$((n + 1)); cmp -s $OUT/off/runs/$f $OUT/stock/runs/$f && same=$((same + 1)); done
rule R1_safe_when_off eq $same $n
rule R2_fault_there_03 all_ge -472600 $(for dt in $STEPS; do tb stock 0.3 $dt; done)
rule R2_fault_there_3 all_ge -182100 $(for dt in $STEPS; do tb stock 3 $dt; done)
rule R3_strike_03_lo all_ge -602600 $(for dt in $STEPS; do tb on 0.3 $dt; done)
rule R3_strike_03_hi all_le -542600 $(for dt in $STEPS; do tb on 0.3 $dt; done)
rule R3_strike_3_lo all_ge -312100 $(for dt in $STEPS; do tb on 3 $dt; done)
rule R3_strike_3_hi all_le -252100 $(for dt in $STEPS; do tb on 3 $dt; done)
n=0; same=0
for m in $MASSES; do for dt in $STEPS; do n=$((n + 1)); cmp -s $OUT/on/runs/free_m${m}_$dt.txt $OUT/stock/runs/free_m${m}_$dt.txt && same=$((same + 1)); done; done
rule R4_nothing_else eq $same $n
on_bad=$(cat $(for m in $MASSES; do for dt in $STEPS; do echo $OUT/on/stats/struck_m${m}_$dt.txt $OUT/on/stats/free_m${m}_$dt.txt; done; done) | grep -c 'nan_at_step\|out_of_range_at_step')
rule R5_no_blow_up eq $on_bad 0
echo "rules: $(wc -l < $R | tr -d ' '), held: $(grep -c ': HELD$' $R)" >> $R
cat $R
