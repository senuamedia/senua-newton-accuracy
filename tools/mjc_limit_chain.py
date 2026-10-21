# mjc_limit_chain.py: nwt_chain.py's chain (two arms on two hinge joints, nothing touching them) played on MuJoCo's own
# C engine through its Python API, the first joint limited, its limit's stiffness set by MuJoCo's own constraint
# parameters, so that a sequence of ever stiffer, critically damped limits converges on a hard limit struck without a
# rebound. It calls MuJoCo's API, its only API, and does no measuring of its own; it writes nwt_chain.py's format,
# column for column, so Senua AI's `sx_contact chain` reads it unchanged.
# The chain as nwt_chain.py builds it: the first arm on a joint at the world's origin, the second on a joint carried by
# the first, both turning about +z, gravity when on along -y; each arm a cube of half-size `radius` and the given mass
# (MuJoCo's uniform-density box inertia, as Newton's), the first arm's centre `arm1` from the first joint, the second
# joint `len1` out, the second arm's centre `arm2` beyond it, along +x at the start.
# usage: python mjc_limit_chain.py <out.txt> dt=<seconds> [mass1=KG] [mass2=KG] [radius=M] [arm1=M] [len1=M] [arm2=M]
#          [angle1=RAD] [angle2=RAD] [omega1=RAD_S] [omega2=RAD_S] [secs=S] [gravity=0|1] lo1=RAD hi1=RAD
#          [timeconst=S] [dampratio=X] [imp0=X] [imp1=X] [impwidth=M] [integrator=rk4|euler|implicit] [every=N]
#   timeconst, dampratio  the limit's solreflimit (MuJoCo's default 0.02 and 1: a critically damped limit of that time
#           constant); imp0, imp1, impwidth its solimplimit (MuJoCo's default 0.9, 0.95, 0.001)
#   integrator  MuJoCo's (default rk4)
#   every   write the state every Nth step only (default 1), each line still numbered by its step
# writes <out.txt>: nwt_chain.py's header line and one line a step, 15 whole numbers (the joints' angles and speeds in
# micro-radians and micro-radians a second; each arm's centre, its velocity and its spin about z), step -1 the start.
# prints one STATS line. Exit 0.
import math
import sys

import mujoco
import numpy as np


def whole(x):
    # to the nearest whole number, halves away from zero, as nwt_chain.py's
    return int(math.floor(x + 0.5)) if x >= 0.0 else -int(math.floor(-x + 0.5))


