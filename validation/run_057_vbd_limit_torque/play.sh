#!/usr/bin/env bash
# Run 057: issue 29 (N20, VBD's joint limits and outside torques inaccurate) put to Newton 1.7.0's VBD (its dense
# rigid path: 1.7.0 has no block-sparse rigid path, the one #4720 and #4721 are about) on one arm on one hinge
# (tools/nwt_joint.py): a joint torque on the record's arm and on a light arm against t^2 / (2 I), and the light and
# the record's arm released under gravity onto a joint limit at 4, 2 and 0.8 ms; Featherstone and the MuJoCo solver
# beside (Featherstone not on the light arm's limit: run 055). The README's predictions were pushed before these
# plays. Then reading.txt (sx_contact final, each play, and its STATS line's nan or range field) and checks.txt.
# usage: play.sh <sx_contact binary>   (repository root; STOCK_VENV set: Newton 1.7.0 as released)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"
O=validation/run_057_vbd_limit_torque
HEAVY="mass=1 radius=0.05 arm=0.5"; LIGHT="mass=0.05 radius=0.01 arm=0.02"
plays() {  # <name> <settings...>
  local s dt
  for dt in 0.004 0.002 0.0008; do
    for s in vbd featherstone mujoco; do
      echo "torqueh_${s}_$dt solver=$s dt=$dt $HEAVY gravity=0 torque=1 secs=0.1"
      echo "torquel_${s}_$dt solver=$s dt=$dt $LIGHT gravity=0 torque=0.0001 secs=0.1"
      echo "limith_${s}_$dt solver=$s dt=$dt $HEAVY gravity=1 lo=-0.5 hi=0.5 secs=0.8"
    done
    for s in vbd mujoco; do echo "limitl_${s}_$dt solver=$s dt=$dt $LIGHT gravity=1 lo=-0.5 hi=0.5 secs=0.3"; done
  done
}
date -u +%FT%TZ > $O/started.txt
X=$(mktemp -d); cp -R tools $X/; plays > $X/list.txt
(cd $X && . "$STOCK_VENV/bin/activate" && mkdir -p runs stats &&
 while read -r n rest; do python tools/nwt_joint.py runs/$n.txt $rest > stats/$n.txt 2>> runs/log.txt; done < list.txt)
mkdir -p $O/runs $O/stats; cp $X/runs/* $O/runs/; cp $X/stats/* $O/stats/; rm -rf $X
date -u +%FT%TZ > $O/finished.txt
R=$O/reading.txt; : > $R
for n in $(plays | awk '{print $1}'); do
  st=$(awk '{ for (i = 1; i < NF; i++) if ($i == "nan_at_step" || $i == "out_of_range_at_step") { print $i, $(i + 1); exit } }' $O/stats/$n.txt)
  echo "$n $("$B" final $O/runs/$n.txt < /dev/null | tail -1) ${st:-number_throughout}" >> $R
done
pick() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $R; }
C=$O/checks.txt; : > $C
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $C; }
for n in $(plays | awk '{print $1}'); do
  case $n in
    torqueh_*) rule T_$n all_within 19868 100 $(pick $n angle_urad) ;;
    torquel_*) rule T_$n all_within 21429 100 $(pick $n angle_urad) ;;
    limit*) rule L_${n}_angle all_within -500000 100 $(pick $n angle_urad); rule L_${n}_still all_le 10000 $(pick $n speed_urads | tr -d -) ;;
  esac
  rule N_${n}_number eq $(grep -c "^$n .*number_throughout$" $R) 1
done
echo "checks: $(wc -l < $C | tr -d ' '), held: $(grep -c ': HELD$' $C)" >> $C
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
cat $C
