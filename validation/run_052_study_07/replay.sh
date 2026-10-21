#!/usr/bin/env bash
# Run 052 (Study 7, preregistrations/PREREGISTRATION_07.md): every run of the record played again by its own script on
# one engine, in a clean copy of the repository. Each run's kept outputs are cleared first (its README, its scripts and
# its dry run kept), then the runs are played in order, so a run that reads an earlier run's files reads the replayed
# ones. Each script gets its engines from the environment variables it names, all pointed at the engine given; a script
# that plays the release with the environment on runs with the base environment on. As the record does, the home
# folder is written ~ in every text file afterwards. The exit status of every script goes into replay_status.txt.
# usage: replay.sh <engine folder from setup_engine.sh> <measure folder> [run ...]   (from the root of the clean copy)
#   measure folder: holds sx_contact and sx_contact_suite.sh. With DRY=1 only runs 006 and 011 are played.
set -u
E="$(cd "${1:?usage: replay.sh <engine folder> <measure folder> [run ...]}" && pwd)"; MF="$(cd "${2:?}" && pwd)"; shift 2
B="$MF/sx_contact"
export STOCK_VENV="$E/stock" PATCHED_VENV="$E/unit" NORMAL_VENV="$E/normal" XPBD_VENV="$E/xres" VBD_VENV="$E/vbd" \
  MJLIM_VENV="$E/mjlim" XLIM_VENV="$E/xlim" XSG_VENV="$E/xlim" V3_VENV="$E/xlim" \
  PATCHED_SRC="$E/src_unit" NORMAL_SRC="$E/src_normal" XPBD_SRC="$E/src_xres" VBD_SRC="$E/src_vbd" \
  MJLIM_SRC="$E/src_mjlim" XLIM_SRC="$E/src_xlim"
RUNS="$*"
if [ -z "$RUNS" ]; then
  if [ "${DRY:-0}" = 1 ]; then RUNS="run_006_vbd_free_fall run_011_mujoco_solver_low_friction"
  else RUNS=$(cd validation && ls -d run_0[0-4][0-9]_* run_050_* run_051_* | sort); fi
fi
ST=replay_status.txt; : > $ST
for r in $RUNS; do
  d=validation/$r
  s=$(cd "$d" && ls *.sh | head -1)
  # where the record keeps a reading.txt or an out.txt the script does not write itself, the command that launched it
  # sent the script's output there (runs 001 to 013 and the studies): the replay does the same (found by the dry run)
  so="replay_out_${r:4:3}.txt"
  if [ -f "$d/reading.txt" ] && ! grep -q 'reading\.txt' "$d/$s"; then so="$d/reading.txt"
  elif [ -f "$d/out.txt" ] && ! grep -q 'out\.txt' "$d/$s"; then so="$d/out.txt"; fi
  for f in "$d"/*; do case "$(basename "$f")" in README.md|*.sh|dry) ;; *) rm -rf "$f" ;; esac; done
  u=$(grep -m1 '^# usage:' "$d/$s")
  case "$u" in
    *"<folder holding sx_contact"*) arg="$MF" ;;
    *"<sx_contact binary>"*|*"<sx_contact>"*) arg="$B" ;;
    *) arg="" ;;
  esac
  t0=$(date -u +%FT%TZ)
  ( . "$E/stock/bin/activate"; bash "$d/$s" $arg ) > "$so" 2> "replay_err_${r:4:3}.txt"
  echo "$r $s exit $? started $t0 finished $(date -u +%FT%TZ)" >> $ST
done
grep -rlIF "$HOME" validation replay_*.txt 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
echo "replayed: $(wc -l < $ST) runs, $(grep -vc ' exit 0 ' $ST) with a non-zero exit"
