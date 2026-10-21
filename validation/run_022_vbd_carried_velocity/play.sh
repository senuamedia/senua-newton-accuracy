#!/usr/bin/env bash
# Run 022, a patch in design (not registered): patches/in_design/vbd_carried_velocity.diff, against Newton v1.6.1.
# Runs 001 and 006 found that VBD's bodies stop falling, in a way that fits positions held in 32-bit floats (F2). The
# cause, read in the source: after its solve, VBD reads each body's velocity back from its positions,
# v = (x - x_prev) / dt (rigid_vbd_kernels.update_body_velocity). The difference of two 32-bit positions is a whole
# number of their spacing u at the body's height, so each step adds round(g dt^2 / u) spacings to the speed instead of
# g dt^2 / u. That gives run 006's readings to the unit: at the centre's 0.15 m (u 14.9 nm), 0.031 ms, round(0.64) = 1,
# 15,258 mm/s2; 0.125 ms, round(10.28) = 10, 9,537 (read 9,536); at 1.05 m (u 119 nm), 0.125 ms, round(1.28) = 1, 7,629;
# 0.031 ms, round(0.08) = 0, no fall; at 10.05 m (u 954 nm) round(0.16) and round(0.01), no fall.
# The patch launches, only when NEWTON_VBD_CARRIED_VELOCITY=1 (read once, when solver_vbd is imported), a copy of that
# kernel whose linear velocity is v_forward + (x - x_inertia) / dt: the same quantity in exact arithmetic, since the
# forward step's target is x_inertia = x_prev + dt v_forward, without subtracting two distant rounded positions. The
# angular velocity and kinematic bodies are as in the stock kernel; nothing is fitted.
# The five checks, on VBD and VBD-ALM:
#   r022_off_vbd, r022_off_vbd_alm   the ten-test suite on the patched source, no switch: must be run 007's vbd, vbd_alm
#   r022_on_vbd, r022_on_vbd_alm     the suite with the switch
#   drops                            the suite's cube (2 kg, half-size 0.04 m, friction 0) dropped from 1 m and 10 m at
#                                    0.125 and 0.03125 ms, off and on
#   run 006's falls                  its 16 VBD and VBD-ALM plays again, off (must be run 006's files) and on
# Predicted, before the plays:
#   S1  off: 39 of 39 suite files byte-identical to run 007's on each solver, and 16 of 16 of run 006's falls.
#   C1  on: every drop lands at sqrt(2 g h0), 4,427,189 um/s from 1 m and 14,000,000 um/s from 10 m, within 1 in 1,000
#       (bounce, speed_in) at both steps on both solvers. Off, the 10 m drops and the 1 m drop at 0.03125 ms never land
#       (the cube does not fall), and the 1 m drop at 0.125 ms lands at a wrong speed.
#   C2  on: the suite's free plays (10 m up, every step 10 ms to 0.156 ms) are byte-identical to SemiImplicit's
#       (suites/1/semi/free_*): with nothing touching the body, VBD's solve leaves the forward step's pose, and the
#       forward step is the same integrator, so T01 passes as it does there.
#   C3  on: the suite's runner reads every test on both solvers (as released it stops short: 36 and 39 of 48 numbers).
#   K   no play stops being a number.
#   Not predicted, the third check: for every line the release's runner did measure against a right answer (the
#   slide's friction, 4,000 per 10,000; the rest's force, 19,600 mN; the hold, 0 um/s; the slip, 980,000 um/s; the
#   lift's and rebound's lowest ground force, 0 or more) the patch must read no further from it. Contact acts on
#   positions in VBD, so its per-step effects stay rounded to the spacing; the patch only stops the velocity
#   losing them a second time.
# usage: play.sh <folder holding sx_contact and sx_contact_suite.sh>   (repository root; VBD_VENV set to the patched
#        source's environment; VBD_SRC to that source, to record it)
set -u
M="$(cd "${1:?usage: play.sh <runner folder>}" && pwd)"
O=validation/run_022_vbd_carried_velocity; W=$O/runs; mkdir -p $W
: > $W/stats.txt; : > $O/log.txt
sw() { if [ "$1" = on ]; then export NEWTON_VBD_CARRIED_VELOCITY=1; else unset NEWTON_VBD_CARRIED_VELOCITY; fi; }
suite() {  # <off|on> <solver>
  local a=$1 s=$2
  ( . "$VBD_VENV/bin/activate"; sw $a
    tools/contact_suite.sh r022_${a}_$s solver=$s > $O/play_r022_${a}_$s.txt 2>> $O/log.txt
    bash "$M/sx_contact_suite.sh" suites/1/r022_${a}_$s suites/1/r022_${a}_$s/verdicts.txt > /dev/null 2>> $O/log.txt
    echo "runner rc $?" >> $O/play_r022_${a}_$s.txt )
}
one() {  # <off|on> <file> <rig settings...>
  local a=$1 f=$2; shift 2
  ( . "$VBD_VENV/bin/activate"; sw $a
    python tools/nwt_contact.py $W/$f "$@" 2>> $O/log.txt | sed "s/^STATS/STATS $f/" >> $W/stats.txt )
}
drops() {  # <solver>
  local s=$1 a h0 secs dt
  for a in off on; do for h0 in 1 10; do for dt in 0.000125 0.00003125; do
    if [ $h0 = 1 ]; then secs=0.6; else secs=1.6; fi
    one $a drop_${s}_${h0}_${dt}_$a.txt dt=$dt mass=2 radius=0.04 h0=$h0 mu=0 secs=$secs solver=$s
  done; done; done
}
falls() {  # run 006's VBD and VBD-ALM plays, as its probe.sh made them
  local a s h0 dt
  for a in off on; do for s in vbd vbd_alm; do for h0 in 0.01 0.1 1 10; do for dt in 0.000125 0.00003125; do
    one $a fall_${s}_${h0}_${dt}_$a.txt dt=$dt h0=$h0 mu=0.5 secs=0.05 solver=$s
  done; done; done; done
}
date -u +%FT%TZ > $O/started.txt
if [ -n "${VBD_SRC:-}" ]; then
  { git -C "$VBD_SRC" status --short
    (cd "$VBD_SRC" && sha256sum newton/_src/solvers/vbd/solver_vbd.py newton/_src/solvers/vbd/rigid_velocity_carried.py newton/_src/solvers/vbd/rigid_vbd_kernels.py)
    . "$VBD_VENV/bin/activate"; pip freeze
  } > $O/patched_source.txt 2>&1
