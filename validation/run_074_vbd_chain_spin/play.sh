#!/usr/bin/env bash
# Run 074: VBD's joint chain energy (issue 12, VBD's part) and VBD-ALM's spinning body (issue 13, its open part), a
# design probe that decides nothing and states no prediction: Study 9's free chain and spinning body on VBD and
# VBD-ALM, as released and with the carried-velocity patch (NEWTON_VBD_CARRIED_VELOCITY=2, Study 4's, rebased onto
# 1.7.0: Study 7's vbd environment), at 2, 0.5 and 0.125 ms, on Newton 1.7.0; then measured.txt (sx_contact).
# usage: play.sh <sx_contact binary>   (repository root; STOCK_VENV and VBD_VENV Study 7's stock and vbd environments)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"
O=validation/run_074_vbd_chain_spin
CHAIN="mass1=0.7 mass2=1.3 radius=0.04 arm1=0.25 len1=0.5 arm2=0.22 angle1=0 angle2=-0.4 omega1=2.2 omega2=-1.1 secs=2 gravity=0"
SPIN="mass=1.5 radius=0.04 h0=1 gravity=0 wz0=4 secs=2 comx=0.03"
plays() { local e s dt
  for e in stock carried; do for s in vbd vbd_alm; do for dt in 0.002 0.0005 0.000125; do
    echo "chain_${s}_${e}_$dt $e nwt_chain dt=$dt $CHAIN solver=$s"
    echo "spin_${s}_${e}_$dt $e nwt_contact dt=$dt $SPIN solver=$s"
  done; done; done; }
mkdir -p $O/runs $O/stats; date -u +%FT%TZ > $O/started.txt
for g in stock carried; do
  ( v=$STOCK_VENV; [ $g = carried ] && v=$VBD_VENV; . "$v/bin/activate"; unset NEWTON_VBD_CARRIED_VELOCITY
    [ $g = carried ] && export NEWTON_VBD_CARRIED_VELOCITY=2
    plays | awk -v g=$g '$2 == g { $2 = ""; print }' | xargs -P 4 -L 1 bash -c 'python tools/$1.py '"$O"'/runs/$0.txt "${@:2}" > '"$O"'/stats/$0.txt 2> '"$O"'/runs/log_$0.txt' ) &
done
wait; date -u +%FT%TZ > $O/finished.txt
M=$O/measured.txt; : > $M
for n in $(plays | awk '{print $1}'); do
  case $n in chain_*) l="$("$B" chain $O/runs/$n.txt < /dev/null | tail -1)";;
    spin_*) l="$("$B" creep $O/runs/$n.txt < /dev/null | tail -1) $("$B" stop $O/runs/$n.txt < /dev/null | tail -1)";; esac
  echo "$n $l" >> $M; done
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
awk '{ for (i = 1; i < NF; i++) if ($i == "kinetic_end_per_million_of_start" || $i == "mean_speed_ums" || $i == "largest_speed_last_third_ums") printf "%s %s %s  ", $1, $i, $(i + 1); print "" }' $M
