#!/usr/bin/env bash
# Run 046, a trace (not registered): XPBD's joint limit with the whole scene turned, before and past pi. Study 5's R4
# (run 037) asked an arm reaching a limit past pi to be held there; it failed because XPBD's limit throws an arm back
# off a limit before pi too (F14, traced in the source: apply_body_deltas leaves a position correction as speed). A
# later study can pose R4 against XPBD's own limit before pi instead. With no gravity, turning the whole scene (the
# arm's start and both limits by the same angle) changes nothing in the physics, so an arm whose limit lies past pi
# should play as the same arm with its limit before pi, once the angle is tracked past pi (the joint-angle patch).
# How close XPBD's plays come to each other when the scene is turned (its 32-bit arithmetic is not turn-invariant) is
# what such a rule's bound needs. Hypothesis: with the patch, XPBD's limit plays the same wherever the limit lies.
# Study 5's arm (1.5 kg, half-size 0.03 m, 0.3 m), no gravity, set turning at 3 rad/s from a start a0, limits a0 - 0.5
# and a0 + 2.5 rad, 1.4 s, on XPBD at 1.6 and 0.32 ms; a0 = 0 is Study 5's below. a0 = -1 and 0.5 keep the limit
# before pi; a0 = 1 and 2 put it past pi (3.5 and 4.5 rad).
# Predicted, before the plays:
#   P1  with the patch, every turned scene's last angle less its start is within 0.01 rad of a0 = 0's, and its last
#       speed within 0.01 rad/s of a0 = 0's, at both steps.
#   P2  as released, the scenes with the limit past pi are thrown (a last speed over 100 rad/s).
#   Reported, not predicted: as released, the turned scenes with the limit before pi. Check: a0 = 0 is run 037's
#   below byte for byte, as released and with the patch.
# usage: play.sh <sx_contact binary>   (repository root; STOCK_VENV and XLIM_VENV set: Newton 1.6.1 from PyPI, and
#        run 035's patched source)
set -u
B="${1:?usage: play.sh <sx_contact binary>}"
O=validation/run_046_xpbd_limit_rotated; W=$O/runs; mkdir -p $W
: > $W/log.txt
ARM="mass=1.5 radius=0.03 arm=0.3 gravity=0 omega0=3"
one() {  # <stock|on> <a0> <lo> <hi> <dt>
  local a=$1 a0=$2 lo=$3 hi=$4 dt=$5 venv
  if [ $a = stock ]; then venv="$STOCK_VENV"; else venv="$XLIM_VENV"; fi
  ( . "$venv/bin/activate"; unset NEWTON_XPBD_JOINT_ANGLE_UNWRAP; if [ $a = on ]; then export NEWTON_XPBD_JOINT_ANGLE_UNWRAP=1; fi
    python tools/nwt_joint.py $W/${a}_a${a0}_$dt.txt dt=$dt $ARM angle0=$a0 secs=1.4 lo=$lo hi=$hi solver=xpbd > $W/${a}_a${a0}_$dt.stats 2>> $W/log.txt )
}
date -u +%FT%TZ > $O/started.txt
for dt in 0.0016 0.00032; do
  for a in stock on; do
    one $a 0 -0.5 2.5 $dt &
    one $a -1 -1.5 1.5 $dt &
    one $a 0.5 0 3 $dt &
    wait
    one $a 1 0.5 3.5 $dt &
    one $a 2 1.5 4.5 $dt &
    wait
  done
done
date -u +%FT%TZ > $O/finished.txt
{
  for f in $W/*_0*.txt; do
    s=$(grep -o 'out_of_range_at_step [0-9]*\|nan_at_step [0-9]*' ${f%.txt}.stats || echo "plays")
    echo "$(basename $f .txt) | $s | $("$B" final $f | tail -1)"
  done
  for a in stock on; do for dt in 0.0016 0.00032; do
    if cmp -s $W/${a}_a0_$dt.txt validation/run_037_study_05/$a/runs/below_$dt.txt; then r=yes; else r=NO; fi
    echo "CHECK $a, a0 = 0, $dt s, byte-identical to run 037's below: $r"
  done; done
} > $O/reading.txt
cat $O/reading.txt
