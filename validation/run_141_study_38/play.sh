#!/usr/bin/env bash
# Run 141: the thirty-eighth registered study (preregistrations/PREREGISTRATION_38.md), played once on Newton 1.7.0:
# XPBD's joints solved colour by colour (Senua AI's joint colours patch, NEWTON_XPBD_JOINT_COLOURS=1) at its own full
# relaxation options, at 8 and 32 iterations, issue 12. Each play into runs/, its error stream into runs/err_<play>.txt
# and its statistics into stats/, then the registered rules judged by sx_contact rule (rules.txt), the measured lines
# beside them (measured.txt). DRY=1 plays every play for 0.02 s, into dry/, to check that the runner runs to the end.
# usage: play.sh <sx_contact binary> <engine folder> [parallel plays]   (repository root)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary> <engine folder>}")" && pwd)/$(basename "$1")"; E="$(cd "${2:?}" && pwd)"; P=${3:-4}
O=validation/run_141_study_38
if [ "${DRY:-0}" = 1 ]; then OUT=$O/dry; SECS=0.02; else OUT=$O; SECS=2; fi
C="mass1=0.95 mass2=1.05 radius=0.04 arm1=0.23 len1=0.46 arm2=0.24 angle1=0 angle2=0.55 omega1=1.7 omega2=-1.3 gravity=0 secs=$SECS solver=xpbd"
G="mass1=1.2 mass2=0.7 radius=0.04 arm1=0.2 len1=0.42 arm2=0.21 angle1=0.35 angle2=0.6 omega1=0 omega2=0 gravity=1 secs=$SECS solver=xpbd"
J="mass=0.9 radius=0.035 arm=0.35 angle0=0 omega0=0 gravity=1 secs=$SECS solver=xpbd"
FULL="opt.joint_linear_relaxation=1.0 opt.joint_angular_relaxation=1.0"
CDT="0.0016 0.0008 0.0004 0.0002 0.0001"; GDT="0.0016 0.0004 0.0001"; JDT="0.001 0.00025"
plays() {  # <play> <engine: stock, off or on> <rig> <setting ...>
  local g dt it
  for g in stock off; do
    for dt in $CDT; do echo "c_${g}_def_$dt $g chain $C dt=$dt iterations=2"; done
    for it in 8 32; do echo "c_${g}_full_it${it}_0.0004 $g chain $C dt=0.0004 iterations=$it $FULL"; done
  done
  for it in 8 32; do for dt in $CDT; do echo "c_on_full_it${it}_$dt on chain $C dt=$dt iterations=$it $FULL"; done; done
  for g in stock on; do for dt in $JDT; do echo "j_${g}_$dt $g joint $J dt=$dt"; done; done
  for dt in $GDT; do echo "g_stock_def_$dt stock chain $G dt=$dt iterations=2"; echo "g_on_full_it32_$dt on chain $G dt=$dt iterations=32 $FULL"; done
}
mkdir -p $OUT/runs $OUT/stats; date -u +%FT%TZ > $OUT/started.txt
one() {  # <play> <engine> <rig> <setting ...>
  local n=$1 g=$2 r=$3; shift 3; local v=$E/col; [ $g = stock ] && v=$E/stock
  ( . "$v/bin/activate"; unset NEWTON_XPBD_JOINT_COLOURS; [ $g = on ] && export NEWTON_XPBD_JOINT_COLOURS=1
    python tools/nwt_$r.py $OUT/runs/$n.txt "$@" > $OUT/stats/$n.txt 2> $OUT/runs/err_$n.txt )
}
export -f one; export E OUT
plays | xargs -P $P -L 1 bash -c 'one "$@"' _
date -u +%FT%TZ > $OUT/finished.txt
grep -rlIF "$HOME" $OUT 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
pick() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
M=$OUT/measured.txt; : > $M
for n in $(plays | awk '{ print $1 }'); do st=$(pick nan_at_step < $OUT/stats/$n.txt); [ -n "$st" ] || st=$(pick out_of_range_at_step < $OUT/stats/$n.txt)
  case $n in j_*) m=swing;; *) m=chain;; esac
  echo "$n stops ${st:--1} $("$B" $m $OUT/runs/$n.txt < /dev/null | tail -1)" >> $M; done
[ "${DRY:-0}" = 1 ] && { echo "dry run: $(wc -l < $M | tr -d ' ') measured lines"; cat $M; exit 0; }
v() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $M; }
dep() { v "$1" energy_largest_drift_ppm; }
R=$OUT/rules.txt; : > $R
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $R; }
same=0; tot=0; for n in $(plays | awk '$2 == "stock" && $1 ~ /^c_/ { print $1 }'); do tot=$((tot + 1)); cmp -s $OUT/runs/$n.txt $OUT/runs/${n/_stock_/_off_}.txt && same=$((same + 1)); done
rule R1_safe_when_off eq $same $tot
k0=$(v c_stock_full_it8_0.0004 kinetic_start_nj)
rule R2_full_relaxation_diverges all_ge $((k0 * 10)) $(for it in 8 32; do v c_stock_full_it${it}_0.0004 kinetic_most_nj; done)
for it in 8 32; do rule R3_falls_with_the_step_it$it falls $(for dt in $CDT; do dep c_on_full_it${it}_$dt; done); done
for it in 8 32; do for dt in 0.0004 0.0002 0.0001; do rule R4_half_of_released_it${it}_$dt le $(dep c_on_full_it${it}_$dt) $(( $(dep c_stock_def_$dt) / 2 )); done; done
jsame=0; for dt in $JDT; do cmp -s $OUT/runs/j_stock_$dt.txt $OUT/runs/j_on_$dt.txt && jsame=$((jsame + 1)); done
rule R5_one_joint_unchanged eq $jsame 2
rule R6_numbers all_eq -1 $(plays | awk '{ print $1 }' | while read -r n; do v $n stops; done)
echo "rules: $(wc -l < $R | tr -d ' '), held: $(grep -c ': HELD$' $R)" >> $R
cat $R
