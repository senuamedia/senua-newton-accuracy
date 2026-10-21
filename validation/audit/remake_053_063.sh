#!/usr/bin/env bash
# The audit's re-make of runs 053 to 063 (docs/audit.md, section 7): each run played and measured again by its own
# script, in a clean copy of the repository on the Newton host, then every file the record keeps for it compared byte
# for byte with a second clean copy, the record. Each run's recorded outputs are cleared first; its script and README
# are kept. The engines are the ones the runs were played with: Newton 1.7.0 as released (Study 8's engine folders'
# stock environment), each pull request's tree first on the path (run 053's engines), the joint-angle patch's fourth
# form (run 061). Run 053 is played from its registration's own archive, as it was. The runs read no output of one
# another, so they are played in three lanes at once. A script's printed output goes into this folder.
# usage: remake_053_063.sh <measure folder (sx_contact, sx_contact_suite.sh)> <Study 8's engines folder> \
#          <the joint-angle patch's v4 environment> <run 053's registration archive> <record copy>
#   (from the root of the clean copy to re-make in; writes validation/audit/remake_053_063_compare.txt and _log.txt)
set -u
M="$(cd "${1:?usage: see the header}" && pwd)"; E8="$(cd "${2:?}" && pwd)"; V4="$(cd "${3:?}" && pwd)"
AR="$(cd "$(dirname "${4:?}")" && pwd)/$(basename "$4")"; REF="$(cd "${5:?}" && pwd)"
A=validation/audit; L=$A/remake_053_063_log.txt; C=$A/remake_053_063_compare.txt; : > $L
log() { echo "$(date -u +%T) $*" >> $L; }
keep() { [ "$1" = README.md ] || [ "${1%.sh}" != "$1" ]; }
export STOCK_VENV="$E8/pr4010/stock" PR4316_VENV="$E8/pr4316/unit" PR4317_VENV="$E8/pr4317/unit" V4_VENV="$V4"
RUNS=$(cd validation && ls -d run_05[3-9]_* run_06[0-3]_* | sort)
for r in $RUNS; do
  d=validation/$r
  for f in "$d"/*; do keep "$(basename "$f")" || rm -rf "$f"; done
  log "$r cleared"
done
play() {  # <run>: its own script, its printed output kept here
  local r=$1 n=${1:4:3}
  if [ "$r" = run_053_study_08 ]; then bash validation/$r/play.sh "$E8" "$M" "$AR" > $A/remake_053_063_out_$n.txt 2>&1
  else bash validation/$r/play.sh "$M/sx_contact" > $A/remake_053_063_out_$n.txt 2>&1; fi
  log "$r played, exit $?"
}
lane() { for r in "$@"; do play "$(cd validation && ls -d run_${r}_*)"; done; }
lane 053 059 060 061 062 &
lane 054 056 057 063 &
lane 055 058 &
wait
# the record writes the home folder of the machine its outputs were made on as ~ (docs/runs.md)
for r in $RUNS; do grep -rlIF "$HOME" validation/$r 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done; done
log "home folder written as ~ in the re-made outputs"
{
  for r in $RUNS; do
    d=validation/$r
    ( cd "$REF" && find "$d" -type f ! -name README.md ! -name '*.sh' | sort ) | while read -r f; do
      if [ ! -f "$f" ]; then echo "MISSING $f"; elif cmp -s "$REF/$f" "$f"; then echo "SAME $f"; else echo "DIFFERS $f"; fi
    done
    find "$d" -type f ! -name README.md ! -name '*.sh' | sort | while read -r f; do
      [ -f "$REF/$f" ] || echo "NEW $f"
    done
  done
} > $C
log "compared: $(grep -c '^SAME' $C) same, $(grep -c '^DIFFERS' $C) differ, $(grep -c '^MISSING' $C) missing, $(grep -c '^NEW' $C) new"
date -u +%FT%TZ > $A/remake_053_063_done.txt
