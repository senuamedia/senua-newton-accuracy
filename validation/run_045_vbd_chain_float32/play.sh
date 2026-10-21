#!/usr/bin/env bash
# Run 045, a trace (not registered): VBD's jointed-chain error at small steps, against where the chain is in the world.
# Read again, with the existing plays: measured on the first n steps of each file (the chain measure on a file's
# prefix), VBD's free chain at 0.05 ms leaves the right trajectory within milliseconds (its second joint at 1.728 rad/s
# after 5 ms where the MuJoCo solver's RK4, keeping energy to 5 ppm, gives 1.649), as released and with Study 4's
# patch alike, and its energy swings with the motion: at its largest it departs by 537,677 ppm as released and
# 524,931 with the patch (end readings of 915,739 and 1,451,104 differ only in where the swing ends), against 31,979 at
# 0.625 ms and 23,161 at 0.2 ms.
# Read in the source (vbd/rigid_vbd_kernels.py, solve_rigid_body): each iteration a body's new pose is its 32-bit pose
# plus the solve's increment, com_new = com_current + x_inc, and at a small step the joint's share of that increment,
# (h^2 / m) F, is about a joint force times h^2 / m: here some 3e-8 m a step at 0.05 ms, under the 32-bit spacing of a
# position 0.5 to 1 m from the origin (6e-8 m). The joint acts in steps of whole spacings or not at all, as VBD's
# velocity read-back did (F2). Hypothesis: VBD's chain error at small steps is its joint solve's increments falling
# under the 32-bit spacing of the bodies' positions. If so, it depends on how far the chain is from the world's origin,
# which nothing in the physics does: moved 100 m away (spacing 7.6e-6 m, 128 times coarser) the chain at 0.625 ms
# (h^2 156 times larger) is where it is at 0.05 ms at the origin, and moved 10 m away (16 times coarser) the chain at
# 0.2 ms (16 times larger) is too. Featherstone, whose state is the joints' angles, is not.
# Run 014's free chain (arms of 1.2 and 0.6 kg, no gravity, set turning, 2 s), the chain rig's new x0 (the first
# joint's place along x; a no-op when not given), run 026's patched source.
# Predicted, before the plays:
#   P1  VBD with Study 4's carried velocity at 0.625 ms, the chain at x0 = 100 m: its energy departs at its largest by
#       more than 200,000 ppm of its most (31,979 at the origin, run 026).
#   P2  the same at 0.2 ms with the chain at x0 = 10 m: more than 200,000 ppm (23,161 at the origin, run 038).
#   P3  Featherstone at 0.625 ms, the chain at x0 = 100 m: its largest departure within 1,000 ppm of its play at the
#       origin.
#   Reported, not predicted: VBD as released, VBD-ALM with the carried velocity and XPBD at 0.625 ms with the chain at
#   100 m; VBD with the carried velocity at 0.625 ms at 10 m and at 0.05 ms at 100 m. Checks: with x0 not given, VBD
#   with the carried velocity at 0.625 ms is run 026's file and Featherstone at 0.625 ms run 014's, byte for byte. The
#   momentum fields are about the world's origin, so not the chain's at x0 other than 0: not read.
# usage: play.sh <sx_contact binary>   (repository root; VBD_VENV set to run 026's patched source's environment)
set -u
B="${1:?usage: play.sh <sx_contact binary>}"
O=validation/run_045_vbd_chain_float32; W=$O/runs; mkdir -p $W
: > $W/log.txt
ARMS="mass1=1.2 mass2=0.6 radius=0.04 arm1=0.25 len1=0.5 arm2=0.2"
FREE="gravity=0 angle2=-0.9 omega1=2.5 omega2=1.5 secs=2"
one() {  # <switch 0|2> <name> <dt> <rig settings...>
  local sw=$1 n=$2 dt=$3; shift 3
  ( . "$VBD_VENV/bin/activate"; if [ $sw = 2 ]; then export NEWTON_VBD_CARRIED_VELOCITY=2; else unset NEWTON_VBD_CARRIED_VELOCITY; fi
    python tools/nwt_chain.py $W/${n}_$dt.txt dt=$dt $ARMS $FREE "$@" > $W/${n}_$dt.stats 2>> $W/log.txt )
}
date -u +%FT%TZ > $O/started.txt
one 2 vbd_s2_x100 0.00005 solver=vbd x0=100 &
one 2 vbd_s2_x0 0.000625 solver=vbd &
one 2 vbd_s2_x100 0.000625 solver=vbd x0=100 &
one 2 vbd_s2_x10 0.0002 solver=vbd x0=10 &
wait
one 0 feather_x0 0.000625 solver=featherstone &
one 0 feather_x100 0.000625 solver=featherstone x0=100 &
one 0 vbd_s0_x100 0.000625 solver=vbd x0=100 &
one 2 alm_s2_x100 0.000625 solver=vbd opt.rigid_compliant_alm=true x0=100 &
wait
one 0 xpbd_x0 0.000625 solver=xpbd &
one 0 xpbd_x100 0.000625 solver=xpbd x0=100 &
one 2 vbd_s2_x10 0.000625 solver=vbd x0=10 &
wait
date -u +%FT%TZ > $O/finished.txt
{
  for f in $W/*_0*.txt; do
    s=$(grep -o 'out_of_range_at_step [0-9]*\|nan_at_step [0-9]*' ${f%.txt}.stats || echo "plays")
    echo "$(basename $f .txt) | $s | $("$B" chain $f | tail -1)"
  done
  if cmp -s $W/vbd_s2_x0_0.000625.txt validation/run_026_vbd_carried_velocity_v2/runs/free_vbd_16_on2.txt; then r=yes; else r=NO; fi
  echo "CHECK VBD with the carried velocity at 0.625 ms, x0 not given, byte-identical to run 026's: $r"
  if cmp -s $W/feather_x0_0.000625.txt validation/run_014_chain/runs/free_featherstone_16.txt; then r=yes; else r=NO; fi
  echo "CHECK Featherstone at 0.625 ms, x0 not given, byte-identical to run 014's: $r"
} > $O/reading.txt
cat $O/reading.txt
