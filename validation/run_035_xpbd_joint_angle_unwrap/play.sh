#!/usr/bin/env bash
# Run 035, a patch in design (not registered): patches/in_design/xpbd_joint_angle_unwrap.diff, against Newton v1.6.1.
# Run 032 (F13) found XPBD throwing a joint that turns past pi inside limits it never reaches: its joint solve
# (kernels.solve_body_joints) takes the angle from the swing-twist split of the joint's relative rotation after putting
# the two quaternions in the same hemisphere, so the angle compared with the limits lies in [-pi, pi]. The patch launches,
# only when NEWTON_XPBD_JOINT_ANGLE_UNWRAP=1 (read once, when solver_xpbd is imported), a copy of that kernel which keeps
# each revolute joint's last angle, unwrapped, and adds the whole turns 2 pi k, k = round((last - measured) / 2 pi), that
# bring the measured angle nearest the last: the standard unwrapping of a periodic reading. Where k is 0 the solve is
# the stock kernel's to the bit. The last angles start from the state's joint coordinates.
# The five checks, on XPBD, the patched source's environment (off: no switch; on: the switch):
#   turn       run 032's scene (the straight chain turning at 2 rad/s, 1.9 s) with limits -1 and 4 rad, and with none,
#              at 2.5 and 0.625 ms, off and on
#   stop       the same chain with limits -1 and 3.5 rad, which it reaches past pi, at 2.5 and 0.625 ms, off and on
#   chains     run 014's free and swinging chains at 10 ms over 1, 4, 16 and 64, on
#   suite      the first deep dive's ten-test suite (r035_on_xpbd), on: no joint but each body's free joint
# Predicted, before the plays:
#   S   off: run 032's XPBD turn files byte-identical (4 of 4).
#   C1  on: the chain with limits -1 and 4 rad plays as with none: byte-identical to run 032's play without limits, at
#       both steps.
#   C2  on: the chain with limits -1 and 3.5 rad ends held at its upper limit: the first joint within 0.05 rad of
#       3.5 rad and slower than 0.1 rad/s at the end, at both steps. Off it is thrown (faster than 100 rad/s).
#   N   on: run 014's eight XPBD chain files byte-identical (nothing passes pi with a limit there, and with no limit the
#       angle compares with nothing), and the suite's 39 files byte-identical to run 007's XPBD suite.
#   K   no play stops being a number.
# usage: play.sh <sx_contact binary>   (repository root; XLIM_VENV and XLIM_SRC set)
set -u
B="${1:?usage: play.sh <sx_contact binary>}"
O=validation/run_035_xpbd_joint_angle_unwrap; W=$O/runs; mkdir -p $W
: > $W/log.txt
ARMS="mass1=1.2 mass2=0.6 radius=0.04 arm1=0.25 len1=0.5 arm2=0.2"
TURN="gravity=0 angle1=0 angle2=0 omega1=2 omega2=0 secs=1.9"
FREE="gravity=0 angle2=-0.9 omega1=2.5 omega2=1.5 secs=2"
SWING="gravity=1 angle1=0.4 angle2=-0.7 secs=2"
dt_of() { awk -v k=$1 'BEGIN { printf "%.12f", 0.01 / k }'; }
one() {  # <off|on> <name> <dt> <rig settings...>
  local a=$1 n=$2 dt=$3; shift 3
  ( . "$XLIM_VENV/bin/activate"; if [ $a = on ]; then export NEWTON_XPBD_JOINT_ANGLE_UNWRAP=1; else unset NEWTON_XPBD_JOINT_ANGLE_UNWRAP; fi
    python tools/nwt_chain.py $W/${n}_${dt}_$a.txt dt=$dt $ARMS "$@" solver=xpbd > $W/${n}_${dt}_$a.stats 2>> $W/log.txt )
}
date -u +%FT%TZ > $O/started.txt
if [ -n "${XLIM_SRC:-}" ]; then
  { git -C "$XLIM_SRC" status --short
    (cd "$XLIM_SRC" && sha256sum newton/_src/solvers/xpbd/solver_xpbd.py newton/_src/solvers/xpbd/joint_angle_unwrap_kernels.py newton/_src/solvers/xpbd/kernels.py)
  } > $O/patched_source.txt
fi
( for a in off on; do for dt in 0.0025 0.000625; do one $a turn_lim $dt $TURN lo1=-1 hi1=4; one $a turn_free $dt $TURN; done; done ) &
( for a in off on; do for dt in 0.0025 0.000625; do one $a stop_lim $dt $TURN lo1=-1 hi1=3.5; done; done ) &
( for k in 1 4 16 64; do one on free_xpbd $(dt_of $k) $FREE; one on swing_xpbd $(dt_of $k) $SWING; done ) &
( . "$XLIM_VENV/bin/activate"; export NEWTON_XPBD_JOINT_ANGLE_UNWRAP=1
  tools/contact_suite.sh r035_on_xpbd solver=xpbd > $O/play_suite.txt 2>> $W/log.txt ) &
wait
date -u +%FT%TZ > $O/finished.txt
pick() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
{
  n=0; d=0
  for dt in 0.0025 0.000625; do for x in lim free; do n=$((n + 1))
    cmp -s $W/turn_${x}_${dt}_off.txt validation/run_032_joint_limit_past_pi/runs/turn_xpbd_${x}_$dt.txt || { d=$((d + 1)); echo "DIFFERS turn_${x}_${dt}_off"; }
  done; done
  echo "S off against run 032: $((n - d)) of $n byte-identical"
  for dt in 0.0025 0.000625; do
    if cmp -s $W/turn_lim_${dt}_on.txt validation/run_032_joint_limit_past_pi/runs/turn_xpbd_free_$dt.txt; then r=yes; else r=NO; fi
    echo "C1 on, limits -1 and 4, $dt s, byte-identical to run 032's play without limits: $r"
  done
  for a in off on; do for dt in 0.0025 0.000625; do
    l=$("$B" chain $W/stop_lim_${dt}_$a.txt | tail -1)
    echo "C2 $a limits -1 and 3.5, $dt s | angle1_urad $(echo "$l" | pick angle1_urad) speed1_urads $(echo "$l" | pick speed1_urads)"
  done; done
  for a in off on; do for dt in 0.0025 0.000625; do for x in lim free; do
    l=$("$B" chain $W/turn_${x}_${dt}_$a.txt | tail -1)
    echo "turn $x $a $dt s | angle1_urad $(echo "$l" | pick angle1_urad) speed1_urads $(echo "$l" | pick speed1_urads)"
  done; done; done
  n=0; d=0
  for k in 1 4 16 64; do for sc in free swing; do n=$((n + 1))
    cmp -s $W/${sc}_xpbd_$(dt_of $k)_on.txt validation/run_014_chain/runs/${sc}_xpbd_$k.txt || { d=$((d + 1)); echo "DIFFERS ${sc}_xpbd_$k"; }
  done; done
  echo "N on, run 014's XPBD chains: $((n - d)) of $n byte-identical"
  n=0; d=0
  for f in suites/1/r035_on_xpbd/*_[0-9]*.txt; do n=$((n + 1)); cmp -s $f suites/1/xpbd/$(basename $f) || { d=$((d + 1)); echo "DIFFERS $(basename $f)"; }; done
  echo "N on, the suite against run 007's XPBD suite: $((n - d)) of $n byte-identical"
  echo "K plays that stopped being a number: $(cat $W/*.stats suites/1/r035_on_xpbd/stats.txt | grep -c nan_at_step)"
} > $O/reading.txt
cat $O/reading.txt
