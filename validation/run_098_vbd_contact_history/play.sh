#!/usr/bin/env bash
# Run 098: VBD's hold with its contacts carried from step to step (issue 6's VBD part), a design probe whose predictions
# were pushed before the plays: Newton's own rigid_contact_history with the collision pipeline's contact matching
# (latest, sticky) on VBD-ALM and VBD, and VBD's legacy penalty ramp (rigid_avbd_beta=1e5, its documentation's
# example), on run 044's hold at 2, 0.5, 0.125 and 0.0625 ms and a slide, on Newton 1.7.0. The rig's matching option
# is new at this run; C0 checks it changes nothing when unset.
# usage: play.sh <sx_contact binary> [parallel plays]   (repository root; STOCK_VENV Newton 1.7.0)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"; P=${2:-4}
O=validation/run_098_vbd_contact_history
HOLD="mass=1 radius=0.05 h0=0 mu=0.5 push=2.94 pushat=0.5 secs=2"
SLIDE="mass=1 radius=0.05 h0=0 mu=0.5 vx0=1 secs=0.5"
HIST="opt.rigid_contact_history=true"
plays() { local dt; for dt in 0.002 0.0005 0.000125 0.0000625; do
  echo "hold_alm_cold_$dt dt=$dt $HOLD solver=vbd_alm"
  echo "hold_alm_latest_$dt dt=$dt $HOLD solver=vbd_alm $HIST matching=latest"
  echo "hold_alm_sticky_$dt dt=$dt $HOLD solver=vbd_alm $HIST matching=sticky"
  echo "hold_vbd_sticky_$dt dt=$dt $HOLD solver=vbd $HIST matching=sticky"
  echo "hold_vbd_ramp_$dt dt=$dt $HOLD solver=vbd opt.rigid_avbd_beta=100000"; done
  for dt in 0.002 0.0005 0.000125; do echo "slide_alm_cold_$dt dt=$dt $SLIDE solver=vbd_alm"
    echo "slide_alm_sticky_$dt dt=$dt $SLIDE solver=vbd_alm $HIST matching=sticky"; done
  echo "rig_check_0.0005 dt=0.0005 $HOLD solver=vbd_alm"; }
mkdir -p $O/runs $O/stats; date -u +%FT%TZ > $O/started.txt
( . "$STOCK_VENV/bin/activate"; plays | xargs -P $P -L 1 bash -c 'python tools/nwt_contact.py '"$O"'/runs/$0.txt "$@" > '"$O"'/stats/$0.txt 2> '"$O"'/runs/log_$0.txt' )
date -u +%FT%TZ > $O/finished.txt
pick_s() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
M=$O/measured.txt; : > $M
for n in $(plays | awk '{print $1}'); do st=$(pick_s nan_at_step < $O/stats/$n.txt); [ -n "$st" ] || st=$(pick_s out_of_range_at_step < $O/stats/$n.txt)
  case $n in slide_*) r=stop;; *) r=creep;; esac; echo "$n stops ${st:--1} $("$B" $r $O/runs/$n.txt < /dev/null | tail -1)" >> $M; done
v() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $M; }
C=$O/checks.txt; : > $C
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $C; }
s=0; cmp -s $O/runs/rig_check_0.0005.txt validation/run_091_vbd_alm_hold_steps/runs/hold_itdefault_0.0005.txt && s=1
rule C0_rig_unchanged eq $s 1
rule C1_alm_sticky_held all_in -10 10 $(for dt in 0.002 0.0005 0.000125 0.0000625; do v hold_alm_sticky_$dt mean_speed_ums; done)
rule C2_alm_sticky_slide_coulomb all_within 102041 100 $(for dt in 0.002 0.0005 0.000125; do v slide_alm_sticky_$dt slid_um; done)
echo "checks: $(wc -l < $C | tr -d ' '), held: $(grep -c ': HELD$' $C)" >> $C
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
cat $C
