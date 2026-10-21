#!/usr/bin/env bash
# Run 041, a trace (not registered): VBD's jointed-chain error at small steps (with Study 4's validated carried
# velocity, run 014's free chain gains 45% of its energy in 2 s at 0.05 ms on VBD), after run 038 ruled out the joint
# penalty's start. VBD holds a joint with a structural stiffness, rigid_joint_linear_ke and rigid_joint_angular_ke
# (1e5 by default). Against the arms' inertia seen at a joint (about 9 g between the arms, run 024) that is a spring of
# about 3,000 rad/s: a step of 0.625 ms (h w about 2) damps its vibration away in VBD's implicit solve, while a step of
# 0.05 ms (h w about 0.17) resolves it, so the joints ring, and the chain's energy is read from the arms' speeds.
# Hypothesis: the error at small steps is that elastic joint, resolved. If so a stiffer joint, which rings at a smaller
# amplitude (the stretch under the same load falls as 1 / k), leaves less of it.
# Run 014's free chain at 0.05 ms, 2 s, on VBD with the carried velocity (run 026's source, switch 2):
# Predicted, before the plays:
#   P1  with the structural stiffness at 1e7 (both linear and angular) the chain keeps its energy within 5 in 100 after
#       2 s (with the defaults it reads 1,451,104 per million).
#   P2  with it at 1e4 the energy departs further than with the defaults.
#   Reported, not predicted: the same without the carried velocity; VBD-ALM at 1e7.
# usage: play.sh <sx_contact binary>   (repository root; VBD_VENV set to run 026's patched source's environment)
set -u
B="${1:?usage: play.sh <sx_contact binary>}"
O=validation/run_041_vbd_joint_stiffness; W=$O/runs; mkdir -p $W
: > $W/log.txt
ARMS="mass1=1.2 mass2=0.6 radius=0.04 arm1=0.25 len1=0.5 arm2=0.2"
FREE="gravity=0 angle2=-0.9 omega1=2.5 omega2=1.5 secs=2"
K7="opt.rigid_joint_linear_ke=10000000.0 opt.rigid_joint_angular_ke=10000000.0"
K4="opt.rigid_joint_linear_ke=10000.0 opt.rigid_joint_angular_ke=10000.0"
one() {  # <switch 0|2> <name> <rig settings...>
  local sw=$1 n=$2; shift 2
  ( . "$VBD_VENV/bin/activate"; if [ $sw = 2 ]; then export NEWTON_VBD_CARRIED_VELOCITY=2; else unset NEWTON_VBD_CARRIED_VELOCITY; fi
    python tools/nwt_chain.py $W/${n}_s$sw.txt dt=0.00005 $ARMS $FREE "$@" > $W/${n}_s$sw.stats 2>> $W/log.txt )
}
date -u +%FT%TZ > $O/started.txt
one 2 vbd_k7 solver=vbd $K7 &
one 2 vbd_k4 solver=vbd $K4 &
one 0 vbd_k7 solver=vbd $K7 &
one 2 alm_k7 solver=vbd opt.rigid_compliant_alm=true $K7 &
wait
date -u +%FT%TZ > $O/finished.txt
{
  for f in $W/*_s?.txt; do
    s=$(grep -o 'out_of_range_at_step [0-9]*\|nan_at_step [0-9]*' ${f%.txt}.stats || echo "plays")
    echo "$(basename $f .txt) | $s | $("$B" chain $f | tail -1)"
  done
} > $O/reading.txt
cat $O/reading.txt
