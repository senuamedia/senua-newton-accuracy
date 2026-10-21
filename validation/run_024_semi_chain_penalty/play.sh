#!/usr/bin/env bash
# Run 024, a trace (not registered): why SemiImplicit blows up on the two-link chain at every step run 014 played
# (F10: from the 7th step at 10 ms to 0.40 s at 0.156 ms). SemiImplicit holds a joint together with an explicit penalty
# between the joint's two anchor points, f = joint_attach_ke x_err + joint_attach_kd v_err (kernels_body.py,
# eval_body_joints), ke 10,000 N/m and kd 100 N s/m by default, applied at the anchors, so it turns the arms too. Across
# an arm the mass the anchor sees is m_eff = 1 / (1 / m + l^2 / I), l the anchor's distance from the arm's centre:
# 20.1 g for run 014's first arm at the fixed joint, and 8.8 g at the joint between the arms (both arms in series).
# An explicit damper is stable only while h kd / m_eff < 2, and with the spring the critical step is
# (2 / w)(sqrt(1 + z^2) - z), w^2 = ke / m_eff, z the damping ratio (Belytschko, Liu and Moran 2000, section 6.3):
# 0.17 ms at the joint between the arms (h kd / m_eff = 1.8 at 0.156 ms, run 014's finest step, where the blow-up came
# late), 0.40 ms at the fixed joint. With kd = 0 the spring alone is stable while h w < 2: 1.9 ms between the arms.
# The joint's swing penalty (ke on the angle out of the hinge's plane, against the arms' inertia about an axis in the
# plane, about 0.43 g m^2 in series) is stable while h < 0.41 ms; the chain moves in its plane, so only rounding
# excites it.
# Run 014's free chain (arms of 1.2 and 0.6 kg, half-size 0.04 m, arm1 0.25 m, len1 0.5 m, arm2 0.2 m, no gravity,
# set turning at 2.5 and 1.5 rad/s, 2 s), SemiImplicit, Newton 1.6.1 from PyPI, its defaults but where named:
# Predicted, before the plays:
#   P1  at 0.078125 and 0.0390625 ms (h kd / m_eff 0.89 and 0.44 between the arms) the chain plays its 2 s without
#       leaving the format's range.
#   P2  at 0.3125 ms (h kd / m_eff 3.6) it leaves the range within a few hundred steps; with joint_attach_kd 0 it plays
#       its 2 s (the spring alone and the swing penalty are inside their limits there).
#   P3  at 0.625 ms with joint_attach_kd 0 it still leaves the range, if rounding excites the swing (its penalty is
#       past its limit there, 0.625 ms against 0.41 ms); if it plays, nothing out of the plane was excited.
#   Reported, not predicted: the energy and momentum (sx_contact chain) where it plays.
# usage: play.sh <sx_contact binary>   (repository root, Newton from PyPI's environment on; writes the reading)
set -u
B="${1:?usage: play.sh <sx_contact binary>}"
O=validation/run_024_semi_chain_penalty; W=$O/runs; mkdir -p $W
ARMS="mass1=1.2 mass2=0.6 radius=0.04 arm1=0.25 len1=0.5 arm2=0.2"
FREE="gravity=0 angle2=-0.9 omega1=2.5 omega2=1.5 secs=2"
one() {  # <name> <dt> <rig settings...>
  local n=$1 dt=$2; shift 2
  python tools/nwt_chain.py $W/${n}_$dt.txt dt=$dt $ARMS $FREE solver=semi "$@" > $W/${n}_$dt.stats 2> $W/${n}_$dt.log
}
date -u +%FT%TZ > $O/started.txt
one free_semi 0.0003125 &
one free_semi_kd0 0.0003125 opt.joint_attach_kd=0 &
wait
one free_semi_kd0 0.000625 opt.joint_attach_kd=0 &
one free_semi 0.000078125 &
wait
one free_semi 0.0000390625
date -u +%FT%TZ > $O/finished.txt
{
  for p in "free_semi 0.0003125" "free_semi_kd0 0.0003125" "free_semi_kd0 0.000625" "free_semi 0.000078125" "free_semi 0.0000390625"; do
    set -- $p
    s=$(grep -o 'out_of_range_at_step [0-9]*\|nan_at_step [0-9]*' $W/$1_$2.stats || echo "plays 2 s")
    echo "$1 $2 s | $s | $("$B" chain $W/$1_$2.txt | tail -1)"
  done
} > $O/reading.txt
cat $O/reading.txt
