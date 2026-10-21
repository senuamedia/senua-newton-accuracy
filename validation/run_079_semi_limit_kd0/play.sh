#!/usr/bin/env bash
# Run 079: SemiImplicit's joint limit kept from pulling (issue 16's SemiImplicit part), on a scene SemiImplicit can play:
# run 042's strike with joint_attach_kd=0 (the joint penalty's spring alone, Study 9's configuration for SemiImplicit's
# joints), a design probe that decides nothing and states no prediction: as released and with NEWTON_SEMI_JOINT_LIMIT=1
# (patches/in_design/semi_joint_on_1.7.0.diff), at 0.1 and 1 kg, 0.25, 0.0625 and 0.015625 ms, on Newton 1.7.0, beside
# Featherstone's (released and with its limit patch's =1). Then measured.txt (where the arm turns back, sx_contact swing).
# usage: play.sh <sx_contact binary>   (repository root; STOCK_VENV Newton 1.7.0, JOINT_VENV and LIMIT_VENV the two patches' trees first)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"
O=validation/run_079_semi_limit_kd0
STRIKE="radius=0.04 arm=0.4 secs=2 lo=-1 hi=1"
plays() { local e m dt; for e in stock limit fs fs1; do for m in 0.1 1; do for dt in 0.00025 0.0000625 0.000015625; do
  case $e in stock|limit) o="solver=semi opt.joint_attach_kd=0";; *) o="solver=featherstone";; esac
  echo "strike_${e}_m${m}_$dt $e dt=$dt mass=$m $STRIKE $o"; done; done; done; }
mkdir -p $O/runs $O/stats; date -u +%FT%TZ > $O/started.txt
for g in stock limit fs fs1; do
  ( case $g in stock|fs) v=$STOCK_VENV;; limit) v=$JOINT_VENV;; fs1) v=$LIMIT_VENV;; esac; . "$v/bin/activate"
    unset NEWTON_SEMI_JOINT_LIMIT NEWTON_FEATHERSTONE_LIMIT; [ $g = limit ] && export NEWTON_SEMI_JOINT_LIMIT=1; [ $g = fs1 ] && export NEWTON_FEATHERSTONE_LIMIT=1
    plays | awk -v g=$g '$2 == g { $2 = ""; print }' | xargs -P 2 -L 1 bash -c 'python tools/nwt_joint.py '"$O"'/runs/$0.txt "$@" > '"$O"'/stats/$0.txt 2> '"$O"'/runs/log_$0.txt' ) &
done
wait; date -u +%FT%TZ > $O/finished.txt
pick_s() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
back() { "$B" swing $1 < /dev/null | tail -1 | awk '{ n = 0; for (i = 1; i < NF; i++) if ($i == "turn_urad") { n++; if (n == 2) { print $(i + 1); exit } } } END { if (n < 2) print "none" }'; }
M=$O/measured.txt; : > $M
for n in $(plays | awk '{print $1}'); do st=$(pick_s nan_at_step < $O/stats/$n.txt); [ -n "$st" ] || st=$(pick_s out_of_range_at_step < $O/stats/$n.txt)
  echo "$n stops ${st:--1} back_urad $(back $O/runs/$n.txt)" >> $M; done
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
cat $M
