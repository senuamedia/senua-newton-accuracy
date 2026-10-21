#!/usr/bin/env bash
# Run 026, a patch in design (not registered): the second form of the VBD carried-velocity patch,
# patches/in_design/vbd_carried_velocity_v2.diff, switch NEWTON_VBD_CARRIED_VELOCITY=2. Run 022's first form (switch 1,
# kept unchanged in this file) carries the linear velocity and gives free fall as SemiImplicit and XPBD do, but in run
# 025 it left the chain's excess loss at 0.156 ms in place and made some chain readings worse, and in run 022 two of
# VBD's suite lines read slightly further from their answers. Hypothesis: with the linear velocity carried and the
# angular one still read back from 32-bit quaternions, a joint anchor's velocity, v + w x r, joins an exact part to a
# rounded one. The second form carries the angular velocity as well: the forward step's turn computed from its own
# angular velocity, w_forward 2 atan(dt |w_forward| / 2) / (dt |w_forward|), which is what the stock read-back gives
# for that turn in exact arithmetic, plus the solve's own turn read from two nearby quaternions. Nothing is fitted.
# On the patched source (run 022's environment, its source now carrying the second form):
#   r026_off_vbd, r026_off_vbd_alm     the suite, no switch: must be run 007's vbd, vbd_alm
#   r026_on1_vbd, r026_on1_vbd_alm     the suite, switch 1: must be run 022's r022_on_vbd, r022_on_vbd_alm
#   r026_on2_vbd, r026_on2_vbd_alm     the suite, switch 2
#   chains                             run 014's free and swinging chains on VBD and VBD-ALM at 10 ms over 1, 4, 16
#                                      and 64: off (must be run 014's), switch 1 (must be run 025's on files), switch 2
# Predicted, before the plays:
#   S   off: 39 of 39 suite files on each solver byte-identical to run 007's, 16 of 16 chain files to run 014's;
#       switch 1: 39 of 39 on each to run 022's, 16 of 16 chain files to run 025's.
#   C   switch 2: the suite's free plays byte-identical to SemiImplicit's on both solvers (nothing turns in them).
#   P1  switch 2: the free chain loses less at 0.156 ms than at 0.625 ms on both solvers, and no chain reading
#       (the free chain's energy and momentum after 2 s, the swinging chain's largest energy departure) is further
#       from its answer than as released, at any step.
#   P2  switch 2: every suite line the release measured against a right answer (the slide's friction, the rest's
#       force, the hold, the slip, the lift's and rebound's lowest ground force) reads no further from it.
#   K   no play stops being a number.
# usage: play.sh <folder holding sx_contact and sx_contact_suite.sh>   (repository root; VBD_VENV and VBD_SRC set)
set -u
M="$(cd "${1:?usage: play.sh <runner folder>}" && pwd)"
O=validation/run_026_vbd_carried_velocity_v2; W=$O/runs; mkdir -p $W
: > $O/log.txt
ARMS="mass1=1.2 mass2=0.6 radius=0.04 arm1=0.25 len1=0.5 arm2=0.2"
FREE="gravity=0 angle2=-0.9 omega1=2.5 omega2=1.5 secs=2"
SWING="gravity=1 angle1=0.4 angle2=-0.7 secs=2"
dt_of() { awk -v k=$1 'BEGIN { printf "%.12f", 0.01 / k }'; }
sw() { if [ "$1" = off ]; then unset NEWTON_VBD_CARRIED_VELOCITY; else export NEWTON_VBD_CARRIED_VELOCITY=${1#on}; fi; }
suite() {  # <off|on1|on2> <solver>
  local a=$1 s=$2
  ( . "$VBD_VENV/bin/activate"; sw $a
    tools/contact_suite.sh r026_${a}_$s solver=$s > $O/play_r026_${a}_$s.txt 2>> $O/log.txt
    bash "$M/sx_contact_suite.sh" suites/1/r026_${a}_$s suites/1/r026_${a}_$s/verdicts.txt > /dev/null 2>> $O/log.txt
    echo "runner rc $?" >> $O/play_r026_${a}_$s.txt )
}
chains() {  # <off|on1|on2> <vbd|vbd_alm>
  local a=$1 c=$2 k sc S X
  ( . "$VBD_VENV/bin/activate"; sw $a
    if [ $c = vbd ]; then X="solver=vbd"; else X="solver=vbd opt.rigid_compliant_alm=true"; fi
    for k in 1 4 16 64; do for sc in free swing; do
      if [ $sc = free ]; then S="$FREE"; else S="$SWING"; fi
      python tools/nwt_chain.py $W/${sc}_${c}_${k}_$a.txt dt=$(dt_of $k) $ARMS $S $X > $W/${sc}_${c}_${k}_$a.stats 2> $W/${sc}_${c}_${k}_$a.log
    done; done )
}
date -u +%FT%TZ > $O/started.txt
if [ -n "${VBD_SRC:-}" ]; then
  { git -C "$VBD_SRC" status --short
    (cd "$VBD_SRC" && sha256sum newton/_src/solvers/vbd/solver_vbd.py newton/_src/solvers/vbd/rigid_velocity_carried.py newton/_src/solvers/vbd/rigid_vbd_kernels.py)
  } > $O/patched_source.txt 2>&1
fi
( suite on2 vbd; suite off vbd; chains on2 vbd ) &
( suite on2 vbd_alm; suite off vbd_alm; chains on2 vbd_alm ) &
( suite on1 vbd_alm; chains off vbd; chains off vbd_alm ) &
( suite on1 vbd; chains on1 vbd; chains on1 vbd_alm ) &
wait
date -u +%FT%TZ > $O/finished.txt
same() {  # <dir a> <dir b> <glob> <label>
  local n=0 d=0 f
  for f in $1/$3; do
    n=$((n + 1)); cmp -s "$f" "$2/$(basename "$f")" || { d=$((d + 1)); echo "DIFFERS $(basename "$f")"; }
  done
  echo "IDENTITY $4: $((n - d)) of $n byte-identical"
}
samechain() {  # <arm> <folder> <suffix there>: the chain files of one arm against another run's
  local a=$1 g=$2 x=$3 n=0 d=0 f
  for f in $W/*_$a.txt; do
    n=$((n + 1)); cmp -s "$f" "$g/$(basename "$f" _$a.txt)$x.txt" || { d=$((d + 1)); echo "DIFFERS $(basename "$f")"; }
  done
  echo "IDENTITY chains $a against $g: $((n - d)) of $n byte-identical"
}
{
  echo "== S. safe when off, and the first form unchanged"
  same suites/1/r026_off_vbd suites/1/vbd '*_[0-9]*.txt' "suite off vbd against run 007"
  same suites/1/r026_off_vbd_alm suites/1/vbd_alm '*_[0-9]*.txt' "suite off vbd_alm against run 007"
  same suites/1/r026_on1_vbd suites/1/r022_on_vbd '*_[0-9]*.txt' "suite switch 1 vbd against run 022"
  same suites/1/r026_on1_vbd_alm suites/1/r022_on_vbd_alm '*_[0-9]*.txt' "suite switch 1 vbd_alm against run 022"
  samechain off validation/run_014_chain/runs ""
  samechain on1 validation/run_025_vbd_chain_carried_velocity/runs "_on"
  echo "== C. the free plays with switch 2 against SemiImplicit's"
  same suites/1/r026_on2_vbd suites/1/semi 'free_*.txt' "free switch 2 vbd against semi"
  same suites/1/r026_on2_vbd_alm suites/1/semi 'free_*.txt' "free switch 2 vbd_alm against semi"
  echo "== P1. the chains: off, switch 1, switch 2"
  for c in vbd vbd_alm; do for sc in free swing; do for k in 1 4 16 64; do for a in off on1 on2; do
    s=$(grep -o 'out_of_range_at_step [0-9]*\|nan_at_step [0-9]*' $W/${sc}_${c}_${k}_$a.stats || echo "plays")
    echo "$sc $c 1/$k $a | $s | $("$M/sx_contact" chain $W/${sc}_${c}_${k}_$a.txt | tail -1)"
  done; done; done; done
  echo "== P2. the suite with switch 2"
  for l in r026_on2_vbd r026_on2_vbd_alm; do
    echo "-- $l ($(tail -1 $O/play_$l.txt)); plays that stopped being a number: $(grep -c nan_at_step suites/1/$l/stats.txt)"
    grep '^T[01][0-9]\|^SUITE' suites/1/$l/verdicts.txt
    grep '^slide\|^rest\|^hold\|^slip\|^lift\|^rebound' suites/1/$l/verdicts.txt
  done
} > $O/reading.txt
cat $O/reading.txt
