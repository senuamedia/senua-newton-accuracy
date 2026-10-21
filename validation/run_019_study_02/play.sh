#!/usr/bin/env bash
# Run 019: the second registered study (preregistrations/PREREGISTRATION_02.md), played once. Six arms, each in its own
# scratch folder: stock_plain and stock_res (Newton 1.6.1 from PyPI, XPBD as released and with enable_restitution),
# off_plain and off_res (the patched source, switch unset), on_plain and on_res (NEWTON_XPBD_RESTITUTION_FRICTION=2).
# Each plays the registered scenes at 4 ms and 0.4 ms; then every registered rule is judged by sx_contact rule.
# DRY=1 plays throwaway parameters on the stock_res arm only, into dry/, to check that the runner runs to the end; no
# rule is read from it.
# usage: play.sh <sx_contact binary>   (repository root; STOCK_VENV and XPBD_VENV set to the two environments)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"
O=validation/run_019_study_02; ROOT=$(pwd)
if [ "${DRY:-0}" = 1 ]; then
  OUT=$O/dry; ARMS="stock_res"; STEPS="0.005"
  CUBE="mass=2 radius=0.04"; DROP="h0=0.08 mu=0 secs=0.5"; OBLIQUE="h0=0.08 vx0=4 mu=0.4 secs=0.3"
  SLIDE="h0=0 vx0=5 mu=0.4 secs=0.5"; REST="h0=0 mu=0.5 secs=1"; HOLD="h0=0 mu=0.5 push=5.88 pushat=0.5 secs=1"
else
  OUT=$O; ARMS="stock_plain stock_res off_plain off_res on_plain on_res"; STEPS="0.004 0.0004"
  CUBE="mass=1.4 radius=0.035"; DROP="h0=0.06 mu=0 secs=0.6"; OBLIQUE="h0=0.05 vx0=2.5 mu=0.35 secs=0.5"
  SLIDE="h0=0 vx0=1.8 mu=0.35 secs=1"; REST="h0=0 mu=0.35 secs=1"; HOLD="h0=0 mu=0.35 push=2.881 pushat=0.3 secs=1"
fi
mkdir -p $OUT
play_arm() {  # <restitution: 0|1>: every registered play of one arm into runs/, its STATS line into stats/
  local res=$1 dt R=""
  [ "$res" = 1 ] && R="opt.enable_restitution=true"
  mkdir -p runs stats
  for dt in $STEPS; do
    # shellcheck disable=SC2086
    { python tools/nwt_contact.py runs/drop_$dt.txt dt=$dt $CUBE $DROP solver=xpbd $R > stats/drop_$dt.txt
      python tools/nwt_contact.py runs/oblique_$dt.txt dt=$dt $CUBE $OBLIQUE solver=xpbd $R > stats/oblique_$dt.txt
      python tools/nwt_contact.py runs/slide_$dt.txt dt=$dt $CUBE $SLIDE solver=xpbd $R > stats/slide_$dt.txt
      python tools/nwt_contact.py runs/rest_$dt.txt dt=$dt $CUBE $REST solver=xpbd $R > stats/rest_$dt.txt
      python tools/nwt_contact.py runs/hold_$dt.txt dt=$dt $CUBE $HOLD solver=xpbd $R > stats/hold_$dt.txt
    } 2>> runs/log.txt
  done
}
arm() {  # <name>
  local name=$1 venv sw res X
  case $name in stock_*) venv="$STOCK_VENV";; *) venv="$XPBD_VENV";; esac
  case $name in on_*) sw=2;; *) sw="";; esac
  case $name in *_res) res=1;; *) res=0;; esac
  X=$(mktemp -d); cp -R tools $X/
  (cd $X && . "$venv/bin/activate" && if [ -n "$sw" ]; then export NEWTON_XPBD_RESTITUTION_FRICTION=$sw; else unset NEWTON_XPBD_RESTITUTION_FRICTION; fi && play_arm $res)
  mkdir -p $ROOT/$OUT/$name; cp -R $X/runs $X/stats $ROOT/$OUT/$name/; rm -rf $X
}
date -u +%FT%TZ > $OUT/started.txt
n=0
for a in $ARMS; do
  arm $a &
  n=$((n + 1)); if [ $((n % 3)) = 0 ]; then wait; fi
done
wait
date -u +%FT%TZ > $OUT/finished.txt
# ---- measuring
pick() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
M=$OUT/measured.txt; : > $M
for a in $ARMS; do
  d=$OUT/$a
  for dt in $STEPS; do
    echo "$a drop $dt rebound_per_10000 $("$B" bounce $d/runs/drop_$dt.txt | tail -1 | pick rebound_per_10000)" >> $M
    echo "$a oblique $dt impact $("$B" impact $d/runs/oblique_$dt.txt | tail -1 | pick ratio_per_10000) settle $("$B" settle $d/runs/oblique_$dt.txt | tail -1 | pick ratio_per_10000) most_tilt_urad $(pick most_tilt_urad < $d/stats/oblique_$dt.txt)" >> $M
  done
  echo "$a nan_plays $(cat $d/stats/*.txt | grep -c nan_at_step)" >> $M
done
[ "${DRY:-0}" = 1 ] && { echo "dry run: $(wc -l < $M | tr -d ' ') measured lines"; cat $M; exit 0; }
get() { grep "^$1 " $M | pick "$2"; }
# ---- the rules
R=$OUT/rules.txt; : > $R
rule() { "$B" rule "$@" | tail -1 >> $R; }
ident() {  # <arm a> <arm b> [file ...]: identical files, then files compared (all play files when none given)
  local a=$1 b=$2 n=0 same=0 f; shift 2
  if [ $# = 0 ]; then set -- $(cd $OUT/$a/runs && ls *_0*.txt); fi
  for f in "$@"; do n=$((n + 1)); cmp -s $OUT/$a/runs/$f $OUT/$b/runs/$f && same=$((same + 1)); done
  echo "$same $n"
}
read s1 n1 < <(ident off_plain stock_plain); read s2 n2 < <(ident off_res stock_res)
rule R1_safe_when_off eq $((s1 + s2)) $((n1 + n2))
rule R2_bounce_there all_ge 100 $(for dt in $STEPS; do grep "^stock_plain drop $dt " $M | pick rebound_per_10000; done)
rule R2_friction_lost all_le 3150 $(for dt in $STEPS; do grep "^stock_res oblique $dt " $M | pick impact; done)
rule R3_no_bounce all_le 10 $(for dt in $STEPS; do grep "^on_res drop $dt " $M | pick rebound_per_10000; done)
rule R4_impact all_within 3500 100 $(for dt in $STEPS; do grep "^on_res oblique $dt " $M | pick impact; done)
rule R5_after_impact all_within 3500 100 $(for dt in $STEPS; do grep "^on_res oblique $dt " $M | pick settle; done)
read s6 n6 < <(ident on_res stock_res $(for dt in $STEPS; do echo slide_$dt.txt rest_$dt.txt hold_$dt.txt; done))
rule R6_nothing_else eq $s6 $n6
read s7 n7 < <(ident on_plain stock_plain)
rule R7_pass_not_run eq $s7 $n7
rule R8_no_nan eq $(( $(get "on_plain nan_plays" nan_plays) + $(get "on_res nan_plays" nan_plays) )) 0
echo "rules: $(wc -l < $R | tr -d ' '), held: $(grep -c ': HELD$' $R)" >> $R
cat $R
