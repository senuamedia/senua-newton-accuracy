#!/usr/bin/env bash
# Run 029, a trace (not registered): why VBD gets worse as the step shrinks where its velocity read-back is not the
# cause. Runs 025 and 026 found VBD's excess energy loss on the free chain at 0.156 ms is not its velocity's 32-bit
# read-back; run 001 found its hold creeping faster as the step shrinks (VBD 223 mm/s at 0.125 ms and 614 mm/s at
# 0.031 ms; VBD-ALM 74 and 406 um/s), where every other solver creeps the same or slower. Read in the source
# (solver_vbd.py): VBD warm-starts each constraint's force (its augmented-Lagrangian multiplier, and on the legacy path
# its penalty) from the step before, decayed by rigid_avbd_gamma, 0.999 a step (Augmented Vertex Block Descent, Giles et
# al., SIGGRAPH 2025, warm-starts the same way). A per-step factor decays faster per second as the step shrinks:
# 0.999^100 = 0.90 in a second at 10 ms, 0.999^6400 = 0.0017 at 0.156 ms, 0.999^32000 = 1e-14 at 0.031 ms. So a joint or
# a contact that needs a held force keeps less of it at a small step.
# Hypothesis: that decay is the cause. Played with rigid_avbd_gamma 1 (no decay), the clean off value, against 0.999:
#   chain   run 014's free chain on VBD and VBD-ALM at 0.625 ms and 0.156 ms
#   hold    run 001's hold (1 kg, half-size 0.05 m, friction 0.5, 2.94 N from 0.5 s, 2 s) on VBD and VBD-ALM at
#           0.125 ms and 0.031 ms
# Predicted, before the plays:
#   P1  with gamma 1, the free chain keeps more of its energy at 0.156 ms than at 0.625 ms, on both solvers (as
#       released it keeps less).
#   P2  with gamma 1, the hold creeps slower than as released at both steps on both solvers.
#   Check: gamma 0.999, given, gives run 014's and run 001's files byte for byte.
#   Reported, not predicted: the chain's momentum; whether either solver then holds.
# usage: play.sh <sx_contact binary>   (repository root, Newton from PyPI's environment on; writes the reading)
set -u
B="${1:?usage: play.sh <sx_contact binary>}"
O=validation/run_029_vbd_gamma; W=$O/runs; mkdir -p $W
: > $W/stats.txt; : > $W/log.txt
ARMS="mass1=1.2 mass2=0.6 radius=0.04 arm1=0.25 len1=0.5 arm2=0.2"
FREE="gravity=0 angle2=-0.9 omega1=2.5 omega2=1.5 secs=2"
HOLD="h0=0 mu=0.5 push=2.94 pushat=0.5 secs=2"
chain() {  # <vbd|vbd_alm> <k> <gamma>
  local c=$1 k=$2 g=$3 X dt
  if [ $c = vbd ]; then X="solver=vbd"; else X="solver=vbd opt.rigid_compliant_alm=true"; fi
  dt=$(awk -v k=$k 'BEGIN { printf "%.12f", 0.01 / k }')
  python tools/nwt_chain.py $W/free_${c}_${k}_g$g.txt dt=$dt $ARMS $FREE $X opt.rigid_avbd_gamma=$g > $W/free_${c}_${k}_g$g.stats 2>> $W/log.txt
}
hold() {  # <vbd|vbd_alm> <dt> <gamma>
  python tools/nwt_contact.py $W/hold_$1_$2_g$3.txt dt=$2 $HOLD solver=$1 opt.rigid_avbd_gamma=$3 2>> $W/log.txt | sed "s/^STATS/STATS hold_$1_$2_g$3/" >> $W/stats.txt
}
date -u +%FT%TZ > $O/started.txt
( chain vbd 16 1.0; chain vbd 64 1.0; chain vbd 16 0.999; chain vbd 64 0.999; hold vbd 0.000125 1.0 ) &
( chain vbd_alm 16 1.0; chain vbd_alm 64 1.0; chain vbd_alm 16 0.999; chain vbd_alm 64 0.999; hold vbd_alm 0.000125 1.0 ) &
( hold vbd 0.00003125 1.0; hold vbd 0.000125 0.999 ) &
( hold vbd_alm 0.00003125 1.0; hold vbd_alm 0.000125 0.999 ) &
wait
date -u +%FT%TZ > $O/finished.txt
{
  for c in vbd vbd_alm; do for k in 16 64; do for g in 0.999 1.0; do
    s=$(grep -o 'out_of_range_at_step [0-9]*\|nan_at_step [0-9]*' $W/free_${c}_${k}_g$g.stats || echo "plays")
    echo "free $c 1/$k gamma $g | $s | $("$B" chain $W/free_${c}_${k}_g$g.txt | tail -1)"
  done; done; done
  for s in vbd vbd_alm; do for dt in 0.000125 0.00003125; do for g in 0.999 1.0; do
    f=$W/hold_${s}_${dt}_g$g.txt
    if [ -f $f ]; then echo "hold $s $dt gamma $g | $("$B" creep $f | tail -1)"; fi
  done; done; done
  for c in vbd vbd_alm; do for k in 16 64; do
    if cmp -s $W/free_${c}_${k}_g0.999.txt validation/run_014_chain/runs/free_${c}_$k.txt; then r=yes; else r=NO; fi
    echo "CHECK chain $c 1/$k gamma 0.999 byte-identical to run 014's: $r"
  done; done
  for s in vbd vbd_alm; do
    if cmp -s $W/hold_${s}_0.000125_g0.999.txt validation/run_001_design_probes/runs/hold_${s}_0.000125.txt; then r=yes; else r=NO; fi
    echo "CHECK hold $s 0.125 ms gamma 0.999 byte-identical to run 001's: $r"
  done
  echo "plays that stopped being a number: $(cat $W/*.stats $W/stats.txt | grep -c nan_at_step)"
} > $O/reading.txt
cat $O/reading.txt
