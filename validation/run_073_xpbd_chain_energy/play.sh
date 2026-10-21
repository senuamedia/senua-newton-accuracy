#!/usr/bin/env bash
# Run 073: where XPBD's joint chain loses its energy (issue 12, XPBD's part), a design probe that decides nothing and
# states no prediction: Study 9's free chain on XPBD as released, with #4317, with #4318, each with the speed-floor
# patch, at its default and at equal relaxations of 1, at 2, 8 and 32 iterations, at 2, 0.5 and 0.125 ms, on Newton
# 1.7.0; then measured.txt (sx_contact chain).
# usage: play.sh <sx_contact binary> <engine folder>   (repository root; the engine folder made by run 065's setup_engine.sh)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary> <engine folder>}")" && pwd)/$(basename "$1")"; E="$(cd "${2:?}" && pwd)"
O=validation/run_073_xpbd_chain_energy
CHAIN="mass1=0.7 mass2=1.3 radius=0.04 arm1=0.25 len1=0.5 arm2=0.22 angle1=0 angle2=-0.4 omega1=2.2 omega2=-1.1 secs=2 gravity=0 solver=xpbd"
plays() { local e dt it rx
  for e in stock 4317on 4318on; do for dt in 0.002 0.0005 0.000125; do for it in 2 8 32; do for rx in default one; do
    o=""; [ $rx = one ] && o="opt.joint_linear_relaxation=1 opt.joint_angular_relaxation=1"
    echo "chain_${e}_${rx}_it${it}_$dt $e dt=$dt $CHAIN iterations=$it $o"
  done; done; done; done; }
mkdir -p $O/runs $O/stats; date -u +%FT%TZ > $O/started.txt
for g in stock 4317on 4318on; do
  ( case $g in stock) v=$E/stock;; 4317on) v=$E/pr4317_nofloor;; 4318on) v=$E/pr4318_nofloor;; esac
    . "$v/bin/activate"; unset NEWTON_XPBD_NO_SPEED_FLOOR; [ $g != stock ] && export NEWTON_XPBD_NO_SPEED_FLOOR=1
    plays | awk -v g=$g '$2 == g { $2 = ""; print }' | xargs -P 3 -L 1 bash -c 'python tools/nwt_chain.py '"$O"'/runs/$0.txt "$@" > '"$O"'/stats/$0.txt 2> '"$O"'/runs/log_$0.txt' ) &
done
wait; date -u +%FT%TZ > $O/finished.txt
M=$O/measured.txt; : > $M
for n in $(plays | awk '{print $1}'); do echo "$n $("$B" chain $O/runs/$n.txt < /dev/null | tail -1)" >> $M; done
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
awk '{ for (i = 1; i < NF; i++) if ($i == "kinetic_end_per_million_of_start") print $1, $(i + 1) }' $M
