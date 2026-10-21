#!/usr/bin/env bash
# Run 123: Senua AI's MuJoCo Warp noslip patch in design (patches/in_design/mujoco_warp_noslip_on_3.15.0.diff: MuJoCo's
# noslip solver after MuJoCo Warp's main solve) with the record's Newton noslip patch, on Study 11's hold, slide and drop
# on the MuJoCo solver's Warp path, beside its CPU path (MuJoCo's C engine, Study 11's fix), elliptic and pyramidal, at
# 1 and 4 ms, on Newton 1.7.0. A design probe whose predictions were pushed before the plays. Then measured.txt and
# checks.txt.
# usage: play.sh <sx_contact binary> <engine folder> [parallel plays]   (repository root; the engine folder made by this
#   run's setup_engine.sh)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary> <engine folder>}")" && pwd)/$(basename "$1")"; E="$(cd "${2:?}" && pwd)"; P=${3:-4}
O=validation/run_123_mujoco_warp_noslip
HOLD="mass=1.5 radius=0.04 h0=0 mu=0.6 push=6.174 pushat=0.4 secs=1.6 solver=mujoco"
SLIDE="mass=1.5 radius=0.04 h0=0 mu=0.6 vx0=0.8 secs=1 solver=mujoco"
DROP="mass=0.8 radius=0.03 h0=0.05 mu=0.3 secs=1 solver=mujoco"
CPU="opt.use_mujoco_cpu=true"; NS="opt.noslip_iterations=5"
plays() { local dt c; for dt in 0.001 0.004; do
  echo "hold_stock_$dt stock dt=$dt $HOLD opt.cone=elliptic"
  echo "hold_off_$dt on dt=$dt $HOLD opt.cone=elliptic"
  echo "slide_stock_$dt stock dt=$dt $SLIDE opt.cone=elliptic"
  echo "slide_off_$dt on dt=$dt $SLIDE opt.cone=elliptic"
  echo "drop_stock_$dt stock dt=$dt $DROP opt.cone=elliptic"
  echo "drop_off_$dt on dt=$dt $DROP opt.cone=elliptic"
  for c in elliptic pyramidal; do
    echo "hold_warp_${c}_$dt on dt=$dt $HOLD opt.cone=$c $NS"; echo "hold_cpu_${c}_$dt on dt=$dt $HOLD opt.cone=$c $NS $CPU"
    echo "slide_warp_${c}_$dt on dt=$dt $SLIDE opt.cone=$c $NS"; echo "slide_cpu_${c}_$dt on dt=$dt $SLIDE opt.cone=$c $NS $CPU"
    echo "drop_warp_${c}_$dt on dt=$dt $DROP opt.cone=$c $NS"; echo "drop_cpu_${c}_$dt on dt=$dt $DROP opt.cone=$c $NS $CPU"; done; done; }
mkdir -p $O/runs $O/stats; date -u +%FT%TZ > $O/started.txt
for g in stock on; do
  ( . "$E/$g/bin/activate"
    plays | awk -v g=$g '$2 == g { $2 = ""; print }' | xargs -P $P -L 1 bash -c 'python tools/nwt_contact.py '"$O"'/runs/$0.txt "$@" > '"$O"'/stats/$0.txt 2> '"$O"'/runs/err_$0.txt' ) &
done
wait; date -u +%FT%TZ > $O/finished.txt
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
pick() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
M=$O/measured.txt; : > $M
for n in $(plays | awk '{ print $1 }'); do st=$(pick nan_at_step < $O/stats/$n.txt)
  case $n in hold*) m=creep;; slide*) m=stop;; *) m=rest;; esac
  echo "$n stops ${st:--1} $("$B" $m $O/runs/$n.txt < /dev/null | tail -1)" >> $M; done
v() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $M; }
C=$O/checks.txt; : > $C
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $C; }
rule C0_numbers all_eq -1 $(plays | awk '{ print $1 }' | while read -r n; do v $n stops; done)
same=0; tot=0; for n in $(plays | awk '$2 == "stock" { print $1 }'); do tot=$((tot + 1)); cmp -s $O/runs/$n.txt $O/runs/${n/_stock_/_off_}.txt && same=$((same + 1)); done
rule P1_safe_when_off eq $same $tot
rule P2_warp_creeps_as_released all_ge 100 $(for dt in 0.001 0.004; do s=$(v hold_stock_$dt mean_speed_ums); echo ${s#-}; done)
rule P3_warp_held_with_noslip all_in -10 10 $(for dt in 0.001 0.004; do v hold_warp_elliptic_$dt mean_speed_ums; done)
for dt in 0.001 0.004; do
  rule P4_hold_as_cpu_$dt near $(v hold_warp_elliptic_$dt mean_speed_ums) $(v hold_cpu_elliptic_$dt mean_speed_ums) 10
  rule P4_slide_as_cpu_$dt within $(v slide_warp_elliptic_$dt slid_um) $(v slide_cpu_elliptic_$dt slid_um) 100
  rule P4_weight_as_cpu_$dt within $(v drop_warp_elliptic_$dt mean_ground_force_mN) $(v drop_cpu_elliptic_$dt mean_ground_force_mN) 100; done
echo "checks: $(wc -l < $C | tr -d ' '), held: $(grep -c ': HELD$' $C)" >> $C
cat $C $M
