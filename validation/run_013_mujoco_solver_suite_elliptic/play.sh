#!/usr/bin/env bash
# Run 013, design probe (not registered): Newton's MuJoCo solver on the first deep dive's ten contact tests with the
# elliptic cone (opt.cone=elliptic). Runs 009 and 010 could not read it with its default pyramidal cone, which stops
# being a number on the suite's frictionless scenes; run 012 traced that to the pyramid and found the elliptic cone
# plays every friction. Every scene as the first deep dive's suite has it (no friction setting changed).
# usage: play.sh <folder holding sx_contact and sx_contact_suite.sh>   (repository root, Newton's environment on)
set -u
M="$(cd "${1:?usage: play.sh <runner folder>}" && pwd)"
O=validation/run_013_mujoco_solver_suite_elliptic; mkdir -p $O
tools/contact_suite.sh mujoco_elliptic solver=mujoco opt.cone=elliptic > $O/play.txt 2> $O/log.txt
bash "$M/sx_contact_suite.sh" suites/1/mujoco_elliptic suites/1/mujoco_elliptic/verdicts.txt > /dev/null 2>> $O/log.txt
echo "runner rc $?" >> $O/play.txt
{ echo "plays that stopped being a number: $(grep -c nan_at_step suites/1/mujoco_elliptic/stats.txt)"
  grep '^T[01][0-9]\|^SUITE' suites/1/mujoco_elliptic/verdicts.txt; } > $O/reading.txt
