#!/usr/bin/env bash
# Run 107: XPBD's joint limit on a chain against the converged right answer as the step shrinks, and on one arm (issue
# 8), a design probe whose predictions were pushed before the plays: run 105's chain under the joint-angle patch's
# fourth form (NEWTON_XPBD_JOINT_ANGLE_UNWRAP=4) at XPBD's default relaxations, 16 and 64 iterations, at 2.5, 0.625,
# 0.156 and 0.039 ms; run 061's arm (1.5 kg, 0.03 m, its centre 0.3 m out, turning at 3 rad/s onto a limit at 2.5 rad,
# no gravity, 1.4 s) under the same form at 2, 16 and 64 iterations, at 1.6 and 0.32 ms; on Newton 1.7.0. Then
# measured.txt and checks.txt.
# usage: play.sh <sx_contact binary>   (repository root; V4_VENV the patch's tree)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"
O=validation/run_107_xpbd_limit_chain_steps
CH="mass1=1.2 mass2=0.6 radius=0.04 arm1=0.25 len1=0.5 arm2=0.2 gravity=0 angle1=0 angle2=0 omega1=2 omega2=0 secs=2.5 lo1=-1 hi1=3.3 solver=xpbd"
ARM="mass=1.5 radius=0.03 gravity=0 omega0=3 secs=1.4 solver=xpbd arm=0.3 angle0=0 lo=-0.5 hi=2.5"
CS="0.0025 0.000625 0.00015625 0.0000390625"; TS="1.8 2.0 2.1 2.2 2.5"
plays() { local it dt; for it in 16 64; do for dt in $CS; do echo "chain_it${it}_$dt nwt_chain dt=$dt $CH iterations=$it"; done; done
  for it in 2 16 64; do for dt in 0.0016 0.00032; do echo "arm_it${it}_$dt nwt_joint dt=$dt $ARM iterations=$it"; done; done; }
mkdir -p $O/runs $O/stats; date -u +%FT%TZ > $O/started.txt
( . "$V4_VENV/bin/activate"; export NEWTON_XPBD_JOINT_ANGLE_UNWRAP=4
  plays | xargs -P 4 -L 1 bash -c 'python tools/$1.py '"$O"'/runs/$0.txt "${@:2}" > '"$O"'/stats/$0.txt 2> '"$O"'/runs/log_$0.txt' )
date -u +%FT%TZ > $O/finished.txt
at() { awk -v t=$2 '$1 == "CHAIN" { for (i = 2; i < NF; i++) if ($i == "dt_ns") dt = $(i + 1) / 1e9; next }
  dt > 0 && $1 == sprintf("%d", t / dt - 1 + 0.5) - 0 { print "j1_urad", $2, "j1_urads", $3, "j2_urads", $5; exit }' $1; }
M=$O/measured.txt; : > $M
R=validation/run_105_xpbd_limit_chain_reference/runs/ref_0.0002.txt
for t in $TS; do echo "reference t $t $(at $R $t)" >> $M; done
for n in $(plays | awk '$2 == "nwt_chain" { print $1 }'); do for t in $TS; do echo "$n t $t $(at $O/runs/$n.txt $t)" >> $M; done; done
for n in $(plays | awk '$2 == "nwt_joint" { print $1 }'); do echo "$n t end $("$B" final $O/runs/$n.txt < /dev/null | tail -1)" >> $M; done
v() { awk -v n="$1" -v t="$2" -v k="$3" '$1 == n && $3 == t { for (i = 4; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $M; }
C=$O/checks.txt; : > $C
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $C; }
REF=$(v reference 2.5 j1_urad)
rule P1_on_the_limit_it64 all_in 3299000 3301000 $(for dt in 0.000625 0.00015625 0.0000390625; do v chain_it64_$dt 2.0 j1_urad; done)
rule P2_converged_it64 near $(v chain_it64_0.0000390625 2.5 j1_urad) $REF 20000
rule P3_arm_held_angle all_within 2500000 50 $(for dt in 0.0016 0.00032; do v arm_it64_$dt end angle_urad; done)
rule P3_arm_held_speed all_in -100000 100000 $(for dt in 0.0016 0.00032; do v arm_it64_$dt end speed_urads; done)
echo "checks: $(wc -l < $C | tr -d ' '), held: $(grep -c ': HELD$' $C)" >> $C
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
cat $C; awk '$3 == "2.5" || $3 == "end"' $M
