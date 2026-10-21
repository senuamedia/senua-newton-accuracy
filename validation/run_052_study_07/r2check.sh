#!/usr/bin/env bash
# on the newton host: each R2 file (non-MuJoCo kernel families) compared with the engine version masked, line by line
cd ~/work/s7
grep "^DIFFERS" j170/compare_1.7.0.txt | awk '$2=="play"||$2=="stats"' | awk '$3!="mujoco"&&$3!="other"' | while read -r _ kind fam f; do
  a=rec/validation/$f; b=r170/validation/$f
  if cmp -s <(sed -E 's/engine newton 1\.[0-9]+\.[0-9]+/engine newton V/' "$a") <(sed -E 's/engine newton 1\.[0-9]+\.[0-9]+/engine newton V/' "$b"); then
    echo "VERSION-ONLY $kind $fam $f"
  else
    n=$(diff <(sed -E 's/engine newton 1\.[0-9]+\.[0-9]+/engine newton V/' "$a") <(sed -E 's/engine newton 1\.[0-9]+\.[0-9]+/engine newton V/' "$b") | grep -c '^<')
    sol=$(diff <(sed -E 's/engine newton 1\.[0-9]+\.[0-9]+/engine newton V/' "$a") <(sed -E 's/engine newton 1\.[0-9]+\.[0-9]+/engine newton V/' "$b") | grep '^<' | grep -o 'solver [a-z_]*' | sort | uniq -c | tr '\n' ' ')
    echo "REAL $kind $fam $f lines $n solvers: $sol"
  fi
done
