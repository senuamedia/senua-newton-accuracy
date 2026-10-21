#!/usr/bin/env bash
# Run 021, a trace (not registered): why the normal-contact patch in design (patches/in_design/
# contact_damping_no_pull.diff) failed run 020's second and third checks. Run 020: at 10 ms the suite's drop is
# launched in its first contact step, byte-identical to the release (check 2); with Study 1's patch the hold at
# 0.625 ms creeps 2% faster (2,704 against 2,645 um/s, check 3); alone, with the stock friction, the hold slides back
# faster. The hypothesis: both are limits of Newton's explicit integration of its penalty contact, not of the contact
# law, so no change to the law can reach them.
#
# Newton's defaults: per contact ke 2,500 N/m, kd 100 N s/m, kf 1,000 N s/m (the mean of the two shapes'); a cube flat
# on the ground touches it at four corners. SemiImplicit and Featherstone integrate the contact force explicitly over
# the step, h.
#   The normal: the cube's speed into the ground decays at c_n = 4 kd / m. A damper integrated explicitly gives
#   v' = v (1 - h c_n): monotone (it never turns the speed round) only while h c_n <= 1, stable only while
#   h c_n < 2; with the spring the stability limit is h < (2 / w)(sqrt(1 + z^2) - z), w^2 = 4 ke / m, z the damping
#   ratio (Belytschko, Liu and Moran, Nonlinear Finite Elements for Continua and Structures, Wiley 2000, section 6.3).
#   For the suite's 2 kg cube c_n = 200 /s: monotone to 5 ms, stable to 8.99 ms; at 10 ms h c_n = 2, so the damper
#   alone turns the speed round in one step and the spring adds to it. The patch acts only while the contact opens,
#   after that step.
#   Friction: a horizontal force at the four bottom corners also turns the cube, so the corners' slip decays at
#   c_t = 4 kf (1 / m + r^2 / I) = 10 kf / m for a cube of half-size r (I = 2 m r^2 / 3): explicit friction is stable
#   only while h c_t < 2, h < 0.2 ms for run 001's 1 kg cube and 0.4 ms for the suite's 2 kg cube. Above it the slip
#   grows step by step, alternating in sign, until friction reaches its cap, and the hold creeps at whatever speed
#   that chatter gives; below it the hold creeps at the push over four corners' kf, the viscous branch both friction
#   laws share at a slip that small (run 001: 735 um/s at 0.125 and 0.031 ms, -6,138 and -6,601 um/s at 0.5 ms).
#
# Predicted, before the plays:
#   A. The drop (80 mm, friction 0, half-size 0.04 m) at masses 1, 2 and 4 kg and steps 2.5, 5 and 10 ms, on
#      SemiImplicit and Featherstone, with both switches (Study 1's and the patch's) and with none (the release):
#      A1  with both switches, no rebound (bounce reads 0) wherever h c_n <= 1: 1 kg at 2.5 ms, 2 kg at 2.5 and 5 ms,
#          4 kg at 2.5, 5 and 10 ms; so the 4 kg cube does not rebound at 10 ms, the step the 2 kg cube failed at.
#      A2  wherever h c_n >= 2 (1 kg at 5 and 10 ms, 2 kg at 10 ms) the cube is launched in its first contact step
#          (steps_to_turn 1) and the file with both switches is byte-identical to the release's: the patch is never
#          reached, as for the 2 kg cube at 10 ms in run 020.
#   B. The suite's hold (2 kg, friction 0.5, 5.88 N from 0.5 s, 2 s) on SemiImplicit at 0.625, 0.44, 0.36 and
#      0.15625 ms, with no switch, Study 1's only, both, and the patch's only:
#      B1  at 0.36 and 0.15625 ms (below 0.4 ms) every arm creeps at 5.88 N / 4,000 N s/m = 1,470 um/s, within 1 in
#          100, and each arm with the patch reads within 1 in 100 of the same arm without it.
#      B2  at 0.44 and 0.625 ms (above 0.4 ms) no arm creeps at 1,470 um/s within 1 in 100.
#      B3  the 0.625 ms plays are byte-identical to run 020's kept suites' hold_16 files of the same switches.
#   C. Run 001's hold (1 kg, half-size 0.05 m, friction 0.5, 2.94 N from 0.5 s, 2 s) on SemiImplicit at 0.22 and
#      0.18 ms, with no switch, Study 1's only and both:
#      C1  at 0.18 ms (below 0.2 ms) every arm creeps at 2.94 N / 4,000 N s/m = 735 um/s, within 1 in 100.
#      C2  at 0.22 ms (above it) no arm does.
#   No play stops being a number, except where the release's own instability throws the cube (A2's cells).
# If A and B hold, run 020's failures of checks 2 and 3 are Newton's explicit integration, not the contact law: the
# 10 ms drop fails because the step is past the damper's monotone limit, and the 0.625 ms hold because it is past
# explicit friction's stability limit, where the patch changes a chatter, not a creep.
# usage: play.sh <sx_contact binary>   (repository root; NORMAL_VENV set to run 020's patched source's environment)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"
O=validation/run_021_explicit_limits; W=$O/runs; mkdir -p $W
: > $O/stats.txt; : > $O/log.txt
play() {  # <arm: rel|unit|both|normal> <solver> <file name> <rig settings...>
  local a=$1 s=$2 f=$3; shift 3
  ( . "$NORMAL_VENV/bin/activate"
    unset NEWTON_UNIT_FRICTION_DIRECTION NEWTON_CONTACT_DAMPING_NO_PULL
    case $a in unit|both) export NEWTON_UNIT_FRICTION_DIRECTION=1;; esac
    case $a in normal|both) export NEWTON_CONTACT_DAMPING_NO_PULL=1;; esac
    python tools/nwt_contact.py $W/$f "$@" solver=$s 2>> $O/log.txt | sed "s/^STATS/STATS $f/" >> $O/stats.txt )
}
DROP="radius=0.04 h0=0.08 mu=0 secs=0.5"
HOLD2="mass=2 radius=0.04 h0=0 mu=0.5 push=5.88 pushat=0.5 secs=2"
HOLD1="mass=1 radius=0.05 h0=0 mu=0.5 push=2.94 pushat=0.5 secs=2"
lane1() {  # the drops on SemiImplicit, half the holds
  local m dt a
  for m in 1 2 4; do for dt in 0.0025 0.005 0.01; do for a in rel both; do
    play $a semi drop_m${m}_${dt}_${a}_semi.txt dt=$dt mass=$m $DROP; done; done; done
  for a in rel unit; do for dt in 0.000625 0.00044 0.00036 0.00015625; do
    play $a semi hold2_${dt}_${a}.txt dt=$dt $HOLD2; done; done
  for dt in 0.00022 0.00018; do play rel semi hold1_${dt}_rel.txt dt=$dt $HOLD1; done
}
lane2() {  # the drops on Featherstone, the other holds
  local m dt a
  for m in 1 2 4; do for dt in 0.0025 0.005 0.01; do for a in rel both; do
    play $a featherstone drop_m${m}_${dt}_${a}_featherstone.txt dt=$dt mass=$m $DROP; done; done; done
  for a in both normal; do for dt in 0.000625 0.00044 0.00036 0.00015625; do
    play $a semi hold2_${dt}_${a}.txt dt=$dt $HOLD2; done; done
  for a in unit both; do for dt in 0.00022 0.00018; do play $a semi hold1_${dt}_${a}.txt dt=$dt $HOLD1; done; done
}
date -u +%FT%TZ > $O/started.txt
if [ -n "${NORMAL_SRC:-}" ]; then
  { git -C "$NORMAL_SRC" log --oneline -1; git -C "$NORMAL_SRC" status --short
    (cd "$NORMAL_SRC" && sha256sum newton/_src/solvers/semi_implicit/kernels_contact.py newton/_src/solvers/semi_implicit/kernels_contact_unit.py newton/_src/solvers/semi_implicit/kernels_contact_normal.py newton/_src/solvers/featherstone/solver_featherstone.py)
  } > $O/patched_source.txt
