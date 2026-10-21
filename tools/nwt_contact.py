# nwt_contact.py: the one-cube rig for Newton, the adapter between Senua AI and the engine under test. It only plays
# one cube on a plane and writes what happened, in exactly the format of the first deep dive's sdx_contact rig, so the
# same measuring programs (Senua AI's, in Simplex) read Newton's runs unchanged. It calls Newton's own Python API, its
# only API, and does no measuring of its own. Newton is z-up; the record's columns are the same quantities.
# usage: python nwt_contact.py <out.txt> dt=<seconds> [h0=M] [vx0=V] [mu=X] [mass=KG] [radius=M] [secs=S] [push=N]
#          [pushat=S] [lift=N] [liftat=S] [kick=V] [kickat=S] [solver=xpbd|featherstone|semi|mujoco|vbd|vbd_alm]
#          [iterations=N] [opt.NAME=VALUE] [gravity=0|1] [comx=M] [wz0=RAD_S] [groundmu=X] [register=1]
#          [prio=N] [groundprio=N] [slab=M] [vz0=V] [specgap=M] [matching=WORD] [mus=X] [groundmus=X] [usd=1]
#   h0      the gap between the cube's lowest face and the plane at the start (default 0.05 m)
#   radius  the cube's half-size (default 0.05 m); mass in kg (default 1), given through the shape's density
#   hz      the box's half-height, for a flat plate that cannot tip (default: radius, a cube); the height column is
#           then the lowest face's, from this half-height
#   push    a force along x from pushat on; lift a force up from liftat on (newtons), applied at the centre of mass
#   kick    the cube's speed along x set to this (m/s) at the first step from kickat on (seconds; 0 = no kick), so a
#           cube can settle on the ground before it is set sliding
#   solver  one of Newton's solvers; unset = xpbd. Its own defaults otherwise; iterations where the solver takes them.
#           vbd_alm is VBD with rigid_compliant_alm=True, the contact path Newton 1.6 says will become VBD's default
#   gravity 1 (the default) for 9.8 m/s2 down, 0 for none; the contact force column takes the gravity played
#   comx    the box placed this far along the body's x from the body's origin (default 0), so the centre of mass is
#           there and not at the origin; the columns stay the origin's height and the centre of mass's velocity
#   wz0     the body's spin about the world's z at the start (rad/s; default 0), about its centre of mass, which
#           starts at rest (Newton 1.6's free-joint velocity is the centre of mass's, with the spin, world frame)
#   groundmu  the plane's friction coefficient, apart from the cube's mu (unset: the plane takes mu, as every earlier
#           play)
#   mus, groundmus  the cube's and the plane's static friction coefficient (ShapeConfig.mu_static, pull request #4306;
#           a Newton without it does not take them); unset: none, as every earlier play
#   usd     1: the cube and its friction come from a UsdPhysics stage (made in memory with Pixar's usd-core, a
#           rigid body cube of the same size and mass, its physics material's dynamicFriction mu and, when mus is
#           given, its staticFriction mus), through Newton's own importer (ModelBuilder.add_usd); the plane as
#           always. The stats line then carries the cube shape's friction as imported (shape_mu, shape_mu_static)
#   register  1: the MuJoCo solver's custom attributes registered on the builder (SolverMuJoCo.register_custom_
#           attributes), so the shapes carry its geom priority; prio and groundprio the cube's and the plane's
#           priority (mujoco:geom_priority), set on the model before the solver is built
#   slab    the ground a static box this thick (metres), its top at the plane's height, 20 m wide, in place of the
#           plane (unset: the plane); vz0 the cube's starting speed along z (m/s, default 0)
#   specgap the collision pipeline's speculative contacts on, CollisionPipeline(speculative_contact_gap_max=...)
#           (metres; unset: off, Newton's default)
#   matching the collision pipeline's contact matching, CollisionPipeline(contact_matching=...), latest or sticky
#           (unset: Newton's default); with VBD's opt.rigid_contact_history=true it carries each contact's state
#           from one step to the next
#   opt.<name>=<value>  one of the solver's own constructor options, passed as given (true/false, whole number or
#           number, or a word), for example opt.friction_smoothing=0.01 for SemiImplicit or Featherstone, or
#           opt.cone=elliptic for the MuJoCo solver
# The cube is a free body: Newton has no one-call locked translation, so unlike sdx_contact's default it may turn.
# The contact force on the cube is its impulse over the step: mass x (velocity change) / dt, less the push, the lift
# and the weight. For one body on a plane that is the whole contact force, whatever solver made it.
# gravity is 9.8 m/s2, as in the first deep dive's known-answer suite. Runs on the CPU.
# writes <out.txt>: a header line "CONTACT dt_ns <n> h0_nm <n> vx0_ums <n> mu_ppm <n> mass_g <n> steps <n>", then one
#   line a step: "<step> <height of the lowest face, nm> <vx, um/s> <vz, um/s> <contact force up, mN> <contact
#   force along x, mN>"
# prints one STATS line, with the largest turn of the cube from its start (most_tilt_urad): the height column is the
#   centre's height less the half-size, which is the lowest face's only while the cube stays level. If the engine's
#   state stops being a number, the file ends at the step before and the STATS line says where (nan_at_step). Exit 0.
# Checked on its first plays (run 001): a cube set down pushes exactly its weight, 9,800 mN, on every solver.
import math
import sys

