# nwt_cloth_proxy.py: issue 21's coupled cloth (newton-physics/newton #4698) for Newton: a box played by the MuJoCo solver
# on its CPU path and a light VBD cloth, the two coupled two-way through SolverCoupledProxy with the box a lagged proxy in
# VBD, as #4698's reproduction sets it. It calls Newton's own Python API, its only API, and does no measuring of its
# own: a one-method subclass of SolverVBD records the wrench VBD harvests for the box at each coupled step, beside the
# box's state and the force the cloth receives, its momentum change over the step plus its weight.
# Three scenes (scene=):
#   rest     (default, #4698's) a box resting on the ground, the cloth dropped onto it from 5 cm above its top. Right
#            answers: the wrench fed back to the box is the force the cloth exerts on it, at rest the weight of what of
#            the cloth it carries (all of it when the box is tall enough that the cloth touches nothing else); the box,
#            held by the ground, cannot move faster than the cloth's landing can push it, 2 M_cloth v_land / M_box
#   hammock  the cloth 0.3 m above the ground, held along its two x edges (add_cloth_grid's fix_left and fix_right),
#            the box dropped onto it from 3 cm above. Right answer: the box comes to rest on the cloth, and the wrench
#            fed back to it at rest is its weight, upward
#   throw    no gravity and no ground: the box at rest, the cloth sent at it at cloth_vz from 5 cm above its top. Right
#            answer: nothing outside acts on the two, so their momentum stays what it was
# usage: python nwt_cloth_proxy.py <out.txt> [scene=rest|hammock|throw] [coupled_dt=S] [secs=S] [cloth_mass=KG]
#          [box_mass=KG] [box_hx=M] [box_hz=M] [cloth_vz=V] [iterations=N] [feedback=1|0] [box=<file>] [cloth=<file>]
#          [opt.NAME=VALUE]
#   feedback  1 (default): two-way; 0: the harvested wrench recorded and then zeroed before it reaches the box (one-way)
#   box_hx, box_hz  the box's half-sizes, across and up (default 0.1 and 0.025 m, #4698's 0.2 x 0.2 x 0.05 m box)
#   box_mass  added to the mass the box's shape has at Newton's default density, 1000 kg/m^3, as #4698's script builds
#           it: #4698's box is 2.5 kg, 0.5 added to the shape's 2.0 (the CONTACT file's mass_g is the body's whole mass)
#   box=<file>, cloth=<file>  also write the box, and the cloth, as the CONTACT files Senua AI's measure reads for a cube
#           (header "CONTACT dt_ns <n> h0_nm <n> vx0_ums <n> mu_ppm 0 mass_g <n> steps <n>", then a line a coupled step:
#           <step> <height, nm> <velocity up, um/s> 0 <force up, mN> 0): the box's centre, its velocity up and the
#           wrench harvested for it, up; the cloth's centre of mass, its velocity up and the force it receives, up
#           (h0 and vx0 the starting height and velocity up, mass_g the mass, whole grams, the cloth's without its held
#           particles)
#   opt.<name>=<value>  one of SolverVBD's own constructor options
#   defaults as #4698: a 4 ms coupled step of two 2 ms substeps on each side, 0.6 s, a 45 g cloth of 21 x 21 vertices
#           0.3 m square, box_mass 0.5 kg (a 2.5 kg box), 10 VBD iterations
# writes <out.txt>: a header line "CLOTH coupled_dt_ns <n> cloth_mass_g <n> box_mass_g <n> steps <n> feedback <0|1>",
#   then one line a coupled step, whole numbers: <step> <harvested wrench on the box, z, mN> <force the cloth receives,
#   z, mN> <box height, um> <box speed, um/s>. prints one STATS line. Exit 0.
import math
import sys

import numpy as np
import warp as wp

wp.config.log_level = wp.LOG_WARNING

import newton  # noqa: E402
from newton.solvers import SolverMuJoCo, SolverVBD  # noqa: E402
from newton.solvers.experimental.coupled import SolverCoupledProxy  # noqa: E402


def whole(x):
    return int(math.floor(x + 0.5)) if x >= 0.0 else -int(math.floor(-x + 0.5))


class RecordingVBD(SolverVBD):
    """SolverVBD that records the box's harvested wrench, and zeroes it when the run is one-way."""

    feedback = True
    harvested = None

    def coupling_harvest_proxy_wrenches(self, body_local_to_proxy_global, out_body_f, **kw):
        super().coupling_harvest_proxy_wrenches(body_local_to_proxy_global, out_body_f, **kw)
        f = out_body_f.numpy()
        RecordingVBD.harvested = np.array(f[0], dtype=np.float64)
        if not RecordingVBD.feedback:
            out_body_f.zero_()


