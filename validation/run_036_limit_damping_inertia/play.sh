#!/usr/bin/env bash
# Run 036, a probe of a reported issue (not registered): N5, joint-limit damping depending on inertia on the MuJoCo path
# (newton-physics/newton #4099: four similar pendulums got damping ratios 3.07, 0.31, 0.055 and 0.0097). A new rig,
# tools/nwt_joint.py, plays the first deep dive's one-arm scene (sdx_joint) on Newton and writes its format, so Senua
# AI's sx_contact swing reads the arm's turning points.
# Newton gives a joint limit a stiffness and a damping (limit_ke 1e4 N m/rad and limit_kd 10 N m s/rad by default):
# past the limit the arm meets that spring and damper, whose damping ratio is z = kd / (2 sqrt(ke I)), I the arm's
# inertia about the joint, so it falls as 1 / sqrt(I). Read in Newton 1.6.1's MuJoCo solver
# (update_jnt_solref_from_invweight0_kernel): it now scales MuJoCo's limit reference so that MuJoCo's effective
# stiffness and damping are Newton's limit_ke and limit_kd ("force space"), and lets MuJoCo's refsafe soften a limit too
# stiff for the step.
# The scene: an arm 0.4 m long (a cube of half-size 0.04 m at its end), released level with gravity, swinging down onto
# its lower limit at -1 rad (upper limit 1 rad, never reached), 2 s; masses 0.1, 1, 10 and 100 kg (I = 0.161 m,
# z = 0.39, 0.12, 0.039 and 0.012). A spring-damper strike keeps e = exp(-z pi / sqrt(1 - z^2)) of the speed, and the
# arm then turns at asin(-0.8415 (1 - e^2)): -0.90, -0.48, -0.19 and -0.06 rad (gravity during the strike neglected).
# Featherstone, the MuJoCo solver, XPBD and VBD, at 0.25 ms and 10 ms; Newton 1.6.1 from PyPI.
# Predicted, before the plays:
#   P1  Featherstone at 0.25 ms: the first turning point after the strike within 0.05 rad of -0.90, -0.48, -0.19 and
#       -0.06 rad for the four masses.
#   P2  the MuJoCo solver at 0.25 ms: within 0.02 rad of Featherstone's at each mass (the force-space conversion makes
#       its limit Newton's spring and damper; the reported inertia dependence does not occur in 1.6.1).
#   Reported, not predicted: 10 ms (where refsafe may soften the stiffer limits), XPBD and VBD; and, as a check of the
#   rig, the arm with no limit on the MuJoCo solver with RK4 at 0.25 ms (a pendulum comes up level, 10,000 per half turn).
# usage: play.sh <sx_contact binary>   (repository root, Newton from PyPI's environment on; writes the reading)
set -u
B="${1:?usage: play.sh <sx_contact binary>}"
O=validation/run_036_limit_damping_inertia; W=$O/runs; mkdir -p $W
: > $W/stats.txt; : > $W/log.txt
ARM="radius=0.04 arm=0.4 secs=2"
LIM="lo=-1 hi=1"
one() {  # <name> <rig settings...>
  local n=$1; shift
  python tools/nwt_joint.py $W/$n.txt $ARM "$@" 2>> $W/log.txt | sed "s/^STATS/STATS $n/" >> $W/stats.txt
}
lane() {  # <solver>
  local s=$1 m dt
  for dt in 0.00025 0.01; do for m in 0.1 1 10 100; do one lim_${s}_m${m}_$dt dt=$dt mass=$m $LIM solver=$s; done; done
}
date -u +%FT%TZ > $O/started.txt
lane featherstone & lane mujoco & lane xpbd & ( lane vbd; one free_mujoco_rk4_0.00025 dt=0.00025 mass=1 solver=mujoco opt.integrator=rk4 ) &
wait
date -u +%FT%TZ > $O/finished.txt
{
  for s in featherstone mujoco xpbd vbd; do for dt in 0.00025 0.01; do for m in 0.1 1 10 100; do
    echo "$s m $m kg $dt s | $("$B" swing $W/lim_${s}_m${m}_$dt.txt | tail -1)"
  done; done; done
  echo "rig check | $("$B" swing $W/free_mujoco_rk4_0.00025.txt | tail -1)"
  echo "plays that stopped being a number: $(grep -c nan_at_step $W/stats.txt)"
} > $O/reading.txt
cat $O/reading.txt