import warp as wp

wp.config.log_level = wp.LOG_WARNING  # Warp's start-up and kernel-load messages, which go to the output, off

import newton  # noqa: E402


def main(argv):
    if len(argv) < 3:
        sys.stderr.write("usage: nwt_contact.py <out.txt> dt=<seconds> [h0=M] [vx0=V] [mu=X] [mass=KG] [radius=M] "
                         "[secs=S] [push=N] [pushat=S] [lift=N] [liftat=S] [kick=V] [kickat=S] [solver=NAME] "
                         "[iterations=N] "
                         "[opt.NAME=VALUE] [gravity=0|1] [comx=M] [wz0=RAD_S] [groundmu=X] [register=1] [prio=N] "
                         "[groundprio=N] [slab=M] [vz0=V] [specgap=M] [matching=WORD]\n")
        return 2
    s = {"dt": 0.0, "h0": 0.05, "vx0": 0.0, "mu": 0.0, "mass": 1.0, "radius": 0.05, "hz": 0.0, "secs": 1.0, "push": 0.0,
         "pushat": 0.0, "lift": 0.0, "liftat": 0.3, "kick": 0.0, "kickat": 0.0, "gravity": 1.0, "comx": 0.0,
         "wz0": 0.0}
    solver_name, iterations = "xpbd", None
    opts = {}  # opt.<name>=<value>: one of the solver's own options, passed to its constructor as given
    fr = {}  # groundmu, register, prio, groundprio, when given
    matching = None  # matching=<word>: the collision pipeline's contact matching, when given
    for a in argv[2:]:
        k, _, v = a.partition("=")
        if k in s:
            s[k] = float(v)
        elif k in ("groundmu", "register", "prio", "groundprio", "slab", "vz0", "specgap", "mus", "groundmus", "usd"):
            fr[k] = float(v)
        elif k == "matching":
            matching = v
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
                        opts[k[4:]] = v  # a word, such as the MuJoCo solver's cone=elliptic
        else:
            sys.stderr.write("nwt_contact: unknown setting %s\n" % a)
            return 2
    dt, r, m = s["dt"], s["radius"], s["mass"]
    hz = s["hz"] if s["hz"] > 0.0 else r  # the half-height: a cube unless a plate is asked for
    if dt <= 0.0:
        sys.stderr.write("nwt_contact: dt must be given\n")
        return 2
    wp.set_device("cpu")

    builder = newton.ModelBuilder(gravity=(0.0, 0.0, -9.8 if s["gravity"] == 1.0 else -9.8 * s["gravity"]))  # z-up
    if fr.get("register", 0.0) == 1.0:
        newton.solvers.SolverMuJoCo.register_custom_attributes(builder)
    builder.default_shape_cfg.mu = fr["groundmu"] if "groundmu" in fr else s["mu"]
    if "groundmus" in fr:  # a static coefficient (pull request #4306's mu_static): only when given
        builder.default_shape_cfg.mu_static = fr["groundmus"]
    builder.default_shape_cfg.density = m / (8.0 * r * r * hz)
    if "slab" in fr:  # a static slab, its top at z = 0, in place of the plane
        builder.add_shape_box(-1, xform=wp.transform(p=wp.vec3(0.0, 0.0, -0.5 * fr["slab"]), q=wp.quat_identity()),
                              hx=10.0, hy=10.0, hz=0.5 * fr["slab"])
    else:
        builder.add_ground_plane()
    builder.default_shape_cfg.mu = s["mu"]
    if "mus" in fr or "groundmus" in fr:
        builder.default_shape_cfg.mu_static = fr.get("mus", None)
    if fr.get("usd", 0.0) == 1.0:  # the cube and its material from a UsdPhysics stage, through Newton's importer
        from pxr import Gf, Usd, UsdGeom, UsdPhysics, UsdShade

        stage = Usd.Stage.CreateInMemory()
        UsdGeom.SetStageUpAxis(stage, UsdGeom.Tokens.z)
        UsdGeom.SetStageMetersPerUnit(stage, 1.0)
        scene = UsdPhysics.Scene.Define(stage, "/physicsScene")  # the rig's gravity, not USD's default (9.81)
        scene.CreateGravityDirectionAttr(Gf.Vec3f(0.0, 0.0, -1.0))
        scene.CreateGravityMagnitudeAttr(9.8 if s["gravity"] == 1.0 else 9.8 * s["gravity"])
        mat = UsdShade.Material.Define(stage, "/cubeMaterial")
        mapi = UsdPhysics.MaterialAPI.Apply(mat.GetPrim())
        mapi.CreateDynamicFrictionAttr(s["mu"])
        if "mus" in fr:
            mapi.CreateStaticFrictionAttr(fr["mus"])
        mapi.CreateRestitutionAttr(0.0)
        ucube = UsdGeom.Cube.Define(stage, "/cube")
        ucube.CreateSizeAttr(2.0 * r)
        ucube.AddTranslateOp().Set(Gf.Vec3d(0.0, 0.0, hz + s["h0"]))
        UsdPhysics.RigidBodyAPI.Apply(ucube.GetPrim())
        UsdPhysics.CollisionAPI.Apply(ucube.GetPrim())
        UsdPhysics.MassAPI.Apply(ucube.GetPrim()).CreateMassAttr(m)
        UsdShade.MaterialBindingAPI.Apply(ucube.GetPrim()).Bind(mat, UsdShade.Tokens.weakerThanDescendants, "physics")
        builder.add_usd(stage)
        cube = builder.body_count - 1
    else:
        cube = builder.add_body(xform=wp.transform(p=wp.vec3(0.0, 0.0, hz + s["h0"]), q=wp.quat_identity()), label="cube")
        if s["comx"] == 0.0:
            builder.add_shape_box(cube, hx=r, hy=r, hz=hz)
        else:  # the box, and so the centre of mass, off the body's origin along its x
            builder.add_shape_box(cube, xform=wp.transform(p=wp.vec3(s["comx"], 0.0, 0.0), q=wp.quat_identity()),
                                  hx=r, hy=r, hz=hz)
    # the starting velocity, set where every solver reads it: on the body, and on the free joint add_body made for it
    # (Featherstone and the MuJoCo solver work in joint coordinates; a free joint's velocity is (linear, angular), world
    # frame, as on the body, the layout Newton's own examples use)
    vz0 = fr.get("vz0", 0.0)
    builder.body_qd[cube] = wp.spatial_vector(s["vx0"], 0.0, vz0, 0.0, 0.0, s["wz0"])
    builder.joint_qd[builder.joint_qd_start[builder.joint_count - 1]] = s["vx0"]
    if vz0 != 0.0:
        builder.joint_qd[builder.joint_qd_start[builder.joint_count - 1] + 2] = vz0
    if s["wz0"] != 0.0:
        builder.joint_qd[builder.joint_qd_start[builder.joint_count - 1] + 5] = s["wz0"]
    if solver_name.startswith("vbd"):
        builder.color()
    model = builder.finalize(device="cpu")
    imported = ""
    if fr.get("usd", 0.0) == 1.0:  # the cube's box shape is the last shape
        smus = model.shape_material_mu_static.numpy()[-1] if hasattr(model, "shape_material_mu_static") else None
        imported = " shape_mu %g shape_mu_static %s" % (model.shape_material_mu.numpy()[-1],
                                                       "none" if smus is None else "%g" % smus)
    if "prio" in fr or "groundprio" in fr:  # the plane is shape 0, the cube's box shape 1
        pr = model.mujoco.geom_priority.numpy()
        pr[0], pr[1] = int(fr.get("groundprio", 0.0)), int(fr.get("prio", 0.0))
        model.mujoco.geom_priority.assign(pr)

    kw = {} if iterations is None else {"iterations": iterations}
    kw.update(opts)
    solvers = {"xpbd": newton.solvers.SolverXPBD, "featherstone": newton.solvers.SolverFeatherstone,
               "semi": newton.solvers.SolverSemiImplicit, "mujoco": newton.solvers.SolverMuJoCo,
               "vbd": newton.solvers.SolverVBD,
               "vbd_alm": lambda mdl, **k: newton.solvers.SolverVBD(mdl, rigid_compliant_alm=True, **k)}
    solver = solvers[solver_name](model, **kw)
    state_0, state_1 = model.state(), model.state()
    control = model.control()
    pk = {} if matching is None else {"contact_matching": matching}
    pipeline = (newton.CollisionPipeline(model, **pk) if "specgap" not in fr else
                newton.CollisionPipeline(model, speculative_contact_gap_max=fr["specgap"], **pk))
    contacts = pipeline.contacts()

    steps = int(round(s["secs"] / dt))
    g = 9.8 if s["gravity"] == 1.0 else 9.8 * s["gravity"]  # the gravity played, for the contact force column
    most_tilt = 0.0  # the largest turn of the cube from its start, radians: the height column assumes it stays level
    nan_at = None
    with open(argv[1], "w") as f:
        f.write("CONTACT dt_ns %d h0_nm %d vx0_ums %d mu_ppm %d mass_g %d steps %d\n" % (
            round(dt * 1e9), round(s["h0"] * 1e9), round(s["vx0"] * 1e6), round(s["mu"] * 1e6), round(m * 1e3), steps))
        kicked = False
        for i in range(steps):
            tmid = (i + 0.5) * dt
            fx = s["push"] if (s["push"] != 0.0 and (s["pushat"] <= 0.0 or tmid >= s["pushat"])) else 0.0
            fz = s["lift"] if (s["lift"] != 0.0 and tmid >= s["liftat"]) else 0.0
            if s["kickat"] > 0.0 and not kicked and tmid >= s["kickat"]:
                # the kick: the cube's speed along x set to `kick`, on the body and on its free joint, before the step
                kicked = True
                qd = state_0.body_qd.numpy()
                qd[cube][0] = s["kick"]
                state_0.body_qd.assign(qd)
                jqd = state_0.joint_qd.numpy()
                jqd[model.joint_qd_start.numpy()[model.joint_count - 1]] = s["kick"]
                state_0.joint_qd.assign(jqd)
            v_before = state_0.body_qd.numpy()[cube][0:3].copy()
            state_0.clear_forces()
            bf = state_0.body_f.numpy()
            bf[cube][0], bf[cube][2] = fx, fz
            state_0.body_f.assign(bf)
            if "specgap" in fr:  # speculative contacts sweep the shapes over the step
                pipeline.collide(state_0, contacts, dt=dt)
            else:
                pipeline.collide(state_0, contacts)
            solver.step(state_0, state_1, control, contacts, dt)
            state_0, state_1 = state_1, state_0
            q = state_0.body_q.numpy()[cube]
            v = state_0.body_qd.numpy()[cube][0:3]
            # the contact force: the impulse over the step, less the applied forces and the weight
            cx = m * (v[0] - v_before[0]) / dt - fx
            cz = m * (v[2] - v_before[2]) / dt - fz + m * g
            if not all(math.isfinite(float(x)) for x in list(q) + [v[0], v[2], cz, cx]):
                nan_at = i
                break
            most_tilt = max(most_tilt, 2.0 * math.acos(min(1.0, abs(float(q[6])))))  # q[3:7] is the quaternion, w last
            f.write("%d %d %d %d %d %d\n" % (i, round((q[2] - hz) * 1e9), round(v[0] * 1e6), round(v[2] * 1e6),
                                               round(cz * 1e3), round(cx * 1e3)))
    print("STATS contact dt %g h0 %g vx0 %g mu %g mass %g radius %g steps %d most_tilt_urad %d%s engine newton %s "
          "solver %s%s extra %s" % (dt, s["h0"], s["vx0"], s["mu"], m, r, steps, round(most_tilt * 1e6),
                                  "" if nan_at is None else " nan_at_step %d" % nan_at, newton.__version__, solver_name, imported,
                                  " ".join(([] if iterations is None else ["iterations=%d" % iterations]) +
                                           ["opt.%s=%s" % (k, opts[k]) for k in opts] +
                                           ([] if s["kickat"] <= 0.0 else
                                            ["kick=%g kickat=%g" % (s["kick"], s["kickat"])]) +
                                           ([] if s["hz"] <= 0.0 else ["hz=%g" % s["hz"]]) +
                                           ([] if s["gravity"] == 1.0 else ["gravity=%g" % s["gravity"]]) +
                                           ([] if s["comx"] == 0.0 else ["comx=%g" % s["comx"]]) +
                                           ([] if s["wz0"] == 0.0 else ["wz0=%g" % s["wz0"]]) +
                                           ["%s=%g" % (k, fr[k]) for k in ("groundmu", "register", "prio", "groundprio", "mus", "groundmus",
                                                                          "slab", "vz0", "specgap", "usd")
                                            if k in fr] +
                                           ([] if matching is None else ["matching=%s" % matching])) or "none"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
