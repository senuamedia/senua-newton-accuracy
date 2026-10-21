# nwt_chain.py: two arms on two hinge joints, with nothing touching them, for Newton: the first deep dive's sdx_chain
# scene and the MuJoCo deep dive's mjc_chain scene, scene for scene and column for column, so the same measuring
# program (Senua AI's `sx_contact chain`, in Simplex) reads Newton's runs unchanged. It calls Newton's own Python API,
# its only API, and does no measuring of its own.
# A first arm on a joint at the world's origin and a second arm on a joint carried by the first; both joints turn about
# +z and gravity, when it is on, is along -y, so the motion stays in the x-y plane: a double pendulum. Each arm is a
# cube of half-size `radius`, its mass given through the cube's density. The first arm's centre is `arm1` metres from
# the first joint and the second joint is `len1` metres from the first, both along the first arm's +x; the second
# arm's centre is `arm2` metres from the second joint, along the second arm's +x. The arms' shapes collide with
# nothing. Things with a right answer, none of which depends on how small the step is:
#   - with no gravity nothing does work on the chain: its kinetic energy stays what it was, and so does its angular
#     momentum about the first joint;
#   - with gravity its total energy (kinetic plus mass x 9.8 x height) stays what it was.
# usage: python nwt_chain.py <out.txt> dt=<seconds> [mass1=KG] [mass2=KG] [radius=M] [arm1=M] [len1=M] [arm2=M]
#          [angle1=RAD] [angle2=RAD] [omega1=RAD_S] [omega2=RAD_S] [secs=S] [gravity=0|1]
#          [solver=featherstone|mujoco|xpbd|semi|vbd] [iterations=N] [opt.NAME=VALUE] [lo1=RAD hi1=RAD] [x0=M]
#   x0      the first joint's place along the world's x, metres (default 0, the world's origin): the whole chain is
#           moved there, which changes nothing a chain with nothing acting on it does. The chain measure's angular
#           momentum is taken about the world's origin, so at an x0 other than 0 its momentum fields are not the
#           chain's; its energy and the joints' angles and speeds are
#   lo1, hi1  the first joint's limits, radians, both given or neither (default: Newton's, none within reach); passed
#           to Newton's add_joint_revolute as limit_lower and limit_upper, its own limit stiffness and damping kept
#   defaults as sdx_chain and mjc_chain: 1 kg, 1 kg, 0.05 m, 0.2 m, 0.4 m, 0.2 m, at rest and straight, 2 s, gravity on
#   solver  one of Newton's solvers that play joints; unset = featherstone. Its own defaults otherwise (the hinges carry
#           Newton's default joint settings: no damping, no armature, no friction, no limit within reach)
#   opt.<name>=<value>  one of the solver's own constructor options, passed as given (true/false, whole number or
#           number, or a word), for example opt.angular_damping=0 or opt.integrator=rk4 for the MuJoCo solver
# What is read: Featherstone and the MuJoCo solver keep the joints' angles and speeds as their state; for them each
# arm's place and motion is Newton's forward kinematics of the joints' state the step ended in (newton.eval_fk). XPBD,
# SemiImplicit and VBD keep the bodies as their state; for them the joints' angles and speeds are Newton's inverse
# kinematics of the bodies (newton.eval_ik). An arm's linear velocity is its centre of mass's, world frame, as Newton
# keeps it. Runs on the CPU.
# writes <out.txt>: a header line
#   "CHAIN dt_ns <n> mass1_g <n> mass2_g <n> radius_um <n> arm1_um <n> len1_um <n> arm2_um <n> gravity <0|1> steps <n>"
# then one line a step, 15 whole numbers:
#   <step>
#   <joint 1 angle, micro-radians> <joint 1 speed, micro-radians a second>
#   <joint 2 angle, micro-radians> <joint 2 speed, micro-radians a second>
#   <arm 1 centre x, y, micrometres> <arm 1 velocity x, y, micrometres a second> <arm 1 spin about z, micro-radians a second>
#   <arm 2 centre x, y, micrometres> <arm 2 velocity x, y, micrometres a second> <arm 2 spin about z, micro-radians a second>
# The first line after the header (step -1) is the state before any step; every line is the state a step ended in.
# prints one STATS line. If the engine's state stops being a number, the file ends at the step before and the STATS
# line says where (nan_at_step); the same if a number of the state no longer fits the format's whole numbers, 64-bit
# signed (out_of_range_at_step). Newton's 32-bit values are converted in 64-bit arithmetic. Exit 0.
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


