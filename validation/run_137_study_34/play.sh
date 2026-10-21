#!/usr/bin/env bash
# Run 137: the thirty-fourth registered study (preregistrations/PREREGISTRATION_34.md), played once on Newton 1.7.0: a
# fast body kept from passing through a thin slab (issue 20's tunnelling): on XPBD by Newton's own configuration (64
# iterations and speculative contacts), on SemiImplicit and Featherstone by Senua AI's speculative normal patch
# (NEWTON_SPECULATIVE_NORMAL=1, its third form: contacts strictly apart) with speculative contacts. Each play into runs/, its error stream into runs/err_<play>.txt
# and its statistics into stats/, then the registered rules judged by sx_contact rule (rules.txt), the measured lines
# beside them (measured.txt). DRY=1 plays one throwaway play of each scene and setting (0.008 s), into dry/, to check
# that the runner runs to the end.
# usage: play.sh <sx_contact binary> <engine folder> [parallel plays a setting]   (repository root)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary> <engine folder>}")" && pwd)/$(basename "$1")"; E="$(cd "${2:?}" && pwd)"; P=${3:-2}
O=validation/run_137_study_34
if [ "${DRY:-0}" = 1 ]; then OUT=$O/dry; else OUT=$O; fi
sc() { [ "${DRY:-0}" = 1 ] && echo 0.008 || echo $1; }
C="mass=0.9 radius=0.045 mu=0.45"; SPEC="specgap=1"
THREE="xpbd semi featherstone"; DTS="d4:0.004 d15:0.0015"
# the configuration: XPBD, the chain at 64 iterations with speculative contacts; SemiImplicit and Featherstone, the patch
# on with speculative contacts; the MuJoCo solver, as released with speculative contacts (reported)
cfg() { case $1 in xpbd) echo "chain solver=xpbd iterations=64 $SPEC";; mujoco) echo "stock solver=mujoco $SPEC";; *) echo "on solver=$1 $SPEC";; esac; }
plays() { local s q d t sc; for s in $THREE mujoco; do for q in $DTS; do d=${q%%:*}; t=${q#*:}
  for sc in in:0.05:80 out:0.25:100; do n=${sc%%:*}; h=$(echo $sc | cut -d: -f2); v=$(echo $sc | cut -d: -f3)
    X="$C dt=$t h0=$h vz0=-$v slab=0.005 secs=$(sc 0.1)"
    echo "${s}_${n}_${d}_rel stock $X solver=$s"
    echo "${s}_${n}_${d}_cfg $(cfg $s) $X"
    case $s in semi|featherstone) echo "${s}_${n}_${d}_off off $X solver=$s $SPEC"; echo "${s}_${n}_${d}_chs chain $X solver=$s $SPEC";; esac
  done; done; done
  for s in $THREE; do
    echo "${s}_slide_cfg $(cfg $s) $C dt=0.0005 h0=0 vx0=1.2 secs=$(sc 0.6)"
    echo "${s}_slide_chn chain $C dt=0.0005 h0=0 vx0=1.2 secs=$(sc 0.6) solver=$s$( [ $s = xpbd ] && echo " iterations=64")"
    echo "${s}_hold_cfg $(cfg $s) $C dt=0.0005 h0=0 push=2.3814 pushat=0.3 secs=$(sc 1.2)"
    echo "${s}_hold_chn chain $C dt=0.0005 h0=0 push=2.3814 pushat=0.3 secs=$(sc 1.2) solver=$s$( [ $s = xpbd ] && echo " iterations=64")"; done; }
mkdir -p $OUT/runs $OUT/stats; date -u +%FT%TZ > $OUT/started.txt
for g in stock chain off on; do
  ( . "$E/$( [ $g = off ] && echo on || echo $g )/bin/activate"
    export NEWTON_XPBD_NO_SPEED_FLOOR=1 NEWTON_XPBD_FRICTION_TOTAL=1 NEWTON_UNIT_FRICTION_DIRECTION=1 NEWTON_CONTACT_DAMPING_NO_PULL=1
    export NEWTON_SEMI_COULOMB_FRICTION=1 NEWTON_SEMI_COULOMB_FRICTION_ITERATIONS=64 NEWTON_FEATHERSTONE_COULOMB_FRICTION=64
    unset NEWTON_SPECULATIVE_NORMAL; [ $g = on ] && export NEWTON_SPECULATIVE_NORMAL=1
    plays | awk -v g=$g '$2 == g { $2 = ""; print }' | xargs -P $P -L 1 bash -c 'python tools/nwt_contact.py '"$OUT"'/runs/$0.txt "$@" > '"$OUT"'/stats/$0.txt 2> '"$OUT"'/runs/err_$0.txt' ) &
done
wait; date -u +%FT%TZ > $OUT/finished.txt
grep -rlIF "$HOME" $OUT 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
pick() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
M=$OUT/measured.txt; : > $M
# a drop is read by `final`: a CONTACT file's first column is the cube's lowest face's height (nm), which `final` names
# angle_urad, and its second the speed along x; the speed along z, the third column, is the last line's
for n in $(plays | awk '{ print $1 }'); do st=$(pick nan_at_step < $OUT/stats/$n.txt)
  case $n in *_slide_*) m=stop;; *_hold_*) m=creep;; *) m=final;; esac
  vz=$(tail -1 $OUT/runs/$n.txt | awk '{ print $4 }')
  echo "$n stops ${st:--1} end_vz_ums ${vz:--} $("$B" $m $OUT/runs/$n.txt < /dev/null | tail -1)" >> $M; done
[ "${DRY:-0}" = 1 ] && { echo "dry run: $(wc -l < $M | tr -d ' ') measured lines"; cat $M; exit 0; }
v() { awk -v n="$1" -v k="$2" '$1 == n { for (i = 2; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' $M; }
drops() { local s q n; for s in $THREE; do for q in $DTS; do for n in in out; do v ${s}_${n}_${q%%:*}_$1 angle_urad; done; done; done; }
R=$OUT/rules.txt; : > $R
rule() { "$B" rule "$@" < /dev/null | tail -1 >> $R; }
same=0; tot=0; for n in $(plays | awk '$2 == "chain" && $1 ~ /_chs$/ { print $1 }'); do tot=$((tot + 1)); cmp -s $OUT/runs/$n.txt $OUT/runs/${n%_chs}_off.txt && same=$((same + 1)); done
rule R1_safe_when_off eq $same $tot
rule R2_released_through all_le -5000000 $(drops rel)
rule R3_kept all_ge -2500000 $(drops cfg)
for s in $THREE; do rule R4_${s}_slide within $(v ${s}_slide_cfg slid_um) $(v ${s}_slide_chn slid_um) 1000; done
rule R4_held all_in -10 10 $(for s in $THREE; do v ${s}_hold_cfg mean_speed_ums; done)
rule R5_numbers all_eq -1 $(plays | awk '{ print $1 }' | while read -r n; do v $n stops; done)
echo "rules: $(wc -l < $R | tr -d ' '), held: $(grep -c ': HELD$' $R)" >> $R
cat $R $M
