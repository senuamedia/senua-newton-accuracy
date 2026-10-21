#!/usr/bin/env bash
# Run 085: XPBD's hold against its iteration count with the speed floor removed (Study 10's patch) and the friction
# patch in design on that tree (patches/in_design/xpbd_friction_total_on_nofloor.diff), a design probe with no prediction:
# run 044's hold at 2 and 0.5 ms, 8, 16, 32, 64 and 128 iterations, at XPBD's default contact relaxation and at 1,
# on Newton 1.7.0. Then measured.txt (sx_contact creep).
# usage: play.sh <sx_contact binary>   (repository root; FLOOR_VENV the floor patch's tree, XFR_VENV the stacked tree first)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"
O=validation/run_085_xpbd_hold_nofloor
HOLD="mass=1 radius=0.05 h0=0 pushat=0.5 secs=2 solver=xpbd mu=0.5 push=2.94"
plays() { local e dt it r; for e in stock on; do for dt in 0.002 0.0005; do for it in 8 16 32 64 128; do for r in default one; do
  o=""; [ $r = one ] && o=" opt.rigid_contact_relaxation=1"
  echo "hold_${e}_${r}_it${it}_$dt $e dt=$dt $HOLD iterations=$it$o"; done; done; done; done; }
mkdir -p $O/runs $O/stats; date -u +%FT%TZ > $O/started.txt
for g in stock on; do
  ( v=$FLOOR_VENV; [ $g = on ] && v=$XFR_VENV; . "$v/bin/activate"; export NEWTON_XPBD_NO_SPEED_FLOOR=1; unset NEWTON_XPBD_FRICTION_TOTAL; [ $g = on ] && export NEWTON_XPBD_FRICTION_TOTAL=1
    plays | awk -v g=$g '$2 == g { $2 = ""; print }' | xargs -P 2 -L 1 bash -c 'python tools/nwt_contact.py '"$O"'/runs/$0.txt "$@" > '"$O"'/stats/$0.txt 2> '"$O"'/runs/log_$0.txt' ) &
done
wait; date -u +%FT%TZ > $O/finished.txt
M=$O/measured.txt; : > $M
for n in $(plays | awk '{print $1}'); do echo "$n $("$B" creep $O/runs/$n.txt < /dev/null | tail -1)" >> $M; done
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
awk '{ for (i = 1; i < NF; i++) if ($i == "mean_speed_ums") print $1, $(i + 1) }' $M
