# nwt_joint.py: one arm on one hinge, for Newton: the first deep dive's sdx_joint scene and column format, so the same
# measuring program (Senua AI's `sx_contact`, in Simplex: swing, final, leave) reads Newton's runs unchanged. It calls
# Newton's own Python API, its only API, and does no measuring of its own.
# The arm is a cube of half-size `radius` whose centre is `arm` metres from the joint, along +x when the joint angle is
# zero; the joint is at the world's origin and turns about +z, and gravity, when it is on, is along -y, so a level arm
# swings down under a torque of mass x 9.8 x arm. The arm collides with nothing. Things with a right answer:
#   - with no limit in reach the arm is a pendulum and keeps its energy: released level, it comes up level on the
#     other side, every swing;
#   - a joint limit given a stiffness and a damping (Newton's limit_ke and limit_kd, N m/rad and N m s/rad) acts on
#     the arm past the limit as that spring and damper: what the arm keeps of its speed from one strike follows from the
#     damping ratio kd / (2 sqrt(ke I)), I the arm's inertia about the joint.
# usage: python nwt_joint.py <out.txt> dt=<seconds> [mass=KG] [radius=M] [arm=M] [angle0=RAD] [omega0=RAD_S] [secs=S]
#          [gravity=0|1] [lo=RAD hi=RAD] [limitk=N_M_RAD] [limitd=N_M_S_RAD] [solver=featherstone|mujoco|xpbd|semi|vbd]
#          [iterations=N] [torque=N_M] [drivek=N_M_RAD drived=N_M_S_RAD target=RAD] [vlimit=RAD_S] [elimit=N_M]
#          [place=first] [opt.NAME=VALUE]
#   defaults as sdx_joint: 1 kg, 0.05 m, 0.5 m, level and at rest, 2 s, gravity on, no limit
#   lo, hi  the joint's limits, radians, both given or neither; limitk, limitd their stiffness and damping (default:
#           Newton's, limit_ke 1e4 and limit_kd 10), passed to Newton's add_joint_revolute
#   solver  one of Newton's solvers that play joints; unset = featherstone. Its own defaults otherwise
#   torque  a constant torque about the joint's axis, N m, through Newton's control.joint_f, every step (unset: none)
#   drivek, drived, target  a drive on the joint: Newton's target_ke, target_kd and target_pos (N m/rad, N m s/rad,
#           rad), passed to add_joint_revolute; any one given, the others default to 0 (unset: no drive)
#   vlimit, elimit  the joint's velocity and effort limits (rad/s, N m), add_joint_revolute's velocity_limit and
#           effort_limit (unset: Newton's defaults)
#   place   first: the model's bodies placed from its joints' start (newton.eval_fk on the model) before the solver
#           is built, for a solver that captures its joints' rest angles when built (VBD); unset: the solver built
#           first, as every earlier play
#   opt.<name>=<value>  one of the solver's own constructor options, passed as given
# What is read: Featherstone and the MuJoCo solver keep the joint's angle and speed as their state; for XPBD,
# SemiImplicit and VBD, which keep the body as theirs, the joint's angle and speed are Newton's inverse kinematics of
# it (newton.eval_ik). Runs on the CPU.
# writes <out.txt>: a header line "CONTACT dt_ns <n> h0_nm 0 vx0_ums 0 mu_ppm 0 mass_g <n> steps <n>" (the header the
#   measuring harness reads), then one line a step, the state the step ended in: "<step> <joint angle, micro-radians>
#   <joint speed, micro-radians a second> 0 0 0"
# prints one STATS line. If the engine's state stops being a number, the file ends at the step before and the STATS line
# says where (nan_at_step); the same if a number no longer fits the format's 64-bit whole numbers
# (out_of_range_at_step). Exit 0.
import math
import sys

import numpy as np
import warp as wp

wp.config.log_level = wp.LOG_WARNING  # Warp's start-up and kernel-load messages, which go to the output, off

import newton  # noqa: E402

REDUCED = ("featherstone", "mujoco")  # the solvers whose state is the joints'


def whole(x):
    # to the nearest whole number, halves away from zero, as the C rigs' llround
    return int(math.floor(x + 0.5)) if x >= 0.0 else -int(math.floor(-x + 0.5))


