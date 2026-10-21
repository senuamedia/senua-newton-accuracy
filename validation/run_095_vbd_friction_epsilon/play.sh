#!/usr/bin/env bash
# Run 095: VBD's hold against its own friction_epsilon (issue 6's VBD part), a design probe whose prediction, IPC's
# friction law worked for run 044's hold, was pushed before the plays: VBD and VBD-ALM at friction_epsilon 1e-2 (its
# default), 1e-3, 1e-4 and 1e-5, at 2, 0.5 and 0.125 ms, at the default iterations and at 40, on Newton 1.7.0.
# usage: play.sh <sx_contact binary> [parallel plays]   (repository root; STOCK_VENV Newton 1.7.0)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"; P=${2:-4}
O=validation/run_095_vbd_friction_epsilon
HOLD="mass=1 radius=0.05 h0=0 mu=0.5 push=2.94 pushat=0.5 secs=2"
plays() { local s e dt it; for s in vbd vbd_alm; do for e in 1e-2 1e-3 1e-4 1e-5; do for dt in 0.002 0.0005 0.000125; do for it in default 40; do
  o=""; [ $it = 40 ] && o=" iterations=40"; echo "hold_${s}_eps${e}_it${it}_$dt dt=$dt $HOLD solver=$s opt.friction_epsilon=$e$o"; done; done; done; done; }
mkdir -p $O/runs $O/stats; date -u +%FT%TZ > $O/started.txt
( . "$STOCK_VENV/bin/activate"; plays | xargs -P $P -L 1 bash -c 'python tools/nwt_contact.py '"$O"'/runs/$0.txt "$@" > '"$O"'/stats/$0.txt 2> '"$O"'/runs/log_$0.txt' )
date -u +%FT%TZ > $O/finished.txt
pick_s() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
M=$O/measured.txt; : > $M
for n in $(plays | awk '{print $1}'); do st=$(pick_s nan_at_step < $O/stats/$n.txt); [ -n "$st" ] || st=$(pick_s out_of_range_at_step < $O/stats/$n.txt)
  echo "$n stops ${st:--1} $("$B" creep $O/runs/$n.txt < /dev/null | tail -1)" >> $M; done
v() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $M; }
C=$O/checks.txt; : > $C
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $C; }
# IPC's law for the hold: the push 0.6 of the limit is met at a slip y eps_u a step, 2y - y^2 = 0.6, y = 0.3675; the
# creep is y friction_epsilon, 3,675 um/s at 1e-2, judged within 1 in 10 (rounded outward), at 40 iterations
for e in 1e-2 1e-3 1e-4 1e-5; do case $e in 1e-2) lo=3307; hi=4043;; 1e-3) lo=330; hi=405;; 1e-4) lo=33; hi=41;; 1e-5) lo=3; hi=5;; esac
  for s in vbd; do rule C1_ipc_creep_${s}_eps$e all_in $lo $hi $(for dt in 0.002 0.0005 0.000125; do v hold_${s}_eps${e}_it40_$dt mean_speed_ums; done); done; done
echo "checks: $(wc -l < $C | tr -d ' '), held: $(grep -c ': HELD$' $C)" >> $C
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
cat $C