def rotate(q, v):
    # the quaternion (x, y, z, w) applied to the vector v
    x, y, z, w = q
    u = np.array([x, y, z])
    t = 2.0 * np.cross(u, v)
    return v + w * t + np.cross(u, t)


def row(step, jq, jqd, bq, bqd, com, links):
    # Newton's 32-bit state, converted in 64-bit arithmetic: the micro-units are the exact decimal of each value
    jq, jqd, bq, bqd, com = (np.asarray(a, dtype=np.float64) for a in (jq, jqd, bq, bqd, com))
    out = [step, whole(jq[0] * 1e6), whole(jqd[0] * 1e6), whole(jq[1] * 1e6), whole(jqd[1] * 1e6)]
    for b in links:
        c = bq[b][0:3] + rotate(bq[b][3:7], com[b])  # the centre of mass in the world
        out += [whole(c[0] * 1e6), whole(c[1] * 1e6), whole(bqd[b][0] * 1e6), whole(bqd[b][1] * 1e6),
                whole(bqd[b][5] * 1e6)]
    return out


def fits(values):
    # every number of a line within the format's whole numbers (64-bit signed)
    return all(abs(v) < 2 ** 63 for v in values)


def main(argv):
    if len(argv) < 3:
        sys.stderr.write("usage: nwt_chain.py <out.txt> dt=<seconds> [mass1=] [mass2=] [radius=] [arm1=] [len1=] "
                         "[arm2=] [angle1=] [angle2=] [omega1=] [omega2=] [secs=] [gravity=0|1] [solver=NAME] "
                         "[iterations=N] [opt.NAME=VALUE] [lo1=RAD hi1=RAD] [x0=M]\n")
        return 2
    s = {"dt": 0.0, "mass1": 1.0, "mass2": 1.0, "radius": 0.05, "arm1": 0.2, "len1": 0.4, "arm2": 0.2,
         "angle1": 0.0, "angle2": 0.0, "omega1": 0.0, "omega2": 0.0, "secs": 2.0, "gravity": 1.0, "x0": 0.0}
    solver_name, iterations = "featherstone", None
    opts = {}
    lim = {}  # the first joint's limits, when given
    for a in argv[2:]:
        k, _, v = a.partition("=")
        if k in s:
            s[k] = float(v)
        elif k in ("lo1", "hi1"):
            lim[k] = float(v)
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
            sys.stderr.write("nwt_chain: unknown setting %s\n" % a)
            return 2
    dt, r = s["dt"], s["radius"]
    gravity = 1 if s["gravity"] != 0.0 else 0
    if len(lim) == 1:
        sys.stderr.write("nwt_chain: give both lo1 and hi1, or neither\n")
        return 2
    if dt <= 0.0:
        sys.stderr.write("nwt_chain: dt must be given\n")
        return 2
    wp.set_device("cpu")

    builder = newton.ModelBuilder(gravity=(0.0, -9.8 if gravity else 0.0, 0.0))  # gravity along -y, as mjc_chain
    links = []
    joints = []
    for i, (mass, at, arm) in enumerate(((s["mass1"], 0.0, s["arm1"]), (s["mass2"], s["len1"], s["arm2"]))):
        cfg = newton.ModelBuilder.ShapeConfig(density=mass / (8.0 * r * r * r))
        cfg.has_shape_collision = False
        cfg.has_particle_collision = False
        link = builder.add_link(xform=wp.transform(p=wp.vec3(s["x0"] + at, 0.0, 0.0), q=wp.quat_identity()),
                                label="arm%d" % (i + 1))
        builder.add_shape_box(link, xform=wp.transform(p=wp.vec3(arm, 0.0, 0.0), q=wp.quat_identity()), hx=r, hy=r,
                              hz=r, cfg=cfg)
        parent = -1 if i == 0 else links[0]
        limits = {} if (i > 0 or not lim) else {"limit_lower": lim["lo1"], "limit_upper": lim["hi1"]}
        joints.append(builder.add_joint_revolute(
            parent=parent, child=link, axis=(0.0, 0.0, 1.0),
            parent_xform=wp.transform(p=wp.vec3(s["x0"] if i == 0 else at, 0.0, 0.0), q=wp.quat_identity()),
            child_xform=wp.transform_identity(), label="j%d" % (i + 1), **limits))
        links.append(link)
    builder.add_articulation(joints)
    builder.joint_q[0], builder.joint_q[1] = s["angle1"], s["angle2"]
    builder.joint_qd[0], builder.joint_qd[1] = s["omega1"], s["omega2"]
    if solver_name == "vbd":
        builder.color()
    model = builder.finalize(device="cpu")
    if model.joint_dof_count != 2:
        sys.stderr.write("nwt_chain: expected two degrees of freedom, found %d\n" % model.joint_dof_count)
        return 1

    kw = {} if iterations is None else {"iterations": iterations}
    kw.update(opts)
    solvers = {"featherstone": newton.solvers.SolverFeatherstone, "mujoco": newton.solvers.SolverMuJoCo,
               "xpbd": newton.solvers.SolverXPBD, "semi": newton.solvers.SolverSemiImplicit,
               "vbd": newton.solvers.SolverVBD}
    solver = solvers[solver_name](model, **kw)
    state_0, state_1 = model.state(), model.state()
    control = model.control()
    newton.eval_fk(model, state_0.joint_q, state_0.joint_qd, state_0)  # the bodies placed from the joints' start
    com = model.body_com.numpy()

    steps = int(round(s["secs"] / dt))
    nan_at = None
    out_at = None  # the step whose state no longer fits the format's whole numbers
    with open(argv[1], "w") as f:
        f.write("CHAIN dt_ns %d mass1_g %d mass2_g %d radius_um %d arm1_um %d len1_um %d arm2_um %d gravity %d "
                "steps %d\n" % (whole(dt * 1e9), whole(s["mass1"] * 1e3), whole(s["mass2"] * 1e3), whole(r * 1e6),
                                whole(s["arm1"] * 1e6), whole(s["len1"] * 1e6), whole(s["arm2"] * 1e6), gravity,
                                steps))
        f.write(" ".join(str(x) for x in row(-1, state_0.joint_q.numpy(), state_0.joint_qd.numpy(),
                                             state_0.body_q.numpy(), state_0.body_qd.numpy(), com, links)) + "\n")
        for i in range(steps):
            state_0.clear_forces()
            solver.step(state_0, state_1, control, None, dt)
            state_0, state_1 = state_1, state_0
            if solver_name in REDUCED:
                newton.eval_fk(model, state_0.joint_q, state_0.joint_qd, state_0)
            else:
                newton.eval_ik(model, state_0, state_0.joint_q, state_0.joint_qd)
            jq, jqd = state_0.joint_q.numpy(), state_0.joint_qd.numpy()
            bq, bqd = state_0.body_q.numpy(), state_0.body_qd.numpy()
            if not (np.all(np.isfinite(jq)) and np.all(np.isfinite(jqd)) and np.all(np.isfinite(bq))
                    and np.all(np.isfinite(bqd))):
                nan_at = i
                break
            line = row(i, jq, jqd, bq, bqd, com, links)
            if not fits(line):
                out_at = i
                break
            f.write(" ".join(str(x) for x in line) + "\n")
    print("STATS chain dt %g mass1 %g mass2 %g radius %g arm1 %g len1 %g arm2 %g gravity %d dofs %d steps %d%s%s "
          "engine newton %s solver %s extra %s" % (
              dt, s["mass1"], s["mass2"], r, s["arm1"], s["len1"], s["arm2"], gravity, model.joint_dof_count, steps,
              "" if nan_at is None else " nan_at_step %d" % nan_at,
              "" if out_at is None else " out_of_range_at_step %d" % out_at, newton.__version__, solver_name,
              " ".join(([] if iterations is None else ["iterations=%d" % iterations]) +
                       ["opt.%s=%s" % (k, opts[k]) for k in opts] +
                       ([] if not lim else ["lo1=%g hi1=%g" % (lim["lo1"], lim["hi1"])]) +
                       ([] if s["x0"] == 0.0 else ["x0=%g" % s["x0"]])) or "none"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