def main(argv):
    if len(argv) < 3:
        sys.stderr.write("usage: nwt_joint.py <out.txt> dt=<seconds> [mass=] [radius=] [arm=] [angle0=] [omega0=] "
                         "[secs=] [gravity=0|1] [lo= hi=] [limitk=] [limitd=] [solver=NAME] [iterations=N] "
                         "[torque=] [drivek= drived= target=] [vlimit=] [elimit=] [place=first] "
                         "[opt.NAME=VALUE]\n")
        return 2
    s = {"dt": 0.0, "mass": 1.0, "radius": 0.05, "arm": 0.5, "angle0": 0.0, "omega0": 0.0, "secs": 2.0,
         "gravity": 1.0}
    lim = {}  # lo, hi, limitk, limitd, when given
    act = {}  # torque, drivek, drived, target, when given
    solver_name, iterations = "featherstone", None
    place_first = False
    opts = {}
    for a in argv[2:]:
        k, _, v = a.partition("=")
        if k in s:
            s[k] = float(v)
        elif k in ("torque", "drivek", "drived", "target", "vlimit", "elimit"):
            act[k] = float(v)
        elif k in ("lo", "hi", "limitk", "limitd"):
            lim[k] = float(v)
        elif k == "place" and v == "first":
            place_first = True
        elif k == "solver":
            solver_name = v
        elif k == "iterations":
            iterations = int(v)
        elif k.startswith("opt.") and len(k) > 4:
            opts[k[4:]] = {"true": True, "false": False}.get(v.lower(), None)
            if opts[k[4:]] is None:
                try:
                    opts[k[4:]] = int(v)
                except ValueError:
                    try:
                        opts[k[4:]] = float(v)
                    except ValueError:
                        opts[k[4:]] = v
        else:
            sys.stderr.write("nwt_joint: unknown setting %s\n" % a)
            return 2
    dt, r, m = s["dt"], s["radius"], s["mass"]
    gravity = 1 if s["gravity"] != 0.0 else 0
    if ("lo" in lim) != ("hi" in lim):
        sys.stderr.write("nwt_joint: give both lo and hi, or neither\n")
        return 2
    if dt <= 0.0:
        sys.stderr.write("nwt_joint: dt must be given\n")
        return 2
    wp.set_device("cpu")

    builder = newton.ModelBuilder(gravity=(0.0, -9.8 if gravity else 0.0, 0.0))  # gravity along -y, as sdx_joint
    cfg = newton.ModelBuilder.ShapeConfig(density=m / (8.0 * r * r * r))
    cfg.has_shape_collision = False
    cfg.has_particle_collision = False
    link = builder.add_link(xform=wp.transform_identity(), label="arm")
    builder.add_shape_box(link, xform=wp.transform(p=wp.vec3(s["arm"], 0.0, 0.0), q=wp.quat_identity()), hx=r, hy=r,
                          hz=r, cfg=cfg)
    kw_limit = {}
    if "lo" in lim:
        kw_limit = {"limit_lower": lim["lo"], "limit_upper": lim["hi"]}
    if "limitk" in lim:
        kw_limit["limit_ke"] = lim["limitk"]
    if "limitd" in lim:
        kw_limit["limit_kd"] = lim["limitd"]
    if "drivek" in act or "drived" in act or "target" in act:
        kw_limit.update({"target_ke": act.get("drivek", 0.0), "target_kd": act.get("drived", 0.0),
                         "target_pos": act.get("target", 0.0)})
    if "vlimit" in act:
        kw_limit["velocity_limit"] = act["vlimit"]
    if "elimit" in act:
        kw_limit["effort_limit"] = act["elimit"]
    joint = builder.add_joint_revolute(parent=-1, child=link, axis=(0.0, 0.0, 1.0), parent_xform=wp.transform_identity(),
                                       child_xform=wp.transform_identity(), label="j", **kw_limit)
    builder.add_articulation([joint])
    builder.joint_q[0] = s["angle0"]
    builder.joint_qd[0] = s["omega0"]
    if solver_name == "vbd":
        builder.color()
    model = builder.finalize(device="cpu")

    if place_first:
        newton.eval_fk(model, model.joint_q, model.joint_qd, model)  # the bodies placed before the solver is built
    kw = {} if iterations is None else {"iterations": iterations}
    kw.update(opts)
    solvers = {"featherstone": newton.solvers.SolverFeatherstone, "mujoco": newton.solvers.SolverMuJoCo,
               "xpbd": newton.solvers.SolverXPBD, "semi": newton.solvers.SolverSemiImplicit,
               "vbd": newton.solvers.SolverVBD}
    solver = solvers[solver_name](model, **kw)
    state_0, state_1 = model.state(), model.state()
    control = model.control()
    if "torque" in act:
        control.joint_f.assign(np.array([act["torque"]], dtype=np.float32))
    newton.eval_fk(model, state_0.joint_q, state_0.joint_qd, state_0)  # the body placed from the joint's start

    steps = int(round(s["secs"] / dt))
    nan_at = None
    out_at = None
    with open(argv[1], "w") as f:
        f.write("CONTACT dt_ns %d h0_nm 0 vx0_ums 0 mu_ppm 0 mass_g %d steps %d\n" % (whole(dt * 1e9), whole(m * 1e3),
                                                                                       steps))
        for i in range(steps):
            state_0.clear_forces()
            solver.step(state_0, state_1, control, None, dt)
            state_0, state_1 = state_1, state_0
            if solver_name in REDUCED:
                newton.eval_fk(model, state_0.joint_q, state_0.joint_qd, state_0)
            else:
                newton.eval_ik(model, state_0, state_0.joint_q, state_0.joint_qd)
            jq = np.asarray(state_0.joint_q.numpy(), dtype=np.float64)
            jqd = np.asarray(state_0.joint_qd.numpy(), dtype=np.float64)
            if not (np.isfinite(jq[0]) and np.isfinite(jqd[0])):
                nan_at = i
                break
            line = [i, whole(jq[0] * 1e6), whole(jqd[0] * 1e6), 0, 0, 0]
            if not all(abs(v) < 2 ** 63 for v in line):
                out_at = i
                break
            f.write(" ".join(str(x) for x in line) + "\n")
    print("STATS joint dt %g mass %g radius %g arm %g gravity %d steps %d%s%s engine newton %s solver %s extra %s" % (
        dt, m, r, s["arm"], gravity, steps, "" if nan_at is None else " nan_at_step %d" % nan_at,
        "" if out_at is None else " out_of_range_at_step %d" % out_at, newton.__version__, solver_name,
        " ".join(([] if iterations is None else ["iterations=%d" % iterations]) + (["place=first"] if place_first else []) +
                 ["opt.%s=%s" % (k, opts[k]) for k in opts] +
                 ["%s=%g" % (k, lim[k]) for k in ("lo", "hi", "limitk", "limitd") if k in lim] +
                 ["%s=%g" % (k, act[k]) for k in ("torque", "drivek", "drived", "target", "vlimit", "elimit") if k in act]) or
                "none"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