fi
( suite off vbd; suite on vbd; drops vbd ) &
( suite off vbd_alm; suite on vbd_alm; drops vbd_alm; falls ) &
wait
date -u +%FT%TZ > $O/finished.txt
same() {  # <dir a> <dir b> <glob>: files byte for byte
  local n=0 d=0 f
  for f in $1/$3; do
    n=$((n + 1)); cmp -s "$f" "$2/$(basename "$f")" || { d=$((d + 1)); echo "DIFFERS $(basename "$f")"; }
  done
  echo "IDENTITY $1 against $2 ($3): $((n - d)) of $n byte-identical"
}
pick() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
{
  echo "== S1. safe when off"
  same suites/1/r022_off_vbd suites/1/vbd '*_[0-9]*.txt'
  same suites/1/r022_off_vbd_alm suites/1/vbd_alm '*_[0-9]*.txt'
  n=0; d=0
  for f in $W/fall_*_off.txt; do
    g=validation/run_006_vbd_free_fall/runs/$(basename "$f" _off.txt).txt; n=$((n + 1))
    cmp -s "$f" "$g" || { d=$((d + 1)); echo "DIFFERS $(basename "$f")"; }
  done
  echo "IDENTITY run 006's falls replayed off: $((n - d)) of $n byte-identical"
  echo "== C1. the drops: speed at landing, um/s (from 1 m 4,427,189; from 10 m 14,000,000)"
  for s in vbd vbd_alm; do for h0 in 1 10; do for dt in 0.000125 0.00003125; do
    line="$s from $h0 m at $dt s"
    for a in off on; do
      l=$("$M/sx_contact" bounce $W/drop_${s}_${h0}_${dt}_$a.txt | tail -1)
      v=$(echo "$l" | pick speed_in_ums); line="$line | $a ${v:-$(echo "$l" | cut -d' ' -f4-)}"
    done
    echo "$line"
  done; done; done
  echo "== C2. the suite's free plays with the switch against SemiImplicit's"
  same suites/1/r022_on_vbd suites/1/semi 'free_*.txt'
  same suites/1/r022_on_vbd_alm suites/1/semi 'free_*.txt'
  echo "== C3 and the third check: the suite's verdicts and measured lines"
  for l in r022_on_vbd r022_on_vbd_alm; do
    echo "-- $l ($(tail -1 $O/play_$l.txt)); plays that stopped being a number: $(grep -c nan_at_step suites/1/$l/stats.txt)"
    grep '^T[01][0-9]\|^SUITE' suites/1/$l/verdicts.txt
    grep '^slide\|^rest\|^hold\|^slip\|^lift\|^rebound' suites/1/$l/verdicts.txt
  done
  for l in vbd vbd_alm; do
    echo "-- $l as released (run 007)"
    grep '^slide\|^rest\|^hold\|^slip\|^lift\|^rebound' suites/1/$l/verdicts.txt
  done
  echo "== run 006's falls with the switch against XPBD's (reported)"
  for f in $W/fall_*_on.txt; do
    b=$(basename "$f" _on.txt)
    case $b in fall_vbd_alm_*) x=fall_xpbd_${b#fall_vbd_alm_}.txt;; *) x=fall_xpbd_${b#fall_vbd_}.txt;; esac
    x=validation/run_006_vbd_free_fall/runs/$x
    if cmp -s "$f" "$x"; then echo "$b on against $(basename $x): identical"; else echo "$b on against $(basename $x): differs"; fi
  done
  echo "== single plays that stopped being a number: $(grep -c nan_at_step $W/stats.txt)"
} > $O/reading.txt
cat $O/reading.txt
