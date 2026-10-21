#!/usr/bin/env bash
# Run 084: SemiImplicit's joint limit on arms its joint attachment can carry (issue 16's SemiImplicit part), a design
# probe that decides nothing and states no prediction: run 042's strike (released level onto -1 rad, limits -1 and 1,
# Newton's limit) on two heavy, large arms whose own inertia puts the attachment's explicit bounds above the steps (5 kg,
# half-size 0.2 m; 2 kg, half-size 0.15 m; centres 0.4 m out), as released and with NEWTON_SEMI_JOINT_LIMIT=1
# (patches/in_design/semi_joint_on_1.7.0.diff), beside Featherstone released and with its limit patch's =1, at 1, 0.25
# and 0.0625 ms, on Newton 1.7.0. Kept from pulling they turn back at -0.229 and -0.340 rad. Then measured.txt.
# usage: play.sh <sx_contact binary>   (repository root; STOCK_VENV Newton 1.7.0, JOINT_VENV and LIMIT_VENV the patches)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"
O=validation/run_084_semi_limit_heavy
plays() { local e a dt; for e in stock limit fs fs1; do for a in "5 0.2" "2 0.15"; do set -- $a; for dt in 0.001 0.00025 0.0000625; do
  case $e in stock|limit) o="solver=semi";; *) o="solver=featherstone";; esac
  echo "strike_${e}_m$1_$dt $e dt=$dt mass=$1 radius=$2 arm=0.4 secs=2 lo=-1 hi=1 $o"; done; done; done; }
mkdir -p $O/runs $O/stats; date -u +%FT%TZ > $O/started.txt
for g in stock limit fs fs1; do
  ( case $g in stock|fs) v=$STOCK_VENV;; limit) v=$JOINT_VENV;; fs1) v=$LIMIT_VENV;; esac; . "$v/bin/activate"
    unset NEWTON_SEMI_JOINT_LIMIT NEWTON_FEATHERSTONE_LIMIT; [ $g = limit ] && export NEWTON_SEMI_JOINT_LIMIT=1; [ $g = fs1 ] && export NEWTON_FEATHERSTONE_LIMIT=1
    plays | awk -v g=$g '$2 == g { $2 = ""; print }' | xargs -P 2 -L 1 bash -c 'python tools/nwt_joint.py '"$O"'/runs/$0.txt "$@" > '"$O"'/stats/$0.txt 2> '"$O"'/runs/log_$0.txt' ) &
done
wait; date -u +%FT%TZ > $O/finished.txt
pick_s() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
M=$O/measured.txt; : > $M
for n in $(plays | awk '{print $1}'); do st=$(pick_s nan_at_step < $O/stats/$n.txt); [ -n "$st" ] || st=$(pick_s out_of_range_at_step < $O/stats/$n.txt)
  echo "$n stops ${st:--1} $("$B" swing $O/runs/$n.txt < /dev/null | tail -1 | cut -d' ' -f1-12)" >> $M; done
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
cat $M
