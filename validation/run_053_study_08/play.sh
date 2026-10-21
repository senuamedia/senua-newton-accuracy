#!/usr/bin/env bash
# Run 053 (Study 8, preregistrations/PREREGISTRATION_08.md): each part played in a clean copy of the repository by
# Study 7's replay.sh, with the pull request's engine folder: A #4010 (run 008), B #4316 and C #4317 (runs 037, 048,
# 050, 051). The parts run one after another; each part's replayed run folders and its replay status are kept in
# validation/run_053_study_08/<part>/.
# usage: play.sh <engines folder from setup_engine.sh> <measure folder> <repository archive (a tar of the commit)>
#   (repository root); measure folder as Study 7's: sx_contact and sx_contact_suite.sh
set -u
E="$(cd "${1:?usage: play.sh <engines folder> <measure folder> <archive>}" && pwd)"; MF="$(cd "${2:?}" && pwd)"
A="$(cd "$(dirname "${3:?}")" && pwd)/$(basename "$3")"
O="$(pwd)/validation/run_053_study_08"
date -u +%FT%TZ > "$O/started.txt"
part() {  # <part> <engine> <runs...>
  local p=$1 e=$2 W r; shift 2
  W=$(mktemp -d); tar xf "$A" -C "$W"
  (cd "$W" && bash validation/run_052_study_07/replay.sh "$E/$e" "$MF" "$@") > "$O/replay_$p.txt" 2>&1
  rm -rf "${O:?}/$p"; mkdir -p "$O/$p"
  for r in "$@"; do cp -R "$W/validation/$r" "$O/$p/"; done
  cp "$W/replay_status.txt" "$O/$p/"; cp "$W"/replay_err_*.txt "$O/$p/" 2>/dev/null || true
  rm -rf "${W:?}"
}
part A pr4010 run_008_study_01
part B pr4316 run_037_study_05 run_048_xpbd_limit_gain run_050_xpbd_swing_gradient run_051_xpbd_limit_anchor_held
part C pr4317 run_037_study_05 run_048_xpbd_limit_gain run_050_xpbd_swing_gradient run_051_xpbd_limit_anchor_held
grep -rlIF "$HOME" "$O" 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
date -u +%FT%TZ > "$O/finished.txt"
echo "played: $(cat "$O"/*/replay_status.txt | wc -l) runs, $(cat "$O"/*/replay_status.txt | grep -vc ' exit 0 ') with a non-zero exit"
