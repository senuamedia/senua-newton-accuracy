#!/usr/bin/env bash
# Run 058: a driven joint held at rest at its target, short of pi, past pi and past a full turn (issue 27, #4547's own
# case: 7.0 rad), on one arm on one hinge (tools/nwt_joint.py), Newton 1.7.0, every solver, with the bodies placed before
# the solver is built (place=first: VBD captures its joints' rest angles when built, run 054); SemiImplicit and VBD also
# as the rig built them before. XPBD as released and with #4316. The README's predictions were pushed before these
# plays. Then reading.txt (sx_contact final, each play) and checks.txt (sx_contact rule).
# usage: play.sh <sx_contact binary>   (repository root; STOCK_VENV and PR4316_VENV set: Newton 1.7.0 as released and
#   with #4316's tree first on the path, run 053's engines)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"
O=validation/run_058_drive_past_a_turn; ROOT=$(pwd)
ARM="mass=1 radius=0.05 arm=0.5 gravity=0 dt=0.0001 drivek=100 drived=10 secs=1"
plays() {  # <name> <environment> <settings...>
  local t a e
  for t in 2.5 3.5 7; do
    for a in featherstone mujoco semi vbd xpbd xpbd_4316; do
      case $a in xpbd_4316) e="4316 solver=xpbd";; *) e="stock solver=$a";; esac
      echo "hold_${a}_$t $e $ARM angle0=$t target=$t place=first"
    done
    for a in semi vbd; do echo "built_${a}_$t stock solver=$a $ARM angle0=$t target=$t"; done
  done
}
group() {  # <environment>
  local g=$1 venv X n e rest
  case $g in stock) venv="$STOCK_VENV";; 4316) venv="$PR4316_VENV";; esac
  X=$(mktemp -d); cp -R tools $X/
  plays | awk -v g=$g '$2 == g' > $X/list.txt
  (cd $X && . "$venv/bin/activate" && mkdir -p runs stats &&
   while read -r n e rest; do python tools/nwt_joint.py runs/$n.txt $rest > stats/$n.txt 2>> runs/log_$g.txt; done < list.txt)
  mkdir -p $ROOT/$O/runs $ROOT/$O/stats; cp $X/runs/* $ROOT/$O/runs/; cp $X/stats/* $ROOT/$O/stats/; rm -rf $X
}
date -u +%FT%TZ > $O/started.txt
for g in stock 4316; do group $g & done
wait
date -u +%FT%TZ > $O/finished.txt
R=$O/reading.txt; : > $R
for n in $(plays | awk '{print $1}'); do echo "$n $("$B" final $O/runs/$n.txt < /dev/null | tail -1)" >> $R; done
pick() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $R; }
C=$O/checks.txt; : > $C
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $C; }
for n in $(plays | awk '{print $1}'); do
  t=${n##*_}; tu=$(case $t in 2.5) echo 2500000;; 3.5) echo 3500000;; 7) echo 7000000;; esac)
  rule H_${n}_angle all_within $tu 1000 $(pick $n angle_urad)
  rule H_${n}_still all_le 10000 $(pick $n speed_urads | tr -d -)
done
echo "checks: $(wc -l < $C | tr -d ' '), held: $(grep -c ': HELD$' $C)" >> $C
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
cat $C