def main(argv):
    if len(argv) < 3:
        sys.stderr.write("usage: mjc_limit_chain.py <out.txt> dt=<seconds> [mass1=] [mass2=] [radius=] [arm1=] [len1=] "
                         "[arm2=] [angle1=] [angle2=] [omega1=] [omega2=] [secs=] [gravity=0|1] lo1=RAD hi1=RAD "
                         "[timeconst=] [dampratio=] [imp0=] [imp1=] [impwidth=] [integrator=rk4|euler|implicit] "
                         "[every=N]\n")
        return 2
    s = {"dt": 0.0, "mass1": 1.0, "mass2": 1.0, "radius": 0.05, "arm1": 0.2, "len1": 0.4, "arm2": 0.2,
         "angle1": 0.0, "angle2": 0.0, "omega1": 0.0, "omega2": 0.0, "secs": 2.0, "gravity": 1.0,
         "lo1": float("nan"), "hi1": float("nan"), "timeconst": 0.02, "dampratio": 1.0, "imp0": 0.9, "imp1": 0.95,
         "impwidth": 0.001, "every": 1.0}
    integrator = "rk4"
    for a in argv[2:]:
        k, _, v = a.partition("=")
        if k in s:
            s[k] = float(v)
        elif k == "integrator":
            integrator = v
        else:
            sys.stderr.write("mjc_limit_chain: unknown setting %s\n" % a)
            return 2
    dt, r = s["dt"], s["radius"]
    if dt <= 0.0 or math.isnan(s["lo1"]) or math.isnan(s["hi1"]):
        sys.stderr.write("mjc_limit_chain: dt, lo1 and hi1 must be given\n")
        return 2
    gravity = 1 if s["gravity"] != 0.0 else 0
    names = {"rk4": "RK4", "euler": "Euler", "implicit": "implicit"}
    xml = """<mujoco>
  <compiler angle="radian"/>
  <option timestep="%.17g" integrator="%s" gravity="0 %g 0"/>
  <worldbody>
    <body name="arm1" pos="0 0 0">
      <joint name="j1" type="hinge" axis="0 0 1" limited="true" range="%.17g %.17g"
             solreflimit="%.17g %.17g" solimplimit="%.17g %.17g %.17g"/>
      <geom type="box" size="%.17g %.17g %.17g" pos="%.17g 0 0" mass="%.17g" contype="0" conaffinity="0"/>
      <body name="arm2" pos="%.17g 0 0">
        <joint name="j2" type="hinge" axis="0 0 1"/>
        <geom type="box" size="%.17g %.17g %.17g" pos="%.17g 0 0" mass="%.17g" contype="0" conaffinity="0"/>
      </body>
    </body>
  </worldbody>
</mujoco>""" % (dt, names[integrator], -9.8 if gravity else 0.0, s["lo1"], s["hi1"], s["timeconst"], s["dampratio"],
                s["imp0"], s["imp1"], s["impwidth"], r, r, r, s["arm1"], s["mass1"], s["len1"], r, r, r, s["arm2"],
                s["mass2"])
    m = mujoco.MjModel.from_xml_string(xml)
    d = mujoco.MjData(m)
    d.qpos[0], d.qpos[1] = s["angle1"], s["angle2"]
    d.qvel[0], d.qvel[1] = s["omega1"], s["omega2"]
    mujoco.mj_forward(m, d)
    geoms = [mujoco.mj_name2id(m, mujoco.mjtObj.mjOBJ_BODY, b) for b in ("arm1", "arm2")]
    vel = np.zeros(6)

    def row(step):
        out = [step, whole(d.qpos[0] * 1e6), whole(d.qvel[0] * 1e6), whole(d.qpos[1] * 1e6), whole(d.qvel[1] * 1e6)]
        for g in range(2):
            c = d.geom_xpos[g]  # the arm's cube, its centre and centre of mass
            mujoco.mj_objectVelocity(m, d, mujoco.mjtObj.mjOBJ_GEOM, g, vel, 0)  # world frame: angular, then linear
            out += [whole(c[0] * 1e6), whole(c[1] * 1e6), whole(vel[3] * 1e6), whole(vel[4] * 1e6),
                    whole(vel[2] * 1e6)]
        return out

    steps = int(round(s["secs"] / dt))
    every = max(1, int(s["every"]))
    nan_at = None
    with open(argv[1], "w") as f:
        f.write("CHAIN dt_ns %d mass1_g %d mass2_g %d radius_um %d arm1_um %d len1_um %d arm2_um %d gravity %d "
                "steps %d\n" % (whole(dt * 1e9), whole(s["mass1"] * 1e3), whole(s["mass2"] * 1e3), whole(r * 1e6),
                                whole(s["arm1"] * 1e6), whole(s["len1"] * 1e6), whole(s["arm2"] * 1e6), gravity,
                                steps))
        f.write(" ".join(str(x) for x in row(-1)) + "\n")
        for i in range(steps):
            mujoco.mj_step(m, d)
            if not (np.all(np.isfinite(d.qpos)) and np.all(np.isfinite(d.qvel))):
                nan_at = i
                break
            if (i + 1) % every == 0:
                f.write(" ".join(str(x) for x in row(i)) + "\n")
    print("STATS chain dt %g mass1 %g mass2 %g radius %g arm1 %g len1 %g arm2 %g gravity %d steps %d%s engine mujoco %s "
          "integrator %s limit lo1=%g hi1=%g solreflimit=%g,%g solimplimit=%g,%g,%g bodies %s" % (
              dt, s["mass1"], s["mass2"], r, s["arm1"], s["len1"], s["arm2"], gravity, steps,
              "" if nan_at is None else " nan_at_step %d" % nan_at, mujoco.__version__, integrator, s["lo1"], s["hi1"],
              s["timeconst"], s["dampratio"], s["imp0"], s["imp1"], s["impwidth"], ",".join(str(g) for g in geoms)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
