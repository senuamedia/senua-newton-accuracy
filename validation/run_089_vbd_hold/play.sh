#!/usr/bin/env bash
# Run 089: VBD's hold (issue 6's VBD part), a design probe that decides nothing and states no prediction: run 044's hold
# (1 kg, half-size 0.05 m, friction 0.5, 2.94 N from 0.5 s, 2 s) on VBD and VBD-ALM, as released and with Study 4's
# carried velocity (NEWTON_VBD_CARRIED_VELOCITY=2, Study 7's vbd environment), at 2, 0.5 and 0.125 ms, on Newton 1.7.0.
# usage: play.sh <sx_contact binary>   (repository root; STOCK_VENV and VBD_VENV Study 7's stock and vbd environments)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"
O=validation/run_089_vbd_hold
HOLD="mass=1 radius=0.05 h0=0 mu=0.5 push=2.94 pushat=0.5 secs=2"
plays() { local e s dt; for e in stock carried; do for s in vbd vbd_alm; do for dt in 0.002 0.0005 0.000125; do echo "hold_${s}_${e}_$dt $e dt=$dt $HOLD solver=$s"; done; done; done; }
mkdir -p $O/runs $O/stats; date -u +%FT%TZ > $O/started.txt
for g in stock carried; do
  ( v=$STOCK_VENV; [ $g = carried ] && v=$VBD_VENV; . "$v/bin/activate"; unset NEWTON_VBD_CARRIED_VELOCITY; [ $g = carried ] && export NEWTON_VBD_CARRIED_VELOCITY=2
    plays | awk -v g=$g '$2 == g { $2 = ""; print }' | xargs -P 2 -L 1 bash -c 'python tools/nwt_contact.py '"$O"'/runs/$0.txt "$@" > '"$O"'/stats/$0.txt 2> '"$O"'/runs/log_$0.txt' ) &
done
wait; date -u +%FT%TZ > $O/finished.txt
M=$O/measured.txt; : > $M
for n in $(plays | awk '{print $1}'); do echo "$n $("$B" creep $O/runs/$n.txt < /dev/null | tail -1)" >> $M; done
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
awk '{ for (i = 1; i < NF; i++) if ($i == "mean_speed_ums") print $1, $(i + 1) }' $M
