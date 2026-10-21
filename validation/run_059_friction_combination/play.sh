#!/usr/bin/env bash
# Run 059: issue 18 (N3: one friction coefficient, static friction dropped on import, MuJoCo's geom priority ignored
# when friction is combined) put to one cube sliding on the plane (tools/nwt_contact.py), Newton 1.7.0, the cube's
# and the plane's frictions different, with the MuJoCo solver's geom priority unregistered, equal, the cube's higher
# and the plane's higher; on XPBD (Newton's own contact) and the MuJoCo solver, beside each solver's own slide at one
# friction (0.2, 0.55, 0.9). C0: run 008's XPBD and SemiImplicit slides, byte for byte the record's with the rig's
# change. The README's predictions were pushed before these plays. Then reading.txt (sx_contact stop) and checks.txt.
# usage: play.sh <sx_contact binary>   (repository root; STOCK_VENV set: Newton 1.7.0 as released)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"
O=validation/run_059_friction_combination
SL="dt=0.0005 h0=0 vx0=1 mass=1 radius=0.05 secs=0.6"
plays() {  # <name> <settings...>
  local s
  echo "c0_slide_xpbd dt=0.00025 h0=0 vx0=1.3 mass=0.8 radius=0.045 mu=0.45 secs=1.2 solver=xpbd"
  echo "c0_slide_semi dt=0.00025 h0=0 vx0=1.3 mass=0.8 radius=0.045 mu=0.45 secs=1.2 solver=semi"
  for s in xpbd mujoco; do
    echo "one0.2_$s solver=$s $SL mu=0.2"
    echo "one0.55_$s solver=$s $SL mu=0.55"
    echo "one0.9_$s solver=$s $SL mu=0.9"
    echo "mix_$s solver=$s $SL mu=0.2 groundmu=0.9"
    echo "mixreg_$s solver=$s $SL mu=0.2 groundmu=0.9 register=1"
    echo "mixcube_$s solver=$s $SL mu=0.2 groundmu=0.9 register=1 prio=1 groundprio=0"
    echo "mixground_$s solver=$s $SL mu=0.2 groundmu=0.9 register=1 prio=0 groundprio=1"
  done
}
date -u +%FT%TZ > $O/started.txt
X=$(mktemp -d); cp -R tools $X/; plays > $X/list.txt
(cd $X && . "$STOCK_VENV/bin/activate" && mkdir -p runs stats &&
 while read -r n rest; do python tools/nwt_contact.py runs/$n.txt $rest > stats/$n.txt 2>> runs/log.txt; done < list.txt)
mkdir -p $O/runs $O/stats; cp $X/runs/* $O/runs/; cp $X/stats/* $O/stats/; rm -rf $X
date -u +%FT%TZ > $O/finished.txt
R=$O/reading.txt; : > $R
for n in $(plays | awk '{print $1}'); do echo "$n $("$B" stop $O/runs/$n.txt < /dev/null | tail -1)" >> $R; done
pick() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $R; }
C=$O/checks.txt; : > $C
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $C; }
same=0; for s in xpbd semi; do cmp -s $O/runs/c0_slide_$s.txt validation/run_008_study_01/stock/runs/slide_$s.txt && same=$((same + 1)); done
rule C0_rig_unchanged eq $same 2
for s in xpbd mujoco; do
  for m in mix mixreg mixcube mixground; do
    rule ${s}_${m}_as_0.2 all_within $(pick one0.2_$s slid_um) 100 $(pick ${m}_$s slid_um)
    rule ${s}_${m}_as_0.55 all_within $(pick one0.55_$s slid_um) 100 $(pick ${m}_$s slid_um)
    rule ${s}_${m}_as_0.9 all_within $(pick one0.9_$s slid_um) 100 $(pick ${m}_$s slid_um)
  done
done
echo "checks: $(wc -l < $C | tr -d ' '), held: $(grep -c ': HELD$' $C)" >> $C
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
cat $C
