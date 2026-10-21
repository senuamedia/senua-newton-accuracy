#!/usr/bin/env bash
# Run 105: the right answer for a chain struck against a hard joint limit, and XPBD against it (issue 8), a design
# probe whose predictions were pushed before the plays. Run 061's chain (two links turning at 2 rad/s about the first
# joint, its limits -1 and 3.3 rad, no gravity, 2.5 s) on MuJoCo's own C engine (tools/mjc_limit_chain.py) with its
# limit ever stiffer and critically damped (solreflimit time constants 2, 0.5 and 0.2 ms, the step a twentieth of it,
# RK4, solimplimit 0.99 0.999), converging on a hard limit struck without a rebound; then XPBD as released and with the
# joint-angle patch's fourth form (NEWTON_XPBD_JOINT_ANGLE_UNWRAP=4) at 2.5, 0.625 and 0.156 ms, Newton's defaults.
# Then measured.txt (each play's joints at fixed instants, read from its file) and checks.txt.
# usage: play.sh <sx_contact binary>   (repository root; STOCK_VENV Newton 1.7.0, V4_VENV the patch's tree)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"
O=validation/run_105_xpbd_limit_chain_reference
CH="mass1=1.2 mass2=0.6 radius=0.04 arm1=0.25 len1=0.5 arm2=0.2 gravity=0 angle1=0 angle2=0 omega1=2 omega2=0 secs=2.5 lo1=-1 hi1=3.3"
TS="1.7 1.8 2.0 2.1 2.2 2.3 2.5"
mkdir -p $O/runs $O/stats; date -u +%FT%TZ > $O/started.txt
( . "$STOCK_VENV/bin/activate"
  for tc in 0.002 0.0005 0.0002; do dt=$(awk -v t=$tc 'BEGIN { printf "%.10g", t / 20 }')
    ev=$(awk -v t=$tc 'BEGIN { printf "%d", 0.0001 / (t / 20) + 0.5 }'); python tools/mjc_limit_chain.py $O/runs/ref_$tc.txt dt=$dt $CH timeconst=$tc imp0=0.99 imp1=0.999 every=$ev > $O/stats/ref_$tc.txt 2> $O/runs/log_ref_$tc.txt & done
  for dt in 0.0025 0.000625 0.00015625; do python tools/nwt_chain.py $O/runs/xpbd_stock_$dt.txt dt=$dt $CH solver=xpbd > $O/stats/xpbd_stock_$dt.txt 2> $O/runs/log_xpbd_stock_$dt.txt; done
  wait )
( . "$V4_VENV/bin/activate"; export NEWTON_XPBD_JOINT_ANGLE_UNWRAP=4
  for dt in 0.0025 0.000625 0.00015625; do python tools/nwt_chain.py $O/runs/xpbd_v4_$dt.txt dt=$dt $CH solver=xpbd > $O/stats/xpbd_v4_$dt.txt 2> $O/runs/log_xpbd_v4_$dt.txt & done; wait )
date -u +%FT%TZ > $O/finished.txt
# a play's joints at the instant t: the line of the step that ends at t (step index t/dt - 1), its four joint columns
at() { awk -v t=$2 '$1 == "CHAIN" { for (i = 2; i < NF; i++) if ($i == "dt_ns") dt = $(i + 1) / 1e9; next }
  dt > 0 && $1 == sprintf("%d", t / dt - 1 + 0.5) - 0 { print "j1_urad", $2, "j1_urads", $3, "j2_urad", $4, "j2_urads", $5; exit }' $1; }
M=$O/measured.txt; : > $M
for f in $(cd $O/runs && ls ref_*.txt xpbd_*.txt); do n=${f%.txt}; st=$(awk '{ for (i = 1; i < NF; i++) if ($i == "nan_at_step") print $(i + 1) }' $O/stats/$n.txt)
  for t in $TS; do echo "$n t $t stops ${st:--1} $(at $O/runs/$f $t)" >> $M; done; done
v() { awk -v n="$1" -v t="$2" -v k="$3" '$1 == n && $3 == t { for (i = 4; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $M; }
C=$O/checks.txt; : > $C
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $C; }
rule P1_reference_converged_angle near $(v ref_0.0005 2.5 j1_urad) $(v ref_0.0002 2.5 j1_urad) 10000
rule P1_reference_converged_speed within $(v ref_0.0005 2.5 j1_urads) $(v ref_0.0002 2.5 j1_urads) 100
rule P2_reference_held_on_the_limit all_in 3299000 3301000 $(for t in 1.8 2.0 2.1; do v ref_0.0002 $t j1_urad; done)
rule P3_link2_after_the_strike within $(v ref_0.0002 2.0 j2_urads) 6870000 100
rule P4_v4_near_the_reference near $(v xpbd_v4_0.00015625 2.5 j1_urad) $(v ref_0.0002 2.5 j1_urad) 50000
echo "checks: $(wc -l < $C | tr -d ' '), held: $(grep -c ': HELD$' $C)" >> $C
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
cat $C; grep " t 2.5 " $M
