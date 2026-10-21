#!/usr/bin/env bash
# Run 063: issue 19's loop-closing joint (#2428) put to one arm on two coaxial hinges (tools/nwt_loop.py), the second
# left out of the articulation and carrying a limit or a drive, Newton 1.7.0, every solver; the single free hinge as
# the control. The README's predictions were pushed before these plays. Then reading.txt (sx_contact final) and
# checks.txt (sx_contact rule).
# usage: play.sh <sx_contact binary>   (repository root; STOCK_VENV set: Newton 1.7.0 as released)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"
O=validation/run_063_loop_joint
plays() {  # <name> <settings...>
  local s
  for s in featherstone mujoco xpbd semi vbd; do
    echo "free_$s solver=$s dt=0.0001 omega0=1 secs=1.5 noloop=1"
    echo "loopfree_$s solver=$s dt=0.0001 omega0=1 secs=1.5"
    echo "limit_$s solver=$s dt=0.0001 omega0=1 secs=1.5 lo=-0.5 hi=0.5"
    echo "drive_$s solver=$s dt=0.0001 secs=1 drivek=100 drived=10 target=0.3"
  done
}
date -u +%FT%TZ > $O/started.txt
X=$(mktemp -d); cp -R tools $X/; plays > $X/list.txt
(cd $X && . "$STOCK_VENV/bin/activate" && mkdir -p runs stats &&
 while read -r n rest; do python tools/nwt_loop.py runs/$n.txt $rest > stats/$n.txt 2>> runs/log.txt; done < list.txt)
mkdir -p $O/runs $O/stats; cp $X/runs/* $O/runs/; cp $X/stats/* $O/stats/; rm -rf $X
date -u +%FT%TZ > $O/finished.txt
R=$O/reading.txt; : > $R
for n in $(plays | awk '{print $1}'); do echo "$n $("$B" final $O/runs/$n.txt < /dev/null | tail -1)" >> $R; done
pick() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $R; }
C=$O/checks.txt; : > $C
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $C; }
for s in featherstone mujoco xpbd semi vbd; do
  rule F_${s}_free all_within 1500000 100 $(pick free_$s angle_urad)
  rule F_${s}_loopfree all_within 1500000 100 $(pick loopfree_$s angle_urad)
  rule L_${s}_limit_applied all_within 500000 10 $(pick limit_$s angle_urad)
  rule D_${s}_drive_applied all_within 300000 100 $(pick drive_$s angle_urad)
done
echo "checks: $(wc -l < $C | tr -d ' '), held: $(grep -c ': HELD$' $C)" >> $C
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
cat $C
