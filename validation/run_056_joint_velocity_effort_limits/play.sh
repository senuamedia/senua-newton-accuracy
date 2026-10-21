#!/usr/bin/env bash
# Run 056: issue 19's velocity and effort limits (N7, joint features silently ignored) on one arm on one hinge
# (tools/nwt_joint.py), Newton 1.7.0, every solver that plays joints: does the solver apply a joint's velocity_limit
# under a torque and its effort_limit on a drive, and does it say anything when it does not. The README's predictions
# were pushed before these plays. Then reading.txt (sx_contact final, each play; the lines the play wrote to its error
# stream) and checks.txt (sx_contact rule).
# usage: play.sh <sx_contact binary>   (repository root; STOCK_VENV set: Newton 1.7.0 as released)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"
O=validation/run_056_joint_velocity_effort_limits
ARM="mass=1 radius=0.05 arm=0.5 gravity=0 dt=0.0001"
plays() {  # <name> <settings...>
  local s
  for s in featherstone mujoco xpbd semi vbd; do
    echo "vel_$s solver=$s $ARM torque=1 vlimit=1 secs=1"
    echo "velfree_$s solver=$s $ARM torque=1 secs=1"
    echo "eff_$s solver=$s $ARM drivek=100 target=1 elimit=1 secs=0.2"
    echo "efffree_$s solver=$s $ARM drivek=100 target=1 secs=0.2"
  done
}
date -u +%FT%TZ > $O/started.txt
X=$(mktemp -d); cp -R tools $X/; plays > $X/list.txt
(cd $X && . "$STOCK_VENV/bin/activate" && mkdir -p runs stats err &&
 while read -r n rest; do python tools/nwt_joint.py runs/$n.txt $rest > stats/$n.txt 2> err/$n.txt; done < list.txt)
mkdir -p $O/runs $O/stats $O/err; cp $X/runs/* $O/runs/; cp $X/stats/* $O/stats/; cp $X/err/* $O/err/; rm -rf $X
date -u +%FT%TZ > $O/finished.txt
R=$O/reading.txt; : > $R
for n in $(plays | awk '{print $1}'); do echo "$n $("$B" final $O/runs/$n.txt < /dev/null | tail -1) err_lines $(grep -c . $O/err/$n.txt)" >> $R; done
pick() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $R; }
C=$O/checks.txt; : > $C
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $C; }
for s in featherstone mujoco xpbd semi vbd; do
  rule V_${s}_limit_applied all_within 1000000 100 $(pick vel_$s speed_urads)
  rule V_${s}_free all_within 3973510 100 $(pick velfree_$s speed_urads)
  rule E_${s}_limit_applied all_within 79470 100 $(pick eff_$s angle_urad)
  rule E_${s}_free all_within 1663626 100 $(pick efffree_$s angle_urad)
  rule W_${s}_said_nothing eq $(( $(pick vel_$s err_lines) + $(pick eff_$s err_lines) )) 0
done
echo "checks: $(wc -l < $C | tr -d ' '), held: $(grep -c ': HELD$' $C)" >> $C
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
cat $C