def main(argv):
    if len(argv) < 2:
        sys.stderr.write("usage: nwt_cloth_proxy.py <out.txt> [scene=] [coupled_dt=] [secs=] [cloth_mass=] [box_mass=] "
                         "[box_hx=] [box_hz=] [cloth_vz=] [iterations=] [feedback=1|0] [box=] [cloth=] "
                         "[opt.NAME=VALUE]\n")
        return 2
    s = {"coupled_dt": 0.004, "secs": 0.6, "cloth_mass": 0.045, "box_mass": 0.5, "iterations": 10.0, "feedback": 1.0,
         "box_hx": 0.1, "box_hz": 0.025, "cloth_vz": 0.0}
    words = {"scene": "rest", "box": "", "cloth": ""}
    opts = {}
    for a in argv[2:]:
        k, _, v = a.partition("=")
        if k in s:
            s[k] = float(v)
        elif k in words:
            words[k] = v
        elif k.startswith("opt.") and len(k) > 4:
            opts[k[4:]] = {"true": True, "false": False}.get(v.lower(), None)
            if opts[k[4:]] is None:
                try:
                    opts[k[4:]] = int(v)
                except ValueError:
                    opts[k[4:]] = float(v)
        else:
            sys.stderr.write("nwt_cloth_proxy: unknown setting %s\n" % a)
            return 2
    scene = words["scene"]
    if scene not in ("rest", "hammock", "throw"):
        sys.stderr.write("nwt_cloth_proxy: unknown scene %s\n" % scene)
        return 2
    wp.set_device("cpu")
    RecordingVBD.feedback = s["feedback"] != 0.0
    dt = s["coupled_dt"]
    hx, hz = s["box_hx"], s["box_hz"]

    builder = newton.ModelBuilder(gravity=(0.0, 0.0, 0.0)) if scene == "throw" else newton.ModelBuilder()
    SolverMuJoCo.register_custom_attributes(builder)
    if scene != "throw":
        builder.add_ground_plane()
    if scene == "hammock":
        cloth_z, box_z = 0.3, 0.3 + 0.03 + hz
    else:
        cloth_z, box_z = 2.0 * hz + 0.05, hz
    box = builder.add_body(xform=wp.transform(p=wp.vec3(0.0, 0.0, box_z), q=wp.quat_identity()), mass=s["box_mass"])
    builder.add_shape_box(box, hx=hx, hy=hx, hz=hz)
    n = 21
    cell = 0.3 / (n - 1)
    particle_start = builder.particle_count
    held = scene == "hammock"
    builder.add_cloth_grid(pos=wp.vec3(-0.15, -0.15, cloth_z), rot=wp.quat_identity(), vel=wp.vec3(0.0, 0.0, s["cloth_vz"]),
                           dim_x=n - 1, dim_y=n - 1, cell_x=cell, cell_y=cell, mass=s["cloth_mass"] / (n * n),
                           fix_left=held, fix_right=held, tri_ke=5494.5, tri_ka=5494.5, edge_ke=4.58e-4,
                           particle_radius=0.0005)
    particle_end = builder.particle_count
    builder.color()
    model = builder.finalize(device="cpu")
    model.soft_contact_ke = 1.0e4
    model.soft_contact_kd = 0.0
    model.soft_contact_mu = 0.5

    vbd_kwargs = {"iterations": int(s["iterations"]), "rigid_compliant_alm": True,
                  "rigid_body_particle_contact_buffer_size": 1100}
    vbd_kwargs.update(opts)
    solver = SolverCoupledProxy(
        model=model,
        entries=[
            SolverCoupledProxy.Entry(name="mujoco", solver=lambda v: SolverMuJoCo(model=v, use_mujoco_cpu=True,
                                                                                  use_mujoco_contacts=True),
                                     bodies=[box], joints=list(range(model.joint_count)), substeps=2),
            SolverCoupledProxy.Entry(name="vbd", solver=lambda v: RecordingVBD(model=v, **vbd_kwargs), bodies=[],
                                     particles=list(range(particle_start, particle_end)), substeps=2),
        ],
        coupling=SolverCoupledProxy.Config(proxies=[SolverCoupledProxy.Proxy(
            source="mujoco", destination="vbd", bodies=[box], mode="lagged",
            collision_pipeline=lambda v: newton.CollisionPipeline(v, broad_phase="nxn", soft_contact_gap=0.01))]),
    )
    state_0, state_1 = model.state(), model.state()
    control = model.control()
    pipeline = newton.CollisionPipeline(model)
    contacts = pipeline.contacts()
    pmass = model.particle_mass.numpy()[particle_start:particle_end]
    m_cloth = float(np.sum(pmass))
    if scene == "throw":
        g = 0.0
    else:
        g = 9.81 if abs(float(model.gravity.numpy()[0][2])) > 9.805 else 9.8
    steps = int(round(s["secs"] / dt))
    nan_at = None

    def cloth_centre(state):
        q = state.particle_q.numpy()[particle_start:particle_end].astype(np.float64)
        qd = state.particle_qd.numpy()[particle_start:particle_end].astype(np.float64)
        return float(np.sum(pmass * q[:, 2])) / m_cloth, float(np.sum(pmass * qd[:, 2])) / m_cloth

    lines_box, lines_cloth = [], []
    cz0, cvz0 = cloth_centre(state_0)
    bz0, bvz0 = float(state_0.body_q.numpy()[box][2]), float(state_0.body_qd.numpy()[box][2])
    with open(argv[1], "w") as f:
        f.write("CLOTH coupled_dt_ns %d cloth_mass_g %d box_mass_g %d steps %d feedback %d\n" % (
            whole(dt * 1e9), whole(m_cloth * 1e3), whole(s["box_mass"] * 1e3), steps, 1 if RecordingVBD.feedback else 0))
        for i in range(steps):
            v_before = state_0.particle_qd.numpy()[particle_start:particle_end].astype(np.float64)
            pipeline.collide(state_0, contacts)
            state_0.clear_forces()
            RecordingVBD.harvested = None
            solver.step(state_0, state_1, control, contacts, dt)
            state_0, state_1 = state_1, state_0
            v_after = state_0.particle_qd.numpy()[particle_start:particle_end].astype(np.float64)
            # the force the cloth receives along z: its momentum change over the step plus its weight
            f_cloth = float(np.sum(pmass * (v_after[:, 2] - v_before[:, 2]))) / dt + m_cloth * g
            bq, bqd = state_0.body_q.numpy()[box], state_0.body_qd.numpy()[box]
            h = RecordingVBD.harvested
            fz = float(h[2]) if h is not None else 0.0
            if not (np.all(np.isfinite(bq)) and np.all(np.isfinite(bqd)) and math.isfinite(fz)):
                nan_at = i
                break
            speed = math.sqrt(float(bqd[0]) ** 2 + float(bqd[1]) ** 2 + float(bqd[2]) ** 2)
            f.write("%d %d %d %d %d\n" % (i, whole(fz * 1e3), whole(f_cloth * 1e3), whole(float(bq[2]) * 1e6),
                                         whole(speed * 1e6)))
            if words["box"] or words["cloth"]:
                cz, cvz = cloth_centre(state_0)
                lines_box.append("%d %d %d 0 %d 0\n" % (i, whole(float(bq[2]) * 1e9), whole(float(bqd[2]) * 1e6),
                                                        whole(fz * 1e3)))
                lines_cloth.append("%d %d %d 0 %d 0\n" % (i, whole(cz * 1e9), whole(cvz * 1e6), whole(f_cloth * 1e3)))
    for path, lines, z0, vz0, mass in ((words["box"], lines_box, bz0, bvz0, float(model.body_mass.numpy()[box])),
                                       (words["cloth"], lines_cloth, cz0, cvz0, m_cloth)):
        if path:
            with open(path, "w") as c:
                c.write("CONTACT dt_ns %d h0_nm %d vx0_ums %d mu_ppm 0 mass_g %d steps %d\n" % (
                    whole(dt * 1e9), whole(z0 * 1e9), whole(vz0 * 1e6), whole(mass * 1e3), len(lines)))
                c.writelines(lines)
    extra = ["scene=%s" % scene] if scene != "rest" else []
    extra += ["%s=%g" % (k, s[k]) for k in ("box_hx", "box_hz", "cloth_vz") if s[k] != {"box_hx": 0.1, "box_hz": 0.025,
                                                                                       "cloth_vz": 0.0}[k]]
    extra += ["opt.%s=%s" % (k, opts[k]) for k in opts]
    print("STATS cloth coupled_dt %g secs %g cloth_mass %g box_mass %g iterations %d feedback %d steps %d%s engine newton "
          "%s extra %s" % (dt, s["secs"], m_cloth, s["box_mass"], int(s["iterations"]), 1 if RecordingVBD.feedback else 0,
                           steps, "" if nan_at is None else " nan_at_step %d" % nan_at, newton.__version__,
                           " ".join(extra) or "none"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
