#!/usr/bin/env bash
# on the newton host: each R2 file with the version masked and its lines sorted; what still differs, shown
cd ~/work/s7
m() { sed -E 's/engine newton 1\.[0-9]+\.[0-9]+/engine newton V/' "$1" | sort; }
grep "^DIFFERS" j170/compare_1.7.0.txt | awk '$2=="play"||$2=="stats"' | awk '$3!="mujoco"&&$3!="other"' | while read -r _ kind fam f; do
  a=rec/validation/$f; b=r170/validation/$f
  if cmp -s <(m "$a") <(m "$b"); then echo "ORDER+VERSION-ONLY $f"; else
    echo "STILL $f:"; diff <(m "$a") <(m "$b") | grep '^[<>]' | head -4 | cut -c1-260
  fi
done
