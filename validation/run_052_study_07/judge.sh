#!/usr/bin/env bash
# Run 052 (Study 7, preregistrations/PREREGISTRATION_07.md): every file the record keeps compared with one replay's,
# byte for byte, and the rules counted. A file is set aside (start and finish times, logs, a patched source's
# provenance, the environment's listing, run 014's kept first attempt), a STATS file (compared with the engine's
# version set aside), a reading (what the measure printed from the plays) or a play (what the rig wrote). A play's or a
# STATS file's solver is read from its STATS line, or else from its name. The rules are judged by Senua AI's
# `sx_contact rule`; with a label of 1.6.1 (the control) only the comparison is written.
# usage: judge.sh <sx_contact> <replay root> <record root> <out folder> <label: 1.7.0 or 1.6.1>
set -u
B="$(cd "$(dirname "${1:?usage: judge.sh <sx_contact> <replay root> <record root> <out folder> <label>}")" && pwd)/$(basename "$1")"
RP="$(cd "${2:?}" && pwd)"; RF="$(cd "${3:?}" && pwd)"; mkdir -p "${4:?}"; O="$(cd "$4" && pwd)"; L=${5:?}
C="$O/compare_$L.txt"; : > "$C"
kind() {  # <path inside a run>
  local b; b=$(basename "$1")
  case "$1" in */first_play/*) echo setaside; return ;; esac
  case "$b" in
    started*|finished*|played_at.txt|log*.txt|*.log|patched_source.txt|environment*.txt) echo setaside ;;
    *.stats|stats.txt|stats_*) echo stats ;;
    reading*|measured*|rules*|out.txt|checks*|identity*|tests*|rc*|play_*.txt|play.txt|compare*|verdicts*) echo reading ;;
    *) case "$1" in */stats/*) echo stats ;; *) echo play ;; esac ;;
  esac
}
solver() {  # <run folder> <path inside it>: the solver its STATS line names, or one its name names, or the run's one
  # solver, or "other" (the stats_<rest> sibling and the run's one solver found by the dry run: run 011)
  local d=$1 f=$2 s="" st b
  b=$(basename "$f")
  for st in "$d/${f%.txt}.stats" "$d/$(dirname "$f")/../stats/$b" "$d/$(dirname "$f")/stats_${b#*_}" "$d/$f"; do
    if [ -f "$st" ]; then s=$(grep -o 'solver [a-z_]*' "$st" 2>/dev/null | head -1 | cut -d' ' -f2); [ -n "$s" ] && break; fi
  done
  if [ -z "$s" ]; then case "$f" in *mujoco*) s=mujoco ;; esac; fi
  if [ -z "$s" ]; then
    s=$(cat "$d"/*.sh | grep -o 'solver=[a-z_][a-z_]*' | sort -u | cut -d= -f2)
    [ "$(echo "$s" | grep -c .)" = 1 ] || s=other
  fi
  echo "$s"
}
for d in $(cd "$RF/validation" && ls -d run_0[0-4][0-9]_* run_050_* run_051_* | sort); do
  (cd "$RF/validation/$d" && find . -type f ! -name README.md ! -name '*.sh' ! -path './dry/*' | sed 's|^\./||' | LC_ALL=C sort) | while read -r f; do
    k=$(kind "$f"); s=$(solver "$RF/validation/$d" "$f"); a="$RF/validation/$d/$f"; b="$RP/validation/$d/$f"
    if [ "$k" = setaside ]; then st=SETASIDE
    elif [ ! -f "$b" ]; then st=MISSING
    elif [ "$k" = stats ]; then if cmp -s "$a" <(sed 's/engine newton 1\.7\.0/engine newton 1.6.1/' "$b"); then st=SAME; else st=DIFFERS; fi
    elif cmp -s "$a" "$b"; then st=SAME; else st=DIFFERS; fi
    echo "$st $k $s $d/$f" >> "$C"
  done
  (cd "$RP/validation/$d" && find . -type f ! -name README.md ! -name '*.sh' ! -path './dry/*' | sed 's|^\./||' | LC_ALL=C sort) | while read -r f; do
    [ -f "$RF/validation/$d/$f" ] || echo "NEW $(kind "$f") - $d/$f" >> "$C"
  done
done
{
  echo "$L: $(grep -c '^SAME' "$C") same, $(grep -c '^DIFFERS' "$C") differ, $(grep -c '^MISSING' "$C") missing, $(grep -c '^SETASIDE' "$C") set aside, $(grep -c '^NEW' "$C") new"
  for k in play stats reading; do for s in $(awk -v k=$k '$2 == k {print $3}' "$C" | sort -u); do
    echo "  $k $s: $(awk -v k=$k -v s=$s '$2 == k && $3 == s && $1 == "SAME"' "$C" | wc -l | tr -d ' ') same, $(awk -v k=$k -v s=$s '$2 == k && $3 == s && $1 == "DIFFERS"' "$C" | wc -l | tr -d ' ') differ"
  done; done
} > "$O/summary_$L.txt"
[ "$L" = 1.7.0 ] || { cat "$O/summary_$L.txt"; exit 0; }
rule() { "$B" rule "$@" < /dev/null | tail -1; }
failing() {  # <rules file>: rule lines that did not hold (a missing file counts as one)
  if [ -f "$1" ]; then grep '^RULE ' "$1" | grep -vc ': HELD$'; else echo 1; fi
}
verdicts() { grep '^RULE ' "$1" 2>/dev/null | awk '{print $2, $NF}'; }
{
  nz=$(grep -vc ' exit 0 ' "$RP/replay_status.txt")
  rule R1_the_record_plays eq $(( $(grep -c '^MISSING' "$C") + nz )) 0
  rule R2_unchanged_kernels_play_the_same eq "$(awk '($2 == "play" || $2 == "stats") && $3 != "mujoco" && $1 == "DIFFERS"' "$C" | wc -l | tr -d ' ')" 0
  n=0; for r in run_008_study_01 run_019_study_02 run_033_study_03 run_034_study_04 run_043_study_06; do n=$(( n + $(failing "$RP/validation/$r/rules.txt") )); done
  rule R3_the_validated_studies_hold eq $n 0
  rule R4_study_5_as_it_was eq "$(diff <(verdicts "$RF/validation/run_037_study_05/rules.txt") <(verdicts "$RP/validation/run_037_study_05/rules.txt") | grep -c '^[<>]')" 0
} > "$O/rules.txt"
cat "$O/summary_$L.txt" "$O/rules.txt"
