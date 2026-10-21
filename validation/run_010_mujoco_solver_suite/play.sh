#!/usr/bin/env bash
# Run 010, design probe (not registered): the MuJoCo solver on the first deep dive's ten contact tests, every scene the
# suite leaves frictionless (the drop, the rest, the lift, the fast rebound) given a friction of 2e-5, just above
# MuJoCo Warp's floor of 1e-5, which 32-bit floats cannot hold exactly (run 009); none of those four tests reads
# friction. The suite script's new SUITE_ZEROMU; a difference from the first deep dive's suite, stated as such.
# A check on the suite script: XPBD's suite played again without the setting must be byte-identical to run 007's.
# usage: play.sh <folder holding sx_contact and sx_contact_suite.sh>   (repository root, Newton's environment on)
set -u
M="$(cd "${1:?usage: play.sh <runner folder>}" && pwd)"
O=validation/run_010_mujoco_solver_suite; mkdir -p $O
SUITE_ZEROMU=0.00002 tools/contact_suite.sh mujoco_zeromu solver=mujoco > $O/play_mujoco_zeromu.txt 2> $O/log_mujoco_zeromu.txt &
tools/contact_suite.sh xpbd_check2 solver=xpbd > $O/play_xpbd_check2.txt 2> $O/log_xpbd_check2.txt &
wait
bash "$M/sx_contact_suite.sh" suites/1/mujoco_zeromu suites/1/mujoco_zeromu/verdicts.txt > /dev/null 2>> $O/log_mujoco_zeromu.txt
echo "runner rc $?" >> $O/play_mujoco_zeromu.txt
n=0; same=0
for f in suites/1/xpbd/*_[0-9]*.txt suites/1/xpbd/stats.txt; do
  n=$((n + 1)); cmp -s $f suites/1/xpbd_check2/$(basename $f) && same=$((same + 1))
done
{ echo "CHECK XPBD's suite without SUITE_ZEROMU against run 007's: $same of $n files byte-identical"
  echo "plays that stopped being a number: $(grep -c nan_at_step suites/1/mujoco_zeromu/stats.txt)"
  grep '^T[01][0-9]\|^SUITE' suites/1/mujoco_zeromu/verdicts.txt; } > $O/reading.txt
