# nwt_rest.py: issue 27's own scenes for Newton, as its two reports wrote them (newton-physics/newton #4547 and
# #4540): one body of mass 1 kg and unit inertia (lock_inertia) at the joint, no gravity, on a revolute joint about z or
# a D6 joint with two angular axes, y and z, each driven toward its target with target_ke and no target_kd, the joint
# started at rest at its targets. Nothing acts on it, so the right answer is that it stays there. It calls Newton's own
# Python API, its only API, and does no measuring of its own; the files are the joint rig's format, so Senua AI's
# `sx_contact` (in Simplex) reads them unchanged.
# usage: python nwt_rest.py <out.txt> dt=<seconds> joint=revolute|d6 [rest=RAD] [ke=N_M_RAD] [steps=N]
#          [solver=featherstone|mujoco|xpbd|semi|vbd] [opt.NAME=VALUE]
#   joint   revolute: the angle about z, its target rest (default 7.0, #4547's); d6: the two angular axes y and z,
#           their targets 0.2 and 0.4 (#4540's)
#   ke      the drives' stiffness (default 2.0, #4547's; #4540 plays it as given)
#   steps   the steps played (default 1000; the reports play one)
#   opt.<name>=<value>  one of the solver's own constructor options, passed as given, for example
#           opt.angular_damping=0 opt.joint_attach_ke=0 opt.joint_attach_kd=0 for SemiImplicit as the reports set it,
#           or opt.use_mujoco_cpu=true
# What is read: Featherstone and the MuJoCo solver keep the joint's coordinates as their state (newton.eval_fk places
# the body); XPBD, SemiImplicit and VBD keep the body (newton.eval_ik reads the joint), as the reports do.
# writes <out.txt>: "CONTACT dt_ns <n> h0_nm 0 vx0_ums 0 mu_ppm 0 mass_g 1000 steps <n>", then one line a step,
#   "<step> <the first angular coordinate, urad> <its speed, urad/s> 0 0 0"; for d6 also <out.txt>.dof2 the same for
#   the second; and prints one STATS line (nan_at_step or out_of_range_at_step where the state stopped being a number
#   or left the format's range). Runs on the CPU. Exit 0.
import math
import sys

import numpy as np
import warp as wp

import newton


def whole(x):
    return int(math.floor(x + 0.5)) if x >= 0.0 else -int(math.floor(-x + 0.5))


def main(argv):
    if len(argv) < 3:
        sys.stderr.write("usage: nwt_rest.py <out.txt> dt=<seconds> joint=revolute|d6 [rest=] [ke=] [steps=] "
                         "[solver=NAME] [opt.NAME=VALUE]\n")
        return 2
    dt, joint_kind, rest, ke, steps, solver_name = 0.0, "revolute", 7.0, 2.0, 1000, "featherstone"
    opts = {}
    for a in argv[2:]:
        k, _, v = a.partition("=")
        if k == "dt":
            dt = float(v)
        elif k == "joint" and v in ("revolute", "d6"):
            joint_kind = v
        elif k == "rest":
            rest = float(v)
        elif k == "ke":
            ke = float(v)
        elif k == "steps":
            steps = int(v)
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
            sys.stderr.write("nwt_rest: unknown setting %s\n" % a)
            return 2
    if dt <= 0.0:
        sys.stderr.write("nwt_rest: dt must be given\n")
        return 2
    wp.set_device("cpu")
    builder = newton.ModelBuilder(gravity=(0.0, 0.0, 0.0))
    body = builder.add_link(mass=1.0, inertia=wp.mat33(np.eye(3)), lock_inertia=True)
    if joint_kind == "revolute":
        joint = builder.add_joint_revolute(-1, body, axis=newton.Axis.Z, target_pos=rest, target_ke=ke, target_kd=0.0)
        targets = [rest]
    else:
        joint = builder.add_joint_d6(-1, body, angular_axes=[
            newton.ModelBuilder.JointDofConfig(axis=newton.Axis.Y, target_pos=0.2, target_ke=ke),
            newton.ModelBuilder.JointDofConfig(axis=newton.Axis.Z, target_pos=0.4, target_ke=ke)])
        targets = [0.2, 0.4]
    builder.add_articulation([joint])
    q0 = builder.joint_q_start[joint]
    for i, t in enumerate(targets):
        builder.joint_q[q0 + i] = t
    if solver_name == "vbd":
        builder.color()
    model = builder.finalize(device="cpu")
    solvers = {"featherstone": newton.solvers.SolverFeatherstone, "mujoco": newton.solvers.SolverMuJoCo,
               "xpbd": newton.solvers.SolverXPBD, "semi": newton.solvers.SolverSemiImplicit,
               "vbd": newton.solvers.SolverVBD}
    solver = solvers[solver_name](model, **opts)
    state_0, state_1 = model.state(), model.state()
    control = model.control()
    newton.eval_fk(model, model.joint_q, model.joint_qd, state_0)  # as the reports place the body
    reduced = solver_name in ("featherstone", "mujoco")
    files = [open(argv[1], "w")] + ([open(argv[1] + ".dof2", "w")] if joint_kind == "d6" else [])
    for f in files:
        f.write("CONTACT dt_ns %d h0_nm 0 vx0_ums 0 mu_ppm 0 mass_g 1000 steps %d\n" % (whole(dt * 1e9), steps))
    nan_at = out_at = None
    for i in range(steps):
        state_0.clear_forces()
        solver.step(state_0, state_1, control, None, dt)
        state_0, state_1 = state_1, state_0
        if reduced:
            newton.eval_fk(model, state_0.joint_q, state_0.joint_qd, state_0)
        else:
            newton.eval_ik(model, state_0, state_0.joint_q, state_0.joint_qd)
        jq = np.asarray(state_0.joint_q.numpy(), dtype=np.float64)
        jqd = np.asarray(state_0.joint_qd.numpy(), dtype=np.float64)
        rows = []
        for k in range(len(targets)):
            if not (np.isfinite(jq[q0 + k]) and np.isfinite(jqd[q0 + k])):
                nan_at = i
            rows.append([i, whole(jq[q0 + k] * 1e6), whole(jqd[q0 + k] * 1e6), 0, 0, 0] if nan_at is None else None)
        if nan_at is not None:
            break
        if not all(abs(v) < 2 ** 63 for r in rows for v in r):
            out_at = i
            break
        for f, r in zip(files, rows):
            f.write(" ".join(str(x) for x in r) + "\n")
    for f in files:
        f.close()
    print("STATS rest dt %g joint %s rest %g ke %g steps %d%s%s engine newton %s solver %s extra %s" % (
        dt, joint_kind, rest, ke, steps, "" if nan_at is None else " nan_at_step %d" % nan_at,
        "" if out_at is None else " out_of_range_at_step %d" % out_at, newton.__version__, solver_name,
        " ".join("opt.%s=%s" % (k, opts[k]) for k in opts) or "none"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
