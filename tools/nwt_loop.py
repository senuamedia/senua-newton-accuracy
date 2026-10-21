# nwt_loop.py: issue 19's loop-closing joint for Newton (newton-physics/newton #2428): one arm (the joint rig's: a cube
# of half-size `radius`, its centre `arm` metres along +x, mass through the cube's density), no gravity, on two
# revolute joints about +z at the world's origin: joint A in the articulation and free, joint B coaxial with it and
# left out of the articulation (a loop-closing joint), carrying a limit or a drive. The two hinges agree, so the arm
# turns about z either way; what it does past B's limit or under B's drive is B's features being applied or not.
# It calls Newton's own Python API, its only API, and does no measuring of its own; the file is the joint rig's format,
# so Senua AI's `sx_contact` (in Simplex) reads it unchanged.
# usage: python nwt_loop.py <out.txt> dt=<seconds> [mass=KG] [radius=M] [arm=M] [omega0=RAD_S] [secs=S]
#          [lo=RAD hi=RAD] [drivek=N_M_RAD drived=N_M_S_RAD target=RAD] [noloop=1] [solver=NAME] [opt.NAME=VALUE]
#   lo, hi  joint B's limits (Newton's default limit stiffness and damping); drivek, drived, target joint B's drive
#   noloop  1: joint B not added (the single free hinge, the control)
#   defaults: 1 kg, 0.05 m, 0.5 m, at rest, 2 s
# What is read: joint A's angle and speed, Newton's forward kinematics of the state for Featherstone and the MuJoCo
# solver, its inverse kinematics for XPBD, SemiImplicit and VBD (as the joint rig). Runs on the CPU.
# writes <out.txt>: "CONTACT dt_ns <n> h0_nm 0 vx0_ums 0 mu_ppm 0 mass_g <n> steps <n>", then one line a step,
#   "<step> <joint A's angle, urad> <its speed, urad/s> 0 0 0"; prints one STATS line (nan_at_step where the state
#   stopped being a number). Exit 0.
import math
import sys

import numpy as np
import warp as wp

import newton


def whole(x):
    return int(math.floor(x + 0.5)) if x >= 0.0 else -int(math.floor(-x + 0.5))


def main(argv):
    if len(argv) < 3:
        sys.stderr.write("usage: nwt_loop.py <out.txt> dt=<seconds> [mass=] [radius=] [arm=] [omega0=] [secs=] [lo= hi=] "
                         "[drivek= drived= target=] [noloop=1] [solver=NAME] [opt.NAME=VALUE]\n")
        return 2
    s = {"dt": 0.0, "mass": 1.0, "radius": 0.05, "arm": 0.5, "omega0": 0.0, "secs": 2.0, "noloop": 0.0}
    b = {}  # lo, hi, drivek, drived, target: joint B's
    solver_name = "featherstone"
    opts = {}
    for a in argv[2:]:
        k, _, v = a.partition("=")
        if k in s:
            s[k] = float(v)
        elif k in ("lo", "hi", "drivek", "drived", "target"):
            b[k] = float(v)
        elif k == "solver":
            solver_name = v
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
            sys.stderr.write("nwt_loop: unknown setting %s\n" % a)
            return 2
    dt, r, m = s["dt"], s["radius"], s["mass"]
    if dt <= 0.0:
        sys.stderr.write("nwt_loop: dt must be given\n")
        return 2
    wp.set_device("cpu")
    builder = newton.ModelBuilder(gravity=(0.0, 0.0, 0.0))
    cfg = newton.ModelBuilder.ShapeConfig(density=m / (8.0 * r * r * r))
    cfg.has_shape_collision = False
    cfg.has_particle_collision = False
    link = builder.add_link(xform=wp.transform_identity(), label="arm")
    builder.add_shape_box(link, xform=wp.transform(p=wp.vec3(s["arm"], 0.0, 0.0), q=wp.quat_identity()), hx=r, hy=r,
                          hz=r, cfg=cfg)
    ja = builder.add_joint_revolute(parent=-1, child=link, axis=(0.0, 0.0, 1.0), parent_xform=wp.transform_identity(),
                                    child_xform=wp.transform_identity(), label="a")
    builder.add_articulation([ja])
    if s["noloop"] != 1.0:
        kw = {}
        if "lo" in b and "hi" in b:
            kw.update({"limit_lower": b["lo"], "limit_upper": b["hi"]})
        if "drivek" in b or "drived" in b or "target" in b:
            kw.update({"target_ke": b.get("drivek", 0.0), "target_kd": b.get("drived", 0.0),
                       "target_pos": b.get("target", 0.0)})
        builder.add_joint_revolute(parent=-1, child=link, axis=(0.0, 0.0, 1.0), parent_xform=wp.transform_identity(),
                                   child_xform=wp.transform_identity(), label="b", **kw)  # not in the articulation
    builder.joint_qd[builder.joint_qd_start[ja]] = s["omega0"]
    if solver_name == "vbd":
        builder.color()
    model = builder.finalize(device="cpu")
    solvers = {"featherstone": newton.solvers.SolverFeatherstone, "mujoco": newton.solvers.SolverMuJoCo,
               "xpbd": newton.solvers.SolverXPBD, "semi": newton.solvers.SolverSemiImplicit,
               "vbd": newton.solvers.SolverVBD}
    solver = solvers[solver_name](model, **opts)
    state_0, state_1 = model.state(), model.state()
    control = model.control()
    newton.eval_fk(model, state_0.joint_q, state_0.joint_qd, state_0)
    reduced = solver_name in ("featherstone", "mujoco")
    qa = builder.joint_q_start[ja]
    steps = int(round(s["secs"] / dt))
    nan_at = None
    with open(argv[1], "w") as f:
        f.write("CONTACT dt_ns %d h0_nm 0 vx0_ums 0 mu_ppm 0 mass_g %d steps %d\n" % (whole(dt * 1e9), whole(m * 1e3),
                                                                                       steps))
        for i in range(steps):
            state_0.clear_forces()
            solver.step(state_0, state_1, control, None, dt)
            state_0, state_1 = state_1, state_0
            if reduced:
                newton.eval_fk(model, state_0.joint_q, state_0.joint_qd, state_0)
            else:
                newton.eval_ik(model, state_0, state_0.joint_q, state_0.joint_qd)
            jq = float(state_0.joint_q.numpy()[qa])
            jqd = float(state_0.joint_qd.numpy()[builder.joint_qd_start[ja]])
            if not (math.isfinite(jq) and math.isfinite(jqd)):
                nan_at = i
                break
            f.write("%d %d %d 0 0 0\n" % (i, whole(jq * 1e6), whole(jqd * 1e6)))
    print("STATS loop dt %g mass %g radius %g arm %g steps %d%s engine newton %s solver %s extra %s" % (
        dt, m, r, s["arm"], steps, "" if nan_at is None else " nan_at_step %d" % nan_at, newton.__version__,
        solver_name, " ".join(["noloop"] * (s["noloop"] == 1.0) + ["%s=%g" % (k, b[k]) for k in sorted(b)] +
                              ["opt.%s=%s" % (k, opts[k]) for k in opts]) or "none"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
