#!/usr/bin/env bash
# Run 091: VBD-ALM's hold against the step (issue 6's VBD part), a design probe that decides nothing and states no
# prediction: run 044's hold on VBD-ALM (rigid_compliant_alm, the contact path Newton names VBD's coming default), as
# released, at 4, 2, 1, 0.5, 0.25, 0.125 and 0.0625 ms, and at 1 and 4 times its default iterations, on Newton 1.7.0.
# usage: play.sh <sx_contact binary>   (repository root; STOCK_VENV Newton 1.7.0)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"
O=validation/run_091_vbd_alm_hold_steps
HOLD="mass=1 radius=0.05 h0=0 mu=0.5 push=2.94 pushat=0.5 secs=2 solver=vbd_alm"
plays() { local dt it; for dt in 0.004 0.002 0.001 0.0005 0.00025 0.000125 0.0000625; do for it in default 40; do
  o=""; [ $it = 40 ] && o=" iterations=40"; echo "hold_it${it}_$dt dt=$dt $HOLD$o"; done; done; }
mkdir -p $O/runs $O/stats; date -u +%FT%TZ > $O/started.txt
( . "$STOCK_VENV/bin/activate"; plays | xargs -P 4 -L 1 bash -c 'python tools/nwt_contact.py '"$O"'/runs/$0.txt "$@" > '"$O"'/stats/$0.txt 2> '"$O"'/runs/log_$0.txt' )
date -u +%FT%TZ > $O/finished.txt
M=$O/measured.txt; : > $M
for n in $(plays | awk '{print $1}'); do echo "$n $("$B" creep $O/runs/$n.txt < /dev/null | tail -1)" >> $M; done
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
awk '{ for (i = 1; i < NF; i++) if ($i == "mean_speed_ums") print $1, $(i + 1) }' $M
