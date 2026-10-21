#!/usr/bin/env bash
# Run 049, a trace (not registered): run 047's grid (VBD's free chain at three steps, the first joint at 0, 4, 16 and
# 64 m) on VBD as released and on VBD-ALM with Study 4's carried velocity. Run 047 found, on VBD with the carried
# velocity, that the ratio of h^2 to the 32-bit spacing of the positions decides the chain's error (traced to VBD's
# solve keeping its poses in 32 bits, run 045). The solve is the same as released and on VBD-ALM's compliant path, so
# the same law should hold on both. Also the baseline a correction of the solve is measured against.
# Predicted, before the plays:
#   P1  as released and on VBD-ALM, the three plays at a ratio of 0.051 (0.625 ms at 64 m, 0.3125 ms at 16 m,
#       0.15625 ms at 4 m) each depart from their energy at their largest by more than 200,000 ppm of their most.
#   P2  on both, at 0.625 ms the largest departure grows with x0 (four places).
#   Reported, not predicted: every other play. Checks: as released, x0 = 0 at 0.625 and 0.15625 ms are run 026's
#   files (off) byte for byte; VBD-ALM with the carried velocity at x0 = 0 the same with run 026's (on2).
# usage: play.sh <sx_contact binary>   (repository root; VBD_VENV set to run 026's patched source's environment)
set -u
B="${1:?usage: play.sh <sx_contact binary>}"
O=validation/run_049_vbd_chain_spacing_release; W=$O/runs; mkdir -p $W
: > $W/log.txt
ARMS="mass1=1.2 mass2=0.6 radius=0.04 arm1=0.25 len1=0.5 arm2=0.2"
FREE="gravity=0 angle2=-0.9 omega1=2.5 omega2=1.5 secs=2"
one() {  # <vbd|alm> <dt> <x0>
  local c=$1 dt=$2 x0=$3
  ( . "$VBD_VENV/bin/activate"
    if [ $c = vbd ]; then unset NEWTON_VBD_CARRIED_VELOCITY; S="solver=vbd"; else export NEWTON_VBD_CARRIED_VELOCITY=2; S="solver=vbd opt.rigid_compliant_alm=true"; fi
    if [ $x0 = 0 ]; then X=""; else X="x0=$x0"; fi
    python tools/nwt_chain.py $W/${c}_x${x0}_$dt.txt dt=$dt $ARMS $FREE $S $X > $W/${c}_x${x0}_$dt.stats 2>> $W/log.txt )
}
date -u +%FT%TZ > $O/started.txt
for dt in 0.000625 0.0003125 0.00015625; do
  for c in vbd alm; do
    for x0 in 0 4 16 64; do one $c $dt $x0 & done
    wait
  done
done
date -u +%FT%TZ > $O/finished.txt
{
  for c in vbd alm; do for dt in 0.000625 0.0003125 0.00015625; do for x0 in 0 4 16 64; do
    f=$W/${c}_x${x0}_$dt.txt
    s=$(grep -o 'out_of_range_at_step [0-9]*\|nan_at_step [0-9]*' ${f%.txt}.stats || echo "plays")
    echo "${c}_x${x0}_$dt | $s | $("$B" chain $f | tail -1)"
  done; done; done
  for p in "0.000625 16" "0.00015625 64"; do set -- $p
    if cmp -s $W/vbd_x0_$1.txt validation/run_026_vbd_carried_velocity_v2/runs/free_vbd_$2_off.txt; then r=yes; else r=NO; fi
    echo "CHECK as released, x0 = 0 at $1 s byte-identical to run 026's: $r"
    if cmp -s $W/alm_x0_$1.txt validation/run_026_vbd_carried_velocity_v2/runs/free_vbd_alm_$2_on2.txt; then r=yes; else r=NO; fi
    echo "CHECK VBD-ALM with the carried velocity, x0 = 0 at $1 s byte-identical to run 026's: $r"
  done
} > $O/reading.txt
cat $O/reading.txt
