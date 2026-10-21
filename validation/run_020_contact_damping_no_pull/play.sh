#!/usr/bin/env bash
# Run 020, a patch in design (not registered): patches/in_design/contact_damping_no_pull.diff, against Newton v1.6.1
# with Study 1's patches/unit_friction_direction.diff applied. Run 017 traced SemiImplicit's and Featherstone's rebound
# with a restitution of 0 (F11) to their body contact kernel damping the normal contact only while it closes,
# fd = min(vn, 0) * kd. The patch launches, only when NEWTON_CONTACT_DAMPING_NO_PULL=1 (read once, when
# kernels_contact is imported), a copy of the stock kernel, or of Study 1's copy when its switch is also set, whose
# normal force is the linear spring-dashpot in both phases kept from pulling: min(ke d + kd vn, 0) while the contact
# overlaps (Schwager and Poeschel 2007), with the shapes' own ke and kd.
# The five checks, on the first deep dive's ten-test suite (tools/contact_suite.sh, every scene unchanged), against
# the kept suites of runs 007 (Newton 1.6.1 from PyPI, as released and with Study 1's patch) and 013 (the MuJoCo
# solver with its elliptic cone):
#   r020_off_semi, r020_off_featherstone        the patched source, no switch: must be run 007's semi, featherstone
#   r020_offu_semi, r020_offu_featherstone      Study 1's switch only: must be run 007's semi_patched, featherstone_patched
#   r020_on_semi, r020_on_featherstone          the normal-contact switch only
#   r020_onu_semi, r020_onu_featherstone        both switches
#   r020_on_xpbd, r020_on_vbd, r020_on_mujoco_elliptic   the normal-contact switch on solvers that do not use the
#                                               kernel: must be run 007's xpbd and vbd and run 013's mujoco_elliptic
# Predicted, before the plays: with the normal-contact switch, a drop rebounds 0 from 5 ms down on both solvers. At
# 10 ms the suite's 2 kg cube is at the explicit damping's stability limit (4 kd dt / m = 2 with Newton's kd of 100 on
# four corners), so the 10 ms drop may not settle and T04 may fail on that one step. With both switches, the refinement
# chain falls at every step (T08 passes) and the three friction tests still pass; T01, T03 and T09 pass on every on
# arm; T06 and T07 still fail (the creep at rest, F4). Every off, offu and other-solver arm is byte-identical to its
# kept suite; no play stops being a number.
# usage: play.sh <folder holding sx_contact and sx_contact_suite.sh>   (repository root; NORMAL_VENV set to the patched
#        source's environment; NORMAL_SRC to that source, to record it)
set -u
M="$(cd "${1:?usage: play.sh <runner folder>}" && pwd)"
O=validation/run_020_contact_damping_no_pull; mkdir -p $O
arm() {  # <label> <unit switch 0|1> <normal switch 0|1> <rig settings...>
  local label=$1 u=$2 nm=$3; shift 3
  ( . "$NORMAL_VENV/bin/activate"
    if [ "$u" = 1 ]; then export NEWTON_UNIT_FRICTION_DIRECTION=1; else unset NEWTON_UNIT_FRICTION_DIRECTION; fi
    if [ "$nm" = 1 ]; then export NEWTON_CONTACT_DAMPING_NO_PULL=1; else unset NEWTON_CONTACT_DAMPING_NO_PULL; fi
    tools/contact_suite.sh $label "$@" > $O/play_$label.txt 2> $O/log_$label.txt
    bash "$M/sx_contact_suite.sh" suites/1/$label suites/1/$label/verdicts.txt > /dev/null 2>> $O/log_$label.txt
    echo "runner rc $?" >> $O/play_$label.txt )
}
date -u +%FT%TZ > $O/started.txt
if [ -n "${NORMAL_SRC:-}" ]; then
  { git -C "$NORMAL_SRC" log --oneline -1; git -C "$NORMAL_SRC" status --short
    (cd "$NORMAL_SRC" && sha256sum newton/_src/solvers/semi_implicit/kernels_contact.py newton/_src/solvers/semi_implicit/kernels_contact_unit.py newton/_src/solvers/semi_implicit/kernels_contact_normal.py newton/_src/solvers/featherstone/solver_featherstone.py)
  } > $O/patched_source.txt
fi
arm r020_on_semi 0 1 solver=semi &
arm r020_on_featherstone 0 1 solver=featherstone &
arm r020_onu_semi 1 1 solver=semi &
arm r020_onu_featherstone 1 1 solver=featherstone &
wait
arm r020_off_semi 0 0 solver=semi &
arm r020_off_featherstone 0 0 solver=featherstone &
arm r020_offu_semi 1 0 solver=semi &
arm r020_offu_featherstone 1 0 solver=featherstone &
wait
arm r020_on_xpbd 0 1 solver=xpbd &
arm r020_on_vbd 0 1 solver=vbd &
arm r020_on_mujoco_elliptic 0 1 solver=mujoco opt.cone=elliptic &
wait
date -u +%FT%TZ > $O/finished.txt
same() {  # <label a> <label b>: the play files (not stats.txt or CONFIG) byte for byte
  local n=0 d=0 f
  for f in suites/1/$1/*_[0-9]*.txt; do
    n=$((n + 1)); cmp -s "$f" "suites/1/$2/$(basename "$f")" || { d=$((d + 1)); echo "DIFFERS $1 $2 $(basename "$f")"; }
  done
  echo "IDENTITY $1 against $2: $((n - d)) of $n byte-identical"
}
{
  for l in r020_on_semi r020_on_featherstone r020_onu_semi r020_onu_featherstone; do
    echo "== $l ($(tail -1 $O/play_$l.txt)); plays that stopped being a number: $(grep -c nan_at_step suites/1/$l/stats.txt)"
    grep '^T[01][0-9]\|^SUITE' suites/1/$l/verdicts.txt
  done
  echo "== safe when off, and nothing on the other solvers"
  same r020_off_semi semi
  same r020_off_featherstone featherstone
  same r020_offu_semi semi_patched
  same r020_offu_featherstone featherstone_patched
  same r020_on_xpbd xpbd
  same r020_on_vbd vbd
  same r020_on_mujoco_elliptic mujoco_elliptic
  echo "== the drop's rebound at each step, with the normal-contact switch"
  for l in r020_on_semi r020_on_featherstone r020_onu_semi r020_onu_featherstone; do
    for k in 1 2 4 8 16 32 64; do echo "$l drop 1/$k | $("$M/sx_contact" bounce suites/1/$l/drop_$k.txt | tail -1)"; done
  done
  echo "== the refinement chain's rebound after the landing, both switches"
  for l in r020_onu_semi r020_onu_featherstone; do
    for k in 4 8 16 32 64; do echo "$l chain 1/$k | $("$M/sx_contact" bounce suites/1/$l/chain_$k.txt | tail -1)"; done
  done
  echo "== the depth at rest, the rig's last line (nm): as released, normal-contact switch"
  for k in 1 16; do echo "rest 1/$k | semi $(tail -1 suites/1/semi/rest_$k.txt | cut -d' ' -f2) $(tail -1 suites/1/r020_on_semi/rest_$k.txt | cut -d' ' -f2) | featherstone $(tail -1 suites/1/featherstone/rest_$k.txt | cut -d' ' -f2) $(tail -1 suites/1/r020_on_featherstone/rest_$k.txt | cut -d' ' -f2)"; done
} > $O/reading.txt
