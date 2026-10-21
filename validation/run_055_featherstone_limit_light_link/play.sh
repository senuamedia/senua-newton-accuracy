#!/usr/bin/env bash
# Run 055: issue 28 (N19, Featherstone not a number on serial arms the MuJoCo solver plays) put to one arm on one hinge
# (tools/nwt_joint.py), Newton 1.7.0: a light arm released level under gravity onto its lower joint limit, at steps
# either side of the explicit integrator's stability bound for the limit's spring and damper; the record's arm beside;
# the MuJoCo solver beside every play. The README's predictions were pushed before these plays. Then reading.txt
# (sx_contact final, each play, and its STATS line's nan or range field) and checks.txt (sx_contact rule).
# usage: play.sh <sx_contact binary>   (repository root; STOCK_VENV set: Newton 1.7.0 as released)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"
O=validation/run_055_featherstone_limit_light_link; ROOT=$(pwd)
LIGHT="mass=0.05 radius=0.01 arm=0.02 gravity=1 lo=-0.5 hi=0.5 secs=0.15"
HEAVY="mass=1 radius=0.05 arm=0.5 gravity=1 lo=-0.5 hi=0.5 secs=0.5"
plays() {  # <name> <settings...>
  local s dt
  for s in featherstone mujoco; do
    for dt in 0.0041666667 0.001 0.00025 0.0001 0.00002 0.00001 0.000005 0.000002; do echo "light_${s}_$dt solver=$s dt=$dt $LIGHT"; done
    for dt in 0.00025 0.0001 0.00005 0.00002; do echo "lightkd0_${s}_$dt solver=$s dt=$dt $LIGHT limitd=0"; done
    for dt in 0.0041666667 0.001; do echo "heavy_${s}_$dt solver=$s dt=$dt $HEAVY"; done
  done
}
date -u +%FT%TZ > $O/started.txt
X=$(mktemp -d); cp -R tools $X/; plays > $X/list.txt
(cd $X && . "$STOCK_VENV/bin/activate" && mkdir -p runs stats &&
 while read -r n rest; do python tools/nwt_joint.py runs/$n.txt $rest > stats/$n.txt 2>> runs/log.txt; done < list.txt)
mkdir -p $O/runs $O/stats; cp $X/runs/* $O/runs/; cp $X/stats/* $O/stats/; rm -rf $X
date -u +%FT%TZ > $O/finished.txt
# ---- reading: the last step's angle and speed, and where the play stopped being a number or left the format's range
R=$O/reading.txt; : > $R
for n in $(plays | awk '{print $1}'); do
  st=$(awk '{ for (i = 1; i < NF; i++) if ($i == "nan_at_step" || $i == "out_of_range_at_step") { print $i, $(i + 1); exit } }' $O/stats/$n.txt)
  echo "$n $("$B" final $O/runs/$n.txt < /dev/null | tail -1) ${st:-number_throughout}" >> $R
done
pick() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $R; }
# ---- checks: held on the lower limit (angle within 1 in 100 of -0.5 rad, speed within 0.01 rad/s of 0, a number
# throughout)
C=$O/checks.txt; : > $C
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $C; }
for n in $(plays | awk '{print $1}'); do
  rule H_${n}_angle all_within -500000 100 $(pick $n angle_urad)
  rule H_${n}_still all_le 10000 $(pick $n speed_urads | tr -d -)
  rule H_${n}_number eq $(grep -c "^$n .*number_throughout$" $R) 1
done
echo "checks: $(wc -l < $C | tr -d ' '), held: $(grep -c ': HELD$' $C)" >> $C
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
cat $C
