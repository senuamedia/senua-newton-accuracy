#!/usr/bin/env bash
# Run 104: VBD's spinning body against its iterations (issue 13), a design probe that decides nothing and states no
# prediction: run 074's spinning body (touching nothing) on VBD and VBD-ALM, as released and with the carried velocity
# (NEWTON_VBD_CARRIED_VELOCITY=2, Study 4's patch rebased onto 1.7.0), at 1, 10 (the default) and 40 iterations, at 2,
# 0.5 and 0.125 ms, on Newton 1.7.0: does the centre's drift come from the solve's pose updates? Then measured.txt.
# usage: play.sh <sx_contact binary> [parallel plays]   (repository root; STOCK_VENV and VBD_VENV Study 7's stock and
#   vbd environments)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"; P=${2:-4}
O=validation/run_104_vbd_spin_iterations
SPIN="mass=1.5 radius=0.04 h0=1 gravity=0 wz0=4 secs=2 comx=0.03"
plays() { local e s it dt; for e in stock carried; do for s in vbd vbd_alm; do for it in 1 10 40; do for dt in 0.002 0.0005 0.000125; do
  echo "spin_${s}_${e}_it${it}_$dt $e dt=$dt $SPIN solver=$s iterations=$it"; done; done; done; done; }
mkdir -p $O/runs $O/stats; date -u +%FT%TZ > $O/started.txt
for g in stock carried; do
  ( v=$STOCK_VENV; [ $g = carried ] && v=$VBD_VENV; . "$v/bin/activate"; unset NEWTON_VBD_CARRIED_VELOCITY
    [ $g = carried ] && export NEWTON_VBD_CARRIED_VELOCITY=2
    plays | awk -v g=$g '$2 == g { $2 = ""; print }' | xargs -P $P -L 1 bash -c 'python tools/nwt_contact.py '"$O"'/runs/$0.txt "$@" > '"$O"'/stats/$0.txt 2> '"$O"'/runs/log_$0.txt' ) &
done
wait; date -u +%FT%TZ > $O/finished.txt
M=$O/measured.txt; : > $M
for n in $(plays | awk '{print $1}'); do echo "$n $("$B" creep $O/runs/$n.txt < /dev/null | tail -1)" >> $M; done
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
awk '{ for (i = 1; i < NF; i++) if ($i == "mean_speed_ums") print $1, $(i + 1) }' $M
