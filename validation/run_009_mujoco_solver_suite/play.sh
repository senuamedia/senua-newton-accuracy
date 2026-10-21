#!/usr/bin/env bash
# Run 009, design probe (not registered): the MuJoCo solver on the first deep dive's ten contact tests. Run 007 could
# not read it: the suite's drop is frictionless, and the MuJoCo solver stops being a number at the first contact of a
# frictionless shape. MuJoCo's C engine raises any friction under 1e-5 to 1e-5 (mjMINMU) and plays on, so its own run
# of this suite (the MuJoCo deep dive's run 008) played the drop at 1e-5 in effect. Here the MuJoCo solver plays the
# suite with the drop's friction given as 1e-5 (the suite script's new SUITE_DROPMU), every other scene unchanged.
# A check on the suite script: XPBD's suite played again without SUITE_DROPMU must be byte-identical to run 007's.
# usage: play.sh <folder holding sx_contact and sx_contact_suite.sh>   (repository root, Newton's environment on)
set -u
M="$(cd "${1:?usage: play.sh <runner folder>}" && pwd)"
O=validation/run_009_mujoco_solver_suite; mkdir -p $O
SUITE_DROPMU=0.00001 tools/contact_suite.sh mujoco_dropmu solver=mujoco > $O/play_mujoco_dropmu.txt 2> $O/log_mujoco_dropmu.txt &
tools/contact_suite.sh xpbd_check solver=xpbd > $O/play_xpbd_check.txt 2> $O/log_xpbd_check.txt &
wait
bash "$M/sx_contact_suite.sh" suites/1/mujoco_dropmu suites/1/mujoco_dropmu/verdicts.txt > /dev/null 2>> $O/log_mujoco_dropmu.txt
echo "runner rc $?" >> $O/play_mujoco_dropmu.txt
n=0; same=0
for f in suites/1/xpbd/*_[0-9]*.txt suites/1/xpbd/stats.txt; do
  n=$((n + 1)); cmp -s $f suites/1/xpbd_check/$(basename $f) && same=$((same + 1))
done
{ echo "CHECK XPBD's suite without SUITE_DROPMU against run 007's: $same of $n files byte-identical"
  grep '^T[01][0-9]\|^SUITE' suites/1/mujoco_dropmu/verdicts.txt; } > $O/reading.txt
