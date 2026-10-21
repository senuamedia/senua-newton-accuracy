#!/usr/bin/env bash
# Run 121: VBD's free chain 10 m from the world's origin with Senua AI's VBD displacement patch
# (patches/newton-1.7.0/vbd_displacement.diff, NEWTON_VBD_DISPLACEMENT=1), at VBD's defaults and with four of its own
# joint options (its compliant ALM path; the persisted multiplier not carried, rigid_avbd_gamma=0; the C0 stabilization
# off and full, rigid_avbd_joint_alpha=0 and 1), beside the chain at the origin, at 0.375 and 0.09375 ms, on Newton
# 1.7.0: Study 22's chain, where 10 m out at the smallest step the patch left a floor (R5). A design probe whose
# predictions were pushed before the plays. Then measured.txt and checks.txt.
# usage: play.sh <sx_contact binary> <engine folder> [parallel plays]   (repository root; the engine folder made by run
#   114's setup_engine.sh, its on/ the patched tree)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary> <engine folder>}")" && pwd)/$(basename "$1")"; E="$(cd "${2:?}" && pwd)"; P=${3:-4}
O=validation/run_121_vbd_far_joint_options
CHAIN="mass1=1.0 mass2=0.8 radius=0.04 arm1=0.22 len1=0.45 arm2=0.2 angle1=0 angle2=0.5 omega1=1.9 omega2=-0.9 gravity=0 secs=2"
cfg() { case $1 in default) echo "";; alm) echo " opt.rigid_compliant_alm=true";; gamma0) echo " opt.rigid_avbd_gamma=0";;
  alpha0) echo " opt.rigid_avbd_joint_alpha=0";; alpha1) echo " opt.rigid_avbd_joint_alpha=1";; esac; }
plays() { local c x dt; for c in default alm gamma0 alpha0 alpha1; do for x in 0 10; do for dt in 0.000375 0.00009375; do
  xs=""; [ $x = 0 ] || xs=" x0=$x"; echo "c_${c}_x${x}_$dt dt=$dt $CHAIN solver=vbd$xs$(cfg $c)"; done; done; done; }
mkdir -p $O/runs $O/stats; date -u +%FT%TZ > $O/started.txt
( . "$E/on/bin/activate"; export NEWTON_VBD_DISPLACEMENT=1
  plays | xargs -P $P -L 1 bash -c 'python tools/nwt_chain.py '"$O"'/runs/$0.txt "$@" > '"$O"'/stats/$0.txt 2> '"$O"'/runs/err_$0.txt' )
date -u +%FT%TZ > $O/finished.txt
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
pick() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
M=$O/measured.txt; : > $M
for n in $(plays | awk '{ print $1 }'); do st=$(pick nan_at_step < $O/stats/$n.txt); [ -n "$st" ] || st=$(pick out_of_range_at_step < $O/stats/$n.txt)
  l="$("$B" chain $O/runs/$n.txt < /dev/null | tail -1)"
  echo "$n stops ${st:--1} energy_largest_drift_ppm $(echo "$l" | pick energy_largest_drift_ppm)" >> $M; done
v() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $M; }
L() { v $1 energy_largest_drift_ppm; }
C=$O/checks.txt; : > $C
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $C; }
rule C0_numbers all_eq -1 $(plays | awk '{ print $1 }' | while read -r n; do v $n stops; done)
rule C0_as_study_22 eq 4 $(k=0; for x in 0 10; do for dt in 0.000375 0.00009375; do cmp -s $O/runs/c_default_x${x}_$dt.txt validation/run_114_study_22/runs/c_vbd_on_x${x}_$dt.txt && k=$((k + 1)); done; done; echo $k)
rule P1_default_floor ge $(L c_default_x10_0.00009375) $(( 2 * $(L c_default_x0_0.00009375) ))
for c in alm gamma0 alpha0 alpha1; do rule P2_${c}_10m_as_the_origin all_within $(L c_${c}_x0_0.00009375) 3 $(L c_${c}_x10_0.00009375); done
echo "checks: $(wc -l < $C | tr -d ' '), held: $(grep -c ': HELD$' $C)" >> $C
cat $C $M
