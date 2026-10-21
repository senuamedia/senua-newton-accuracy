#!/usr/bin/env bash
# Run 015, design probe (not registered): XPBD's bounce with a restitution of 0 (finding F5), against XPBD's own
# option enable_restitution. As released (run 007) a cube dropped 80 mm with a restitution of 0 rebounds 382 to 1,125
# parts in 10,000 of the drop height, more as the step shrinks, and fails the bounce test (T04).
# Prediction, written before the plays, from Newton's source (newton/_src/solvers/xpbd): XPBD resolves the contact by
# moving the body out of the ground and takes the body's velocity from how far it moved in the step, so the push
# that undoes the penetration leaves the contact as an upward speed. XPBD's velocity-level restitution pass is off by
# default (enable_restitution=False); switched on with the shape's restitution of 0 (Newton's default), it sets a
# contact's separating speed toward 0 times the speed it arrived with. So with enable_restitution:
#   - the rebound falls under 100 parts in 10,000 (1% of the drop) at every step, and T04 passes;
#   - the hold still creeps (T06 fails): that is friction's, not the bounce's.
# The first deep dive's ten-test suite, every scene unchanged (tools/contact_suite.sh), on XPBD with
# opt.enable_restitution=true; read by its own runner, sx_contact_suite.sh, and each drop by sx_contact bounce. The
# plays are under suites/1/xpbd_restitution/.
# usage: play.sh <folder holding sx_contact and sx_contact_suite.sh>   (repository root, Newton's environment on)
set -u
M="$(cd "${1:?usage: play.sh <runner folder>}" && pwd)"
O=validation/run_015_xpbd_restitution; mkdir -p $O
L=xpbd_restitution
date -u +%FT%TZ > $O/started.txt
tools/contact_suite.sh $L solver=xpbd opt.enable_restitution=true > $O/play.txt 2> $O/log.txt
bash "$M/sx_contact_suite.sh" suites/1/$L suites/1/$L/verdicts.txt > /dev/null 2>> $O/log.txt
echo "runner rc $?" >> $O/play.txt
date -u +%FT%TZ > $O/finished.txt
{ grep '^T[01][0-9]\|^SUITE' suites/1/$L/verdicts.txt
  for k in 1 2 4 8 16 32 64; do echo "drop 1/$k | $("$M/sx_contact" bounce suites/1/$L/drop_$k.txt | tail -1)"; done
  # beside them, run 007's drops on XPBD as released, read the same way
  for k in 1 2 4 8 16 32 64; do echo "as released, drop 1/$k | $("$M/sx_contact" bounce suites/1/xpbd/drop_$k.txt | tail -1)"; done
} > $O/reading.txt
