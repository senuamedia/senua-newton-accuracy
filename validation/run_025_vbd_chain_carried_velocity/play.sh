#!/usr/bin/env bash
# Run 025, a probe of the patch in design (not registered): VBD's two-link chain with the carried velocity
# (patches/in_design/vbd_carried_velocity.diff, NEWTON_VBD_CARRIED_VELOCITY=1). In run 014 VBD and VBD-ALM took energy
# out of a free chain, less as the step shrank to 0.625 ms but more again at 0.156 ms (VBD 3.8% against 3.2%, VBD-ALM
# 7.6% against 3.1%), where XPBD's loss kept falling (0.91%). Run 022's patch removes the 32-bit cancellation in VBD's
# linear velocity, which grows as the step shrinks (a step's motion against the spacing of the arms' 32-bit positions).
# Run 014's two scenes (arms of 1.2 and 0.6 kg, half-size 0.04 m, arm1 0.25 m, len1 0.5 m, arm2 0.2 m; the free chain,
# no gravity, set turning at 2.5 and 1.5 rad/s; the swinging chain, gravity, released at rest from 0.4 and -0.7 rad;
# 2 s), on VBD and VBD-ALM at 10 ms over 1, 4, 16 and 64, on run 022's patched source, switch off and on.
# Predicted, before the plays:
#   S   off: 16 of 16 files byte-identical to run 014's (safe when off on joints).
#   P1  on: the free chain's loss at 0.156 ms is less than at 0.625 ms, on VBD and on VBD-ALM.
#   Not predicted, reported: the angular velocity is still read back from the quaternions (the patch leaves it), so how
#   much of the loss goes is not predicted; the swinging chain's energy; every other step.
# usage: play.sh <sx_contact binary>   (repository root; VBD_VENV set to run 022's patched source's environment)
set -u
B="${1:?usage: play.sh <sx_contact binary>}"
O=validation/run_025_vbd_chain_carried_velocity; W=$O/runs; mkdir -p $W
ARMS="mass1=1.2 mass2=0.6 radius=0.04 arm1=0.25 len1=0.5 arm2=0.2"
FREE="gravity=0 angle2=-0.9 omega1=2.5 omega2=1.5 secs=2"
SWING="gravity=1 angle1=0.4 angle2=-0.7 secs=2"
dt_of() { awk -v k=$1 'BEGIN { printf "%.12f", 0.01 / k }'; }
settings() { case $1 in vbd) echo "solver=vbd" ;; vbd_alm) echo "solver=vbd opt.rigid_compliant_alm=true" ;; esac; }
lane() {  # <off|on>: every play of one arm, one after another
  local a=$1 c k sc
  ( . "$VBD_VENV/bin/activate"
    if [ $a = on ]; then export NEWTON_VBD_CARRIED_VELOCITY=1; else unset NEWTON_VBD_CARRIED_VELOCITY; fi
    for c in vbd vbd_alm; do for k in 1 4 16 64; do for sc in free swing; do
      if [ $sc = free ]; then S="$FREE"; else S="$SWING"; fi
      python tools/nwt_chain.py $W/${sc}_${c}_${k}_$a.txt dt=$(dt_of $k) $ARMS $S $(settings $c) > $W/${sc}_${c}_${k}_$a.stats 2> $W/${sc}_${c}_${k}_$a.log
    done; done; done )
}
date -u +%FT%TZ > $O/started.txt
lane off & lane on & wait
date -u +%FT%TZ > $O/finished.txt
{
  n=0; d=0
  for f in $W/*_off.txt; do
    g=validation/run_014_chain/runs/$(basename "$f" _off.txt).txt; n=$((n + 1))
    cmp -s "$f" "$g" || { d=$((d + 1)); echo "DIFFERS $(basename "$f")"; }
  done
  echo "S off against run 014: $((n - d)) of $n byte-identical"
  for c in vbd vbd_alm; do for sc in free swing; do for k in 1 4 16 64; do for a in off on; do
    s=$(grep -o 'out_of_range_at_step [0-9]*\|nan_at_step [0-9]*' $W/${sc}_${c}_${k}_$a.stats || echo "plays")
    echo "$sc $c 1/$k $a | $s | $("$B" chain $W/${sc}_${c}_${k}_$a.txt | tail -1)"
  done; done; done; done
} > $O/reading.txt
cat $O/reading.txt
