#!/usr/bin/env bash
# Run 111: Senua AI's VBD displacement patch in design (patches/in_design/vbd_displacement_on_1.7.0.diff,
# NEWTON_VBD_DISPLACEMENT=1: each rigid body's displacement from its inertial target kept apart from its 32-bit pose, the
# velocity the forward step's plus it over the step, as pull request #4721 proposes), on run 074's spinning body (issue
# 13), Study 9's free chain (issue 12's VBD part), and run 044's hold (cold and with Study 17's contact history) and a
# slide on VBD and VBD-ALM, on Newton 1.7.0. The README's predictions were pushed before these plays. Then measured.txt
# and checks.txt.
# usage: play.sh <sx_contact binary> [parallel plays]   (repository root; STOCK_VENV Newton 1.7.0, DISP_VENV the patch's
#   tree first on the path)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"; P=${2:-4}
O=validation/run_111_vbd_displacement
SPIN="mass=1.5 radius=0.04 h0=1 gravity=0 wz0=4 secs=2 comx=0.03"
CHAIN="mass1=0.7 mass2=1.3 radius=0.04 arm1=0.25 len1=0.5 arm2=0.22 angle1=0 angle2=-0.4 omega1=2.2 omega2=-1.1 secs=2 gravity=0"
HOLD="mass=1 radius=0.05 h0=0 mu=0.5 push=2.94 pushat=0.5 secs=2"; SLIDE="mass=1 radius=0.05 h0=0 mu=0.5 vx0=1 secs=0.5"
plays() { local e s dt; for e in stock off on; do
  for s in vbd vbd_alm; do for dt in 0.002 0.0005 0.000125 0.0000625; do echo "spin_${s}_${e}_$dt $e nwt_contact dt=$dt $SPIN solver=$s"; done; done
  for dt in 0.002 0.0005 0.000125; do echo "chain_vbd_${e}_$dt $e nwt_chain dt=$dt $CHAIN solver=vbd"; done
  for dt in 0.002 0.000125; do echo "hold_alm_${e}_$dt $e nwt_contact dt=$dt $HOLD solver=vbd_alm"
    echo "holdc_alm_${e}_$dt $e nwt_contact dt=$dt $HOLD solver=vbd_alm opt.rigid_contact_history=true matching=sticky"
    echo "slide_alm_${e}_$dt $e nwt_contact dt=$dt $SLIDE solver=vbd_alm"; done; done; }
mkdir -p $O/runs $O/stats; date -u +%FT%TZ > $O/started.txt
for g in stock off on; do
  ( v=$DISP_VENV; [ $g = stock ] && v=$STOCK_VENV; . "$v/bin/activate"; unset NEWTON_VBD_DISPLACEMENT; [ $g = on ] && export NEWTON_VBD_DISPLACEMENT=1
    plays | awk -v g=$g '$2 == g { $2 = ""; print }' | xargs -P $P -L 1 bash -c 'python tools/$1.py '"$O"'/runs/$0.txt "${@:2}" > '"$O"'/stats/$0.txt 2> '"$O"'/runs/log_$0.txt' ) &
done
wait; date -u +%FT%TZ > $O/finished.txt
pick() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
M=$O/measured.txt; : > $M
for n in $(plays | awk '{print $1}'); do st=$(pick nan_at_step < $O/stats/$n.txt); [ -n "$st" ] || st=$(pick out_of_range_at_step < $O/stats/$n.txt)
  case $n in chain_*) l="$("$B" chain $O/runs/$n.txt < /dev/null | tail -1)"; l="energy_drift_ppm $(echo "$l" | pick energy_drift_ppm_of_most_kinetic) momentum_drift_ppm $(echo "$l" | pick momentum_drift_ppm)";;
    slide_*) l="$("$B" stop $O/runs/$n.txt < /dev/null | tail -1)";; *) l="$("$B" creep $O/runs/$n.txt < /dev/null | tail -1)";; esac
  echo "$n stops ${st:--1} $l" >> $M; done
v() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $M; }
C=$O/checks.txt; : > $C
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $C; }
s=0; t=0; for n in $(plays | awk '$2 == "stock" { print $1 }'); do t=$((t + 1)); cmp -s $O/runs/$n.txt $O/runs/${n/_stock_/_off_}.txt && s=$((s + 1)); done
rule C0_safe_when_off eq $s $t
rule C0_numbers all_eq -1 $(plays | awk '$2 == "on" { print $1 }' | while read -r n; do v $n stops; done)
rule C1_spin_still all_in -3 3 $(for s in vbd vbd_alm; do for dt in 0.002 0.0005 0.000125 0.0000625; do v spin_${s}_on_$dt mean_speed_ums; done; done)
rule C2_chain_no_worse_as_the_step_shrinks all_ge 0 $(a=$(v chain_vbd_on_0.002 energy_drift_ppm); b=$(v chain_vbd_on_0.0005 energy_drift_ppm); c=$(v chain_vbd_on_0.000125 energy_drift_ppm); echo $(( ${a#-} - ${b#-} )) $(( ${b#-} - ${c#-} )))
rule C3_hold_carried_still all_in -10 10 $(for dt in 0.002 0.000125; do v holdc_alm_on_$dt mean_speed_ums; done)
rule C3_slide_kept all_within $(v slide_alm_stock_0.002 slid_um) 100 $(v slide_alm_on_0.002 slid_um)
echo "checks: $(wc -l < $C | tr -d ' '), held: $(grep -c ': HELD$' $C)" >> $C
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
cat $C
