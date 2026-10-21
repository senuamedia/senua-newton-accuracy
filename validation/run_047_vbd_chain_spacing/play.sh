#!/usr/bin/env bash
# Run 047, a trace (not registered): VBD's chain error against the step and the chain's place together. Run 045 found
# VBD's free chain departs from its energy as far at 0.625 ms 100 m from the origin, and at 0.2 ms 10 m from it, as at
# 0.05 ms at the origin (the hypothesis: the joint solve's increments, about (h^2 / m) F a step, under the 32-bit
# spacing of the bodies' positions). If that is the cause, what decides the error is the ratio of h^2 to the spacing
# at the chain's place, not either alone. The chain spans x0 to x0 + 0.7 m; its spacing is 6.0e-8 m at the origin
# (positions 0.5 to 1 m), 4.8e-7 m at 4 m, 1.9e-6 m at 16 m and 7.6e-6 m at 64 m. With h^2 / spacing in units of
# 1e-9 s^2 / 6e-8 m (VBD at 0.05 ms at the origin: 0.042), the grid below gives:
#             x0 = 0     4 m      16 m     64 m
#   0.625 ms   6.5       0.81     0.20     0.051
#   0.3125 ms  1.6       0.20     0.051    0.013
#   0.15625 ms 0.41      0.051    0.013    0.0032
# Run 014's free chain (no gravity, 2 s) on VBD with Study 4's carried velocity, run 026's patched source.
# Predicted, before the plays:
#   P1  the three plays at a ratio of 0.051 (0.625 ms at 64 m, 0.3125 ms at 16 m, 0.15625 ms at 4 m) each depart from
#       their energy at their largest by more than 200,000 ppm of their most, as VBD at 0.05 ms at the origin (ratio
#       0.042: 524,931).
#   P2  at each step the largest departure grows with x0 (four places, three steps).
#   Reported, not predicted: the plays at a ratio of 0.20 and at the smallest ratios. Checks: x0 = 0 at 0.625 and
#   0.15625 ms are run 026's files byte for byte.
# usage: play.sh <sx_contact binary>   (repository root; VBD_VENV set to run 026's patched source's environment)
set -u
B="${1:?usage: play.sh <sx_contact binary>}"
O=validation/run_047_vbd_chain_spacing; W=$O/runs; mkdir -p $W
: > $W/log.txt
ARMS="mass1=1.2 mass2=0.6 radius=0.04 arm1=0.25 len1=0.5 arm2=0.2"
FREE="gravity=0 angle2=-0.9 omega1=2.5 omega2=1.5 secs=2"
one() {  # <dt> <x0>
  local dt=$1 x0=$2
  ( . "$VBD_VENV/bin/activate"; export NEWTON_VBD_CARRIED_VELOCITY=2
    if [ $x0 = 0 ]; then X=""; else X="x0=$x0"; fi
    python tools/nwt_chain.py $W/vbd_x${x0}_$dt.txt dt=$dt $ARMS $FREE solver=vbd $X > $W/vbd_x${x0}_$dt.stats 2>> $W/log.txt )
}
date -u +%FT%TZ > $O/started.txt
for dt in 0.000625 0.0003125 0.00015625; do
  for x0 in 0 4 16 64; do one $dt $x0 & done
  wait
done
date -u +%FT%TZ > $O/finished.txt
{
  for dt in 0.000625 0.0003125 0.00015625; do for x0 in 0 4 16 64; do
    f=$W/vbd_x${x0}_$dt.txt
    s=$(grep -o 'out_of_range_at_step [0-9]*\|nan_at_step [0-9]*' ${f%.txt}.stats || echo "plays")
    echo "vbd_x${x0}_$dt | $s | $("$B" chain $f | tail -1)"
  done; done
  for p in "0.000625 16" "0.00015625 64"; do set -- $p
    if cmp -s $W/vbd_x0_$1.txt validation/run_026_vbd_carried_velocity_v2/runs/free_vbd_$2_on2.txt; then r=yes; else r=NO; fi
    echo "CHECK x0 = 0 at $1 s byte-identical to run 026's: $r"
  done
} > $O/reading.txt
cat $O/reading.txt
