#!/usr/bin/env bash
# Run 142: the thirty-ninth registered study (preregistrations/PREREGISTRATION_39.md), played once on Newton 1.7.0: VBD's
# legacy path far from the origin with Senua AI's VBD pose carry (NEWTON_VBD_POSE_CARRY=1) on the displacement patch and
# Newton's own rigid_avbd_joint_alpha=0, issue 12. Each play into runs/, its error stream into runs/err_<play>.txt and its
# statistics into stats/, then the registered rules judged by sx_contact rule (rules.txt), the measured lines beside them
# (measured.txt). DRY=1 plays every play for 0.02 s, into dry/, to check that the runner runs to the end.
# usage: play.sh <sx_contact binary> <engine folder> [parallel plays]   (repository root)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary> <engine folder>}")" && pwd)/$(basename "$1")"; E="$(cd "${2:?}" && pwd)"; P=${3:-4}
O=validation/run_142_study_39
if [ "${DRY:-0}" = 1 ]; then OUT=$O/dry; CS=0.02; SS=0.02; LS=0.02; HS=0.02; HP=0.01; else OUT=$O; CS=2; SS=1.2; LS=0.5; HS=1.2; HP=0.3; fi
LEG="opt.rigid_compliant_alm=false opt.rigid_avbd_joint_alpha=0.0"
CH="mass1=0.85 mass2=1.15 radius=0.04 arm1=0.26 len1=0.52 arm2=0.2 angle1=0 angle2=0.45 omega1=1.8 omega2=-1.4 gravity=0 secs=$CS solver=vbd"
SPIN="mass=1.3 radius=0.045 h0=1 gravity=0 wz0=3.8 comx=0.02 secs=$SS solver=vbd $LEG"
SL="mass=1.0 radius=0.04 h0=0 mu=0.4 vx0=0.8 secs=$LS solver=vbd $LEG"
HOLD="mass=1.25 radius=0.045 h0=0 mu=0.5 push=3.0625 pushat=$HP secs=$HS solver=vbd $LEG opt.rigid_contact_history=true matching=sticky"
CDT="0.0004 0.0002 0.0001 0.00005 0.000025"; SDT="0.0012 0.00024 0.00006"; LDT="0.0012 0.00024 0.00006 0.00003"; HDT="0.0012 0.00006"
plays() { local g x dt; for g in dsp off on; do
  for x in 0 20 50; do for dt in $CDT; do echo "c_x${x}_${g}_$dt $g dt=$dt x0=$x $CH $LEG"; done; done
  for dt in $SDT; do echo "s_${g}_$dt $g dt=$dt $SPIN"; done
  for dt in $LDT; do echo "l_${g}_$dt $g dt=$dt $SL"; done
  for dt in $HDT; do echo "h_${g}_$dt $g dt=$dt $HOLD"; done; done
  for x in 0 20 50; do for dt in $CDT; do echo "c_x${x}_ona_$dt on dt=$dt x0=$x $CH opt.rigid_compliant_alm=false"; done; done; }
mkdir -p $OUT/runs $OUT/stats; date -u +%FT%TZ > $OUT/started.txt
one() {  # <play> <group> <setting ...>: the chain by nwt_chain.py, the rest by nwt_contact.py, under its group's engine
  local n=$1 g=$2; shift 2; local v=$E/carry; [ $g = dsp ] && v=$E/dsp
  ( . "$v/bin/activate"; export NEWTON_VBD_DISPLACEMENT=1; unset NEWTON_VBD_POSE_CARRY; [ $g = on ] && export NEWTON_VBD_POSE_CARRY=1
    case $n in c_*) r=tools/nwt_chain.py;; *) r=tools/nwt_contact.py;; esac
    python $r $OUT/runs/$n.txt "$@" > $OUT/stats/$n.txt 2> $OUT/runs/err_$n.txt )
}
export -f one; export E OUT
plays | xargs -P $P -L 1 bash -c 'one "$@"' _
date -u +%FT%TZ > $OUT/finished.txt
grep -rlIF "$HOME" $OUT 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
pick() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
M=$OUT/measured.txt; : > $M
for n in $(plays | awk '{ print $1 }'); do st=$(pick nan_at_step < $OUT/stats/$n.txt); [ -n "$st" ] || st=$(pick out_of_range_at_step < $OUT/stats/$n.txt)
  case $n in c_*) m=chain;; l_*) m=stop;; *) m=creep;; esac
  echo "$n stops ${st:--1} $("$B" $m $OUT/runs/$n.txt < /dev/null | tail -1)" >> $M; done
[ "${DRY:-0}" = 1 ] && { echo "dry run: $(wc -l < $M | tr -d ' ') measured lines"; cat $M; exit 0; }
v() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $M; }
dep() { v "$1" energy_largest_drift_ppm; }
R=$OUT/rules.txt; : > $R
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $R; }
same=0; tot=0; for n in $(plays | awk '$2 == "dsp" { print $1 }'); do tot=$((tot + 1)); cmp -s $OUT/runs/$n.txt $OUT/runs/${n/_dsp_/_off_}.txt && same=$((same + 1)); done
rule R1_safe_when_off eq $same $tot
for x in 20 50; do rule R2_far_grows_off_x$x ge $(dep c_x${x}_off_0.000025) $(( $(dep c_x0_off_0.000025) * 2 )); done
for dt in $CDT; do rule R3_far_as_origin_$dt all_within $(dep c_x0_on_$dt) 10 $(dep c_x20_on_$dt) $(dep c_x50_on_$dt); done
for x in 0 20 50; do rule R4_falls_x$x falls $(for dt in $CDT; do dep c_x${x}_on_$dt; done); done
rule R5_spin_centre_still all_in -3 3 $(for dt in $SDT; do v s_on_$dt mean_speed_ums; done)
rule R5_slide_settles all_within $(v l_on_0.00003 slid_um) 200 $(v l_on_0.00024 slid_um) $(v l_on_0.00006 slid_um)
rule R5_hold_kept all_in -10 10 $(for dt in $HDT; do v h_on_$dt mean_speed_ums; done)
rule R6_numbers all_eq -1 $(plays | awk '{ print $1 }' | while read -r n; do v $n stops; done)
echo "rules: $(wc -l < $R | tr -d ' '), held: $(grep -c ': HELD$' $R)" >> $R
cat $R
