#!/usr/bin/env bash
# Run 110: the twenty-first registered study (preregistrations/PREREGISTRATION_21.md), played once on Newton 1.7.0:
# nothing a solver ignores goes unsaid (issue 19), by Senua AI's joint-feature warnings patch on pull request #3552, and
# SemiImplicit plays a loop-closing joint with Newton's own joint_attach_kd=0. Each play into runs/, its error stream
# into runs/err_<play>.txt and its statistics into stats/, then the registered rules judged by sx_contact rule
# (rules.txt), the measured lines beside them (measured.txt). DRY=1 plays one throwaway play of each scene and setting,
# into dry/, to check that the runner runs to the end.
# usage: play.sh <sx_contact binary> <engine folder>   (repository root)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary> <engine folder>}")" && pwd)/$(basename "$1")"; E="$(cd "${2:?}" && pwd)"
O=validation/run_110_study_21
J="mass=0.8 radius=0.04 arm=0.3 drivek=40 drived=4 target=0.7 gravity=0"
L="mass=1.3 radius=0.045 arm=0.4 drivek=60 drived=6 target=0.45 lo=-0.9 hi=0.9"
if [ "${DRY:-0}" = 1 ]; then OUT=$O/dry; JS=0.02; LS=0.02; JDT=0.0001; LDT=0.0001; else OUT=$O; JS=0.3; LS=1.2; JDT=0.00005; LDT=0.00005; fi
SOLVERS="featherstone semi xpbd vbd mujoco"
kd() { [ $1 = semi ] && echo " opt.joint_attach_kd=0"; }  # SemiImplicit with its joint damper off (issue 10, Study 9)
plays() { local s e; for s in $SOLVERS; do for e in stock off on; do echo "j_${s}_$e $e nwt_joint dt=$JDT $J vlimit=1.5 elimit=0.6 secs=$JS solver=$s$(kd $s)"; done
    echo "p_${s}_on on nwt_joint dt=$JDT $J secs=$JS solver=$s$(kd $s)"; done
  for s in featherstone mujoco; do for e in stock on; do echo "l_${s}_$e $e nwt_loop dt=$LDT $L secs=$LS solver=$s"; done; done
  echo "l_semi_on on nwt_loop dt=$LDT $L secs=$LS solver=semi opt.joint_attach_kd=0"; }
mkdir -p $OUT/runs $OUT/stats; date -u +%FT%TZ > $OUT/started.txt
for g in stock off on; do
  ( v=$E/on; [ $g = stock ] && v=$E/stock; . "$v/bin/activate"; unset NEWTON_WARN_IGNORED_JOINT_FEATURES; [ $g = on ] && export NEWTON_WARN_IGNORED_JOINT_FEATURES=1
    plays | awk -v g=$g '$2 == g { $2 = ""; print }' | xargs -P 2 -L 1 bash -c 'python tools/$1.py '"$OUT"'/runs/$0.txt "${@:2}" > '"$OUT"'/stats/$0.txt 2> '"$OUT"'/runs/err_$0.txt' ) &
done
wait; date -u +%FT%TZ > $OUT/finished.txt
grep -rlIF "$HOME" $OUT 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
nan() { awk '{ for (i = 1; i < NF; i++) if ($i == "nan_at_step" || $i == "out_of_range_at_step") { print $(i + 1); exit } }' $1; }
has() { grep -c -- "$2" $OUT/runs/err_$1.txt | awk '{ print ($1 > 0) ? 1 : 0 }'; }
M=$OUT/measured.txt; : > $M
for n in $(plays | awk '{ print $1 }'); do s=$(nan $OUT/stats/$n.txt)
  echo "$n stops ${s:--1} senua_warnings $(grep -c 'does not apply these joint features' $OUT/runs/err_$n.txt) pr3552_warnings $(grep -c 'configured joint properties' $OUT/runs/err_$n.txt) $("$B" final $OUT/runs/$n.txt < /dev/null | tail -1)" >> $M; done
[ "${DRY:-0}" = 1 ] && { echo "dry run: $(wc -l < $M | tr -d ' ') measured lines"; cat $M; exit 0; }
v() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $M; }
R=$OUT/rules.txt; : > $R
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $R; }
named=0; for s in $SOLVERS; do named=$((named + $(has j_${s}_on 'does not apply these joint features.*velocity limit'))); done
for s in featherstone semi xpbd vbd; do named=$((named + $(has j_${s}_on 'does not apply these joint features.*effort limit'))); done
named=$((named + $(has l_featherstone_on 'loop-closing joints'))); named=$((named + $(has l_mujoco_on 'configured joint properties.*limits'))); named=$((named + $(has l_mujoco_on 'configured joint properties.*drive')))
rule R1_named eq $named 12
quiet=0; for s in $SOLVERS; do quiet=$((quiet + $(v p_${s}_on senua_warnings) + $(v p_${s}_on pr3552_warnings))); done
rule R2_nothing_where_nothing_is_ignored eq $quiet 0
off=0; for s in $SOLVERS; do off=$((off + $(v j_${s}_off senua_warnings))); done
rule R3_off_says_nothing_new eq $off 0
same=0; tot=0; for s in $SOLVERS; do for e in off on; do tot=$((tot + 1)); cmp -s $OUT/runs/j_${s}_$e.txt $OUT/runs/j_${s}_stock.txt && same=$((same + 1)); done; done
for s in featherstone mujoco; do tot=$((tot + 1)); cmp -s $OUT/runs/l_${s}_on.txt $OUT/runs/l_${s}_stock.txt && same=$((same + 1)); done
rule R4_nothing_else_changes eq $same $tot
rule R5_semi_loop_a_number all_eq -1 $(v l_semi_on stops)
rule R5_semi_loop_at_target near $(v l_semi_on angle_urad) 450000 1000
rule R5_semi_loop_at_rest in $(v l_semi_on speed_urads) -10000 10000
echo "rules: $(wc -l < $R | tr -d ' '), held: $(grep -c ': HELD$' $R)" >> $R
cat $R
