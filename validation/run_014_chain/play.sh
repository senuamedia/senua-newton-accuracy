#!/usr/bin/env bash
# Run 014, design probe (not registered): the first deep dive's two-link chain on Newton's solvers that play joints,
# the same scenes as the MuJoCo deep dive's run 007 (Study 12's free chain and Study 15's swinging chain of the first
# deep dive), each for 2 s at 10 ms over 1, 4, 16 and 64. Rig tools/nwt_chain.py; measure: Senua AI's sx_contact chain.
#   free   no gravity, set turning: kinetic energy and angular momentum about the first joint must stay as they were
#   swing  gravity, released at rest: the total energy must stay as it was
# Each solver as released, and beside it the one option that is known to take energy out or that MuJoCo's C engine
# was read under in run 007:
#   featherstone, featherstone_d0  Featherstone as released (its angular_damping is 0.05), and with angular_damping 0
#   mujoco, mujoco_euler, mujoco_rk4  the MuJoCo solver as released (Newton's default integrator, implicitfast), with
#                                  Euler (MuJoCo's own default) and with RK4
#   xpbd                           XPBD as released
#   semi, semi_d0                  SemiImplicit as released (angular_damping 0.05), and with angular_damping 0
#   vbd, vbd_alm                   VBD as released (its legacy rigid path) and with rigid_compliant_alm, which Newton
#                                  1.6 says will become its default
# Four plays at a time (one Warp CPU thread each; a play does not depend on another).
# usage: play.sh <sx_contact binary>   (from the repository root, Newton's environment on; writes the reading to
#        validation/run_014_chain/reading.txt)
set -u
B="${1:?usage: play.sh <sx_contact binary>}"
O=validation/run_014_chain; W=$O/runs; mkdir -p $W
ARMS="mass1=1.2 mass2=0.6 radius=0.04 arm1=0.25 len1=0.5 arm2=0.2"
FREE="gravity=0 angle2=-0.9 omega1=2.5 omega2=1.5 secs=2"
SWING="gravity=1 angle1=0.4 angle2=-0.7 secs=2"
CONFS="featherstone featherstone_d0 mujoco mujoco_euler mujoco_rk4 xpbd semi semi_d0 vbd vbd_alm"
settings() {
  case $1 in
    featherstone) echo "solver=featherstone" ;; featherstone_d0) echo "solver=featherstone opt.angular_damping=0" ;;
    mujoco) echo "solver=mujoco" ;; mujoco_euler) echo "solver=mujoco opt.integrator=euler" ;;
    mujoco_rk4) echo "solver=mujoco opt.integrator=rk4" ;; xpbd) echo "solver=xpbd" ;;
    semi) echo "solver=semi" ;; semi_d0) echo "solver=semi opt.angular_damping=0" ;;
    vbd) echo "solver=vbd" ;; vbd_alm) echo "solver=vbd opt.rigid_compliant_alm=true" ;;
  esac
}
dt_of() { awk -v k=$1 'BEGIN { printf "%.12f", 0.01 / k }'; }
date -u +%FT%TZ > $O/started.txt
for c in $CONFS; do
  for k in 1 4 16 64; do
    echo "python tools/nwt_chain.py $W/free_${c}_$k.txt dt=$(dt_of $k) $ARMS $FREE $(settings $c) > $W/free_${c}_$k.stats 2> $W/free_${c}_$k.log"
    echo "python tools/nwt_chain.py $W/swing_${c}_$k.txt dt=$(dt_of $k) $ARMS $SWING $(settings $c) > $W/swing_${c}_$k.stats 2> $W/swing_${c}_$k.log"
  done
done > $W/commands.txt
xargs -P 4 -I CMD bash -c CMD < $W/commands.txt
date -u +%FT%TZ > $O/finished.txt
: > $W/stats.txt
for c in $CONFS; do for k in 1 4 16 64; do for sc in free swing; do cat $W/${sc}_${c}_$k.stats >> $W/stats.txt; done; done; done
for c in $CONFS; do
  for k in 1 4 16 64; do
    echo "free $c $k | $("$B" chain $W/free_${c}_$k.txt | tail -1)"
    echo "swing $c $k | $("$B" chain $W/swing_${c}_$k.txt | tail -1)"
  done
done > $O/reading.txt
