#!/usr/bin/env bash
# Run 053 (Study 8, preregistrations/PREREGISTRATION_08.md): the two rules, from the replayed studies' own rule lines,
# by sx_contact rule. A1: Study 1's lines R2 to R8 with #4010 (part A); B1: Study 5's lines R2 to R6 with #4316
# (part B). Writes rules.txt in run 053's folder and prints it.
# usage: judge.sh <sx_contact binary>   (repository root, after play.sh)
set -u
B="${1:?usage: judge.sh <sx_contact binary>}"; O=validation/run_053_study_08
failing() {  # <rules file> <first> <last>: rule lines R<first> to R<last> that did not hold (a missing file counts one)
  if [ -f "$1" ]; then awk -v a="$2" -v b="$3" '$1 == "RULE" { n = substr($2, 2) + 0; if (n >= a && n <= b && $NF != "HELD") c++ } END { print c + 0 }' "$1"; else echo 1; fi
}
R=$O/rules.txt; : > $R
"$B" rule A1_4010_holds_study_1 eq "$(failing $O/A/run_008_study_01/rules.txt 2 8)" 0 < /dev/null | tail -1 >> $R
"$B" rule B1_4316_holds_study_5 eq "$(failing $O/B/run_037_study_05/rules.txt 2 6)" 0 < /dev/null | tail -1 >> $R
echo "rules: $(wc -l < $R | tr -d ' '), held: $(grep -c ': HELD$' $R)" >> $R
cat $R
