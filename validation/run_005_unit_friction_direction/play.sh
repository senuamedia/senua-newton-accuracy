#!/usr/bin/env bash
# Run 005, a patch in design (not registered): patches/in_design/unit_friction_direction.diff, Newton v1.6.1 with
# SemiImplicit and Featherstone's body contact kernel replaced, only when NEWTON_UNIT_FRICTION_DIRECTION=1, by a copy
# whose friction has a unit direction and a size of min(kf |vt|, mu N). Three arms, each in its own scratch folder:
#   stock     Newton 1.6.1 from PyPI (run 001's environment)
#   off       Newton v1.6.1 from source with the patch applied, the switch unset (the same dependencies, pinned)
#   on        the same, NEWTON_UNIT_FRICTION_DIRECTION=1
# each playing, at 0.125 ms: run 001's five one-cube scenes on SemiImplicit and Featherstone; run 003's settled slide
# on both; run 004's plate on both with friction_smoothing 1.0 and 0.01; and run 001's slide and hold on XPBD and the
# MuJoCo solver, which do not use the kernel. Then off against stock byte for byte, and the readings.
# usage: play.sh <sx_contact binary>   (from the repository root; STOCK_VENV and PATCHED_VENV set to the two
#        Python environments)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary>}")" && pwd)/$(basename "$1")"
O=validation/run_005_unit_friction_direction; mkdir -p $O; ROOT=$(pwd)
dt=0.000125
plays() {  # every play of one arm into runs/, one process a solver
  local s
  for s in semi featherstone; do
    { python tools/nwt_contact.py runs/hold_${s}.txt dt=$dt h0=0 mu=0.5 push=2.94 pushat=0.5 secs=2 solver=$s
      python tools/nwt_contact.py runs/rest_${s}.txt dt=$dt h0=0.02 mu=0.5 secs=1 solver=$s
      python tools/nwt_contact.py runs/bounce_${s}.txt dt=$dt h0=0.1 mu=0 secs=1 solver=$s
      python tools/nwt_contact.py runs/oblique_${s}.txt dt=$dt h0=0.05 vx0=2 mu=0.3 secs=0.5 solver=$s
      python tools/nwt_contact.py runs/slide_${s}.txt dt=$dt h0=0 vx0=1 mu=0.4 secs=1 solver=$s
      python tools/nwt_contact.py runs/settled_${s}.txt dt=$dt h0=0.002 mu=0.4 kick=1 kickat=0.3 secs=1.3 solver=$s
      python tools/nwt_contact.py runs/plate_${s}_1.0.txt dt=$dt radius=0.05 hz=0.005 h0=0.002 mu=0.4 kick=1 kickat=0.3 secs=1.3 solver=$s
      python tools/nwt_contact.py runs/plate_${s}_0.01.txt dt=$dt radius=0.05 hz=0.005 h0=0.002 mu=0.4 kick=1 kickat=0.3 secs=1.3 solver=$s opt.friction_smoothing=0.01
    } > runs/stats_$s.txt 2> runs/log_$s.txt &
  done
  for s in xpbd mujoco; do
    { python tools/nwt_contact.py runs/hold_${s}.txt dt=$dt h0=0 mu=0.5 push=2.94 pushat=0.5 secs=2 solver=$s
      python tools/nwt_contact.py runs/slide_${s}.txt dt=$dt h0=0 vx0=1 mu=0.4 secs=1 solver=$s
    } > runs/stats_$s.txt 2> runs/log_$s.txt
  done
  wait
}
arm() {  # <name> <venv> [switch]
  local name=$1 venv=$2 sw=${3:-} X
  X=$(mktemp -d); cp -R tools $X/; mkdir -p $X/runs
  (cd $X && . "$venv/bin/activate" && if [ -n "$sw" ]; then export NEWTON_UNIT_FRICTION_DIRECTION=$sw; else unset NEWTON_UNIT_FRICTION_DIRECTION; fi && plays)
  rm -rf $ROOT/$O/$name; mkdir -p $ROOT/$O/$name; cp -R $X/runs $ROOT/$O/$name/; rm -rf $X
}
arm stock "$STOCK_VENV"
arm off "$PATCHED_VENV"
arm on "$PATCHED_VENV" 1
( cd $O && for f in stock/runs/*.txt; do
    n=$(basename $f); case $n in log_*) continue;; esac
    if cmp -s $f off/runs/$n; then echo "SAME $n"; else echo "DIFFERS $n"; fi
  done ) > $O/identity_off.txt
echo "off against stock: $(grep -c '^SAME' $O/identity_off.txt) the same, $(grep -c '^DIFFERS' $O/identity_off.txt) not"
( cd $O && for a in stock on; do
    for s in semi featherstone; do
      r=$a/runs
      echo "$a $s hold | $($B creep $r/hold_$s.txt | tail -1)"
      echo "$a $s rest | $($B rest $r/rest_$s.txt | tail -1)"
      echo "$a $s bounce | $($B bounce $r/bounce_$s.txt | tail -1)"
      echo "$a $s oblique | $($B impact $r/oblique_$s.txt | tail -1)"
      echo "$a $s slide | $($B stop $r/slide_$s.txt | tail -1)"
      echo "$a $s settled | $($B stop $r/settled_$s.txt | tail -1 | grep -o 'slid_um [0-9]* came_back_um [0-9]*') | 310-320 ms $($B accel $r/settled_$s.txt 310 320 | tail -1 | grep -o 'mean_acceleration_mm_s2 [-0-9]*')"
      for fs in 1.0 0.01; do
        echo "$a $s plate $fs | $($B stop $r/plate_${s}_$fs.txt | tail -1 | grep -o 'slid_um [0-9]* came_back_um [0-9]*') | 302-305 ms $($B accel $r/plate_${s}_$fs.txt 302 305 | tail -1 | grep -o 'mean_acceleration_mm_s2 [-0-9]*') | 310-320 ms $($B accel $r/plate_${s}_$fs.txt 310 320 | tail -1 | grep -o 'mean_acceleration_mm_s2 [-0-9]*') | 330-350 ms $($B accel $r/plate_${s}_$fs.txt 330 350 | tail -1 | grep -o 'mean_acceleration_mm_s2 [-0-9]*')"
      done
    done
    for s in xpbd mujoco; do
      if cmp -s stock/runs/hold_$s.txt $a/runs/hold_$s.txt && cmp -s stock/runs/slide_$s.txt $a/runs/slide_$s.txt; then r=yes; else r=NO; fi
      echo "$a $s: hold and slide byte-identical to stock: $r"
    done
  done ) > $O/reading.txt
