#!/usr/bin/env bash
# Run 030, a probe of a reported issue (not registered): N8, Featherstone with a body's centre of mass off its origin,
# where users report the centre drifting under pure rotation (newton-physics/newton #1366, #12). The rig gains three
# settings for it (tools/nwt_contact.py): gravity=0, comx (the box, and so the centre of mass, placed off the body's
# origin along its x) and wz0 (a spin about z at the start, about the centre of mass, which starts at rest; Newton 1.6's
# free-joint velocity is the centre of mass's, world frame). Each is a no-op at its default: the checks below replay
# earlier plays.
# The scene: a 1 kg cube, half-size 0.05 m, 1 m above the ground, no gravity, set spinning at 5 rad/s about z, 2 s,
# with its centre of mass 0.05 m off its origin (comx 0.05) and, as the control, at it (comx 0). Nothing acts on it, so
# its centre of mass must stay at rest: the rig's speed column (the centre of mass's, along x) must read 0. Read by
# Senua AI's sx_contact creep (the mean speed over the second half) and stop (the largest speed in the last third).
# Featherstone, SemiImplicit, XPBD, the MuJoCo solver and VBD-ALM at 10 ms, 2.5 ms and 0.625 ms.
# Predicted, before the plays, from the reports:
#   P1  on Featherstone with the centre of mass off the origin, the centre moves: its largest speed in the last third
#       is over 10 um/s at every step.
#   P2  on Featherstone with the centre of mass at the origin, it stays: 10 um/s or less at every step.
#   P3  on SemiImplicit, XPBD, the MuJoCo solver and VBD-ALM, with the offset, it stays: 10 um/s or less at every step.
#   Checks: the changed rig gives four earlier plays byte for byte: run 001's hold on SemiImplicit at 0.125 ms, its slide
#   on VBD-ALM at 0.125 ms, run 004's plate on XPBD, run 007's drop at 2.5 ms on XPBD.
# usage: play.sh <sx_contact binary>   (repository root, Newton from PyPI's environment on; writes the reading)
set -u
B="${1:?usage: play.sh <sx_contact binary>}"
O=validation/run_030_com_offset_spin; W=$O/runs; mkdir -p $W
: > $W/stats.txt; : > $W/log.txt
T="python tools/nwt_contact.py"
SPIN="mass=1 radius=0.05 h0=1 gravity=0 wz0=5 secs=2"
one() {  # <name> <rig settings...>
  local n=$1; shift
  $T $W/$n.txt "$@" 2>> $W/log.txt | sed "s/^STATS/STATS $n/" >> $W/stats.txt
}
lane() {  # <solver>
  local s=$1 dt
  for dt in 0.01 0.0025 0.000625; do
    one spin_${s}_off_$dt dt=$dt $SPIN comx=0.05 solver=$s
    if [ $s = featherstone ]; then one spin_${s}_at_$dt dt=$dt $SPIN solver=$s; fi
  done
}
date -u +%FT%TZ > $O/started.txt
( lane featherstone; one check_hold_semi dt=0.000125 h0=0 mu=0.5 push=2.94 pushat=0.5 secs=2 solver=semi ) &
( lane semi; lane xpbd; one check_plate_xpbd dt=0.000125 radius=0.05 hz=0.005 h0=0.002 mu=0.4 kick=1 kickat=0.3 secs=1.3 solver=xpbd ) &
( lane mujoco; one check_drop_xpbd dt=0.002500000000 mass=2 radius=0.04 h0=0.08 secs=0.5 solver=xpbd ) &
( lane vbd_alm; one check_slide_vbd_alm dt=0.000125 h0=0 vx0=1 mu=0.4 secs=1 solver=vbd_alm ) &
wait
date -u +%FT%TZ > $O/finished.txt
pick() { awk -v k="$1" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
{
  for s in featherstone semi xpbd mujoco vbd_alm; do for c in off at; do for dt in 0.01 0.0025 0.000625; do
    f=$W/spin_${s}_${c}_$dt.txt; [ -f $f ] || continue
    echo "$s centre of mass $c the origin, $dt s | creep mean_speed_ums $("$B" creep $f | tail -1 | pick mean_speed_ums) | stop largest_speed_last_third_ums $("$B" stop $f | tail -1 | pick largest_speed_last_third_ums) slid_um $("$B" stop $f | tail -1 | pick slid_um)"
  done; done; done
  c() { if cmp -s $W/$1.txt $2; then echo "CHECK $1 byte-identical to $2: yes"; else echo "CHECK $1 byte-identical to $2: NO"; fi; }
  c check_hold_semi validation/run_001_design_probes/runs/hold_semi_0.000125.txt
  c check_slide_vbd_alm validation/run_001_design_probes/runs/slide_vbd_alm_0.000125.txt
  c check_plate_xpbd validation/run_004_plate/runs/plate_xpbd_0.000125.txt
  c check_drop_xpbd suites/1/xpbd/drop_4.txt
  echo "plays that stopped being a number: $(grep -c nan_at_step $W/stats.txt)"
} > $O/reading.txt
cat $O/reading.txt