fi
lane1 & lane2 & wait   # two plays at a time
date -u +%FT%TZ > $O/finished.txt
pick() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
{
  echo "== A. the drop: rebound per 10,000 and steps to turn; with both switches against the release, byte for byte"
  for s in semi featherstone; do for m in 1 2 4; do for dt in 0.0025 0.005 0.01; do
    r=$("$B" bounce $W/drop_m${m}_${dt}_rel_$s.txt | tail -1); b=$("$B" bounce $W/drop_m${m}_${dt}_both_$s.txt | tail -1)
    if cmp -s $W/drop_m${m}_${dt}_rel_$s.txt $W/drop_m${m}_${dt}_both_$s.txt; then id=identical; else id=differs; fi
    echo "$s ${m} kg $dt s | release rebound_per_10000 $(echo "$r" | pick rebound_per_10000) steps_to_turn $(echo "$r" | pick steps_to_turn) | both rebound_per_10000 $(echo "$b" | pick rebound_per_10000) steps_to_turn $(echo "$b" | pick steps_to_turn) | files $id"
  done; done; done
  echo "== B. the suite's hold on SemiImplicit: mean speed, um/s (push over four corners' kf: 1,470)"
  for dt in 0.000625 0.00044 0.00036 0.00015625; do
    line="$dt s"
    for a in rel unit both normal; do line="$line | $a $("$B" creep $W/hold2_${dt}_$a.txt | tail -1 | pick mean_speed_ums)"; done
    echo "$line"
  done
  echo "== B3. the 0.625 ms holds against run 020's kept suites"
  for p in "rel r020_off_semi" "unit r020_offu_semi" "both r020_onu_semi" "normal r020_on_semi"; do
    set -- $p
    if cmp -s $W/hold2_0.000625_$1.txt suites/1/$2/hold_16.txt; then echo "$1 against $2 hold_16: identical"; else echo "$1 against $2 hold_16: differs"; fi
  done
  echo "== C. run 001's hold on SemiImplicit: mean speed, um/s (push over four corners' kf: 735)"
  for dt in 0.00022 0.00018; do
    line="$dt s"
    for a in rel unit both; do line="$line | $a $("$B" creep $W/hold1_${dt}_$a.txt | tail -1 | pick mean_speed_ums)"; done
    echo "$line"
  done
  echo "== plays: $(ls $W/*.txt | wc -l | tr -d ' '); that stopped being a number: $(grep -c nan_at_step $O/stats.txt)"
  grep nan_at_step $O/stats.txt | awk '{ print "stopped being a number:", $2 }'
} > $O/reading.txt
cat $O/reading.txt
