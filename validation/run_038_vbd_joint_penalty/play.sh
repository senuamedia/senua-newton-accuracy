#!/usr/bin/env bash
# Run 038, a trace (not registered): VBD's error at small steps on a jointed chain, which with the validated carried
# velocity (Study 4) gives run 014's free chain +45% of its energy at 0.05 ms on VBD (-8% as released). Runs 025, 026
# and 029 ruled out its velocity read-back and its warm-start decay. Read in the source (solver_vbd.py): VBD holds a
# joint with a penalty that starts at rigid_joint_linear_k_start (100 N/m) and rigid_joint_angular_k_start
# (10 N m/rad), ramps by rigid_avbd_beta per iteration (0 by default: no ramp) and is capped at the structural
# rigid_joint_linear_ke and rigid_joint_angular_ke (1e5); each body's solve weighs it against its inertia, m / h^2.
# As the step shrinks, m / h^2 grows as 1 / h^2 (4.8e8 N/m for the 1.2 kg arm at 0.05 ms) while the penalty stays at
# its start, so a joint is held ever more weakly against the bodies' own motion.
# Hypothesis: that unramped penalty is the cause. Predicted, before the plays, on run 014's free chain at 0.05 ms
# (2 s), Newton 1.6.1 from source with the carried velocity's second form (NEWTON_VBD_CARRIED_VELOCITY=2) and without it:
#   P1  on VBD with the penalty started at its structural cap (rigid_joint_linear_k_start and
#       rigid_joint_angular_k_start 1e5), the chain keeps its energy to within 2 parts in 100 after 2 s, with and without
#       the carried velocity (as released at 0.05 ms it keeps 915,739 per million, and with the patch 1,451,104).
#   P2  on VBD, 40 iterations in place of 10 move the energy by less than the penalty at its cap does.
#   Reported, not predicted: VBD-ALM (its compliant path weighs the structural stiffness itself); the chain at 0.2 ms.
# usage: play.sh <sx_contact binary>   (repository root; VBD_VENV set to run 026's patched source's environment)
set -u
B="${1:?usage: play.sh <sx_contact binary>}"
O=validation/run_038_vbd_joint_penalty; W=$O/runs; mkdir -p $W
: > $W/log.txt
ARMS="mass1=1.2 mass2=0.6 radius=0.04 arm1=0.25 len1=0.5 arm2=0.2"
FREE="gravity=0 angle2=-0.9 omega1=2.5 omega2=1.5 secs=2"
KCAP="opt.rigid_joint_linear_k_start=100000.0 opt.rigid_joint_angular_k_start=100000.0"
one() {  # <switch: 0|2> <name> <dt> <rig settings...>
  local sw=$1 n=$2 dt=$3; shift 3
  ( . "$VBD_VENV/bin/activate"; if [ $sw = 2 ]; then export NEWTON_VBD_CARRIED_VELOCITY=2; else unset NEWTON_VBD_CARRIED_VELOCITY; fi
    python tools/nwt_chain.py $W/${n}_${dt}_s$sw.txt dt=$dt $ARMS $FREE "$@" > $W/${n}_${dt}_s$sw.stats 2>> $W/log.txt )
}
date -u +%FT%TZ > $O/started.txt
( one 2 vbd_kcap 0.00005 solver=vbd $KCAP; one 0 vbd_kcap 0.00005 solver=vbd $KCAP ) &
( one 2 vbd_it40 0.00005 solver=vbd iterations=40; one 2 vbd_kcap 0.0002 solver=vbd $KCAP ) &
( one 2 alm_kcap 0.00005 solver=vbd opt.rigid_compliant_alm=true $KCAP; one 0 vbd_it40 0.00005 solver=vbd iterations=40 ) &
( one 2 alm_it40 0.00005 solver=vbd opt.rigid_compliant_alm=true iterations=40; one 2 vbd_dflt 0.00005 solver=vbd ) &
wait
date -u +%FT%TZ > $O/finished.txt
{
  for f in $W/*.txt; do
    [ "$(basename $f)" = log.txt ] && continue
    s=$(grep -o 'out_of_range_at_step [0-9]*\|nan_at_step [0-9]*' ${f%.txt}.stats || echo "plays")
    echo "$(basename $f .txt) | $s | $("$B" chain $f | tail -1)"
  done
  if cmp -s $W/vbd_dflt_0.00005_s2.txt validation/run_034_study_04/on/runs/chain_vbd_0.00005.txt; then r=yes; else r=NO; fi
  echo "CHECK VBD with the patch and its defaults at 0.05 ms byte-identical to Study 4's on play: $r"
} > $O/reading.txt
cat $O/reading.txt
