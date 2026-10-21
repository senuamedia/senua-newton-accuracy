#!/usr/bin/env bash
# Run 062: issue 27 in its two reports' own scenes (tools/nwt_rest.py: #4547's revolute and #4540's two-axis D6, one
# body of unit inertia at the joint, driven at its targets, nothing acting), Newton 1.7.0, Featherstone, the MuJoCo
# solver, XPBD and SemiImplicit (with its defaults, and as the reports set it: no attachment penalty, no angular
# damping), one step and a thousand at 1 ms. The README's predictions were pushed before these plays. Then
# reading.txt (sx_contact final, each play and each D6 axis) and checks.txt (sx_contact rule).
# usage: play.sh <sx_contact binary>   (repository root; STOCK_VENV set: Newton 1.7.0 as released)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"
O=validation/run_062_rest_reports_scenes
REP="opt.angular_damping=0 opt.joint_attach_ke=0 opt.joint_attach_kd=0"
plays() {  # <name> <settings...>
  local n s
  for n in 1 1000; do
    for s in featherstone mujoco xpbd semi semirep; do
      e="solver=$s"; [ $s = semirep ] && e="solver=semi $REP"
      for r in 2.5 3.5 7; do echo "rev${r}_${s}_n$n dt=0.001 joint=revolute rest=$r ke=2 steps=$n $e"; done
      echo "d6_${s}_n$n dt=0.001 joint=d6 ke=2 steps=$n $e"
    done
  done
}
date -u +%FT%TZ > $O/started.txt
X=$(mktemp -d); cp -R tools $X/; plays > $X/list.txt
(cd $X && . "$STOCK_VENV/bin/activate" && mkdir -p runs stats &&
 while read -r n rest; do python tools/nwt_rest.py runs/$n.txt $rest > stats/$n.txt 2>> runs/log.txt; done < list.txt)
mkdir -p $O/runs $O/stats; cp $X/runs/* $O/runs/; cp $X/stats/* $O/stats/; rm -rf $X
date -u +%FT%TZ > $O/finished.txt
R=$O/reading.txt; : > $R
for n in $(plays | awk '{print $1}'); do
  echo "$n $("$B" final $O/runs/$n.txt < /dev/null | tail -1)" >> $R
  [ -f $O/runs/$n.txt.dof2 ] && echo "$n.dof2 $("$B" final $O/runs/$n.txt.dof2 < /dev/null | tail -1)" >> $R
done
pick() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $R; }
C=$O/checks.txt; : > $C
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $C; }
for n in $(awk '{print $1}' $R); do rule S_${n}_still all_le 0 $(pick $n speed_urads | tr -d -); done
echo "checks: $(wc -l < $C | tr -d ' '), held: $(grep -c ': HELD$' $C)" >> $C
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
cat $C
