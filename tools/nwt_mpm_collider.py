# nwt_mpm_collider.py: issue 21's implicit MPM colliders (newton-physics/newton #4712) for Newton: #4712's two scenes,
# played by SolverImplicitMPM. It calls Newton's own Python API, its only API, and does no measuring of its own: it
# writes what the material did at each output step, in whole numbers, in the CONTACT format Senua AI's measure reads.
# Things with a right answer:
#   slope  a cohesive slab resting on a static box inclined at 60 degrees with friction 3: Coulomb friction holds it
#          (tan 60 = 1.73 < 3), so it does not slide
#   cup    liquid in a cup whose walls are 4 mm thick: none of it leaves through the walls
# usage: python nwt_mpm_collider.py <out.txt> scene=slope|cup [margin=M] [voxel=M] [secs=S] [substeps=N] [mu=X]
#          [opt.NAME=VALUE]
#   margin    the collider shapes' margin, Newton's ShapeConfig margin, which SolverImplicitMPM takes as the
#             collider's thickness (default 0, Newton's default)
#   voxel     SolverImplicitMPM.Config's voxel_size (default as #4712: twice the particle spacing, 0.05 m for the slope
#             and 0.01 m for the cup)
#   secs      default 1; substeps default 8, the step 1/24 s over them, as #4712's script; mu the slope's friction
#             (default 3)
#   opt.<name>=<value>  a field of SolverImplicitMPM.Config, set as given (true/false, whole number, number or a word)
# writes <out.txt>: a header line "CONTACT dt_ns <n> h0_nm 0 vx0_ums 0 mu_ppm <n> mass_g <n> steps <n>", then one line
#   a step, six whole numbers: for the slope <step> <the slab's mean travel down the slope, nm> <its mean velocity down
#   the slope, um/s> 0 0 0; for the cup <step> <particles outside the walls> 0 0 0 0. Senua AI's `stop` reads the slope's
#   distance slid; its `final` the cup's last count (in its first column). Prints one STATS line. Exit 0.
import math
import sys

import numpy as np
import warp as wp

wp.config.quiet = True

import newton  # noqa: E402
from newton.solvers import SolverImplicitMPM  # noqa: E402


def whole(x):
    return int(math.floor(x + 0.5)) if x >= 0.0 else -int(math.floor(-x + 0.5))


def add_particles(b, P, sep, density, mat):
    b.add_particles(pos=P.tolist(), vel=[(0.0, 0.0, 0.0)] * len(P), mass=[density * sep**3] * len(P),
                    radius=[0.5 * sep] * len(P), custom_attributes={"mpm:%s" % k: v for k, v in mat.items()})


def main(argv):
    if len(argv) < 2:
        sys.stderr.write("usage: nwt_mpm_collider.py <out.txt> scene=slope|cup [margin=] [voxel=] [secs=] [substeps=] "
                         "[mu=] [opt.NAME=VALUE]\n")
        return 2
    s = {"margin": 0.0, "voxel": -1.0, "secs": 1.0, "substeps": 8.0, "mu": 3.0}
    scene = ""
    opts = {}
    for a in argv[2:]:
        k, _, v = a.partition("=")
        if k in s:
            s[k] = float(v)
        elif k == "scene":
            scene = v
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
            sys.stderr.write("nwt_mpm_collider: unknown setting %s\n" % a)
            return 2
    if scene not in ("slope", "cup"):
        sys.stderr.write("nwt_mpm_collider: scene=slope or scene=cup\n")
        return 2
    wp.set_device("cpu")
    b = newton.ModelBuilder(up_axis=newton.Axis.Y, gravity=(0.0, -9.81, 0.0))
    SolverImplicitMPM.register_custom_attributes(b)
    if scene == "slope":
        sep, a = 0.025, math.radians(60.0)
        n = np.array([-math.sin(a), math.cos(a), 0.0])
        t = np.array([math.cos(a), math.sin(a), 0.0])
        b.add_shape_box(-1, xform=wp.transform(wp.vec3(*(-n)), wp.quat_from_axis_angle(wp.vec3(0.0, 0.0, 1.0), a)),
                        hx=4.0, hy=1.0, hz=2.0, cfg=newton.ModelBuilder.ShapeConfig(mu=s["mu"], margin=s["margin"]))
        U, V, W = np.meshgrid(np.arange(-0.5, 0.5, sep) + 0.5 * sep, np.arange(0.0, 0.3, sep) + 0.5 * sep,
                              np.arange(-0.25, 0.25, sep) + 0.5 * sep, indexing="ij")
        P = U.reshape(-1, 1) * t + V.reshape(-1, 1) * n + W.reshape(-1, 1) * np.array([0.0, 0.0, 1.0])
        density = 400.0
        add_particles(b, P, sep, density, dict(young_modulus=1.4e5, poisson_ratio=0.2, friction=0.0,
                                               yield_pressure=2e3, tensile_yield_ratio=0.3, yield_stress=1.75e3))
    else:
        sep, wall = 0.005, 0.002
        b.add_ground_plane()
        cfg = newton.ModelBuilder.ShapeConfig(mu=0.0, margin=s["margin"])
        r, h = 0.05, 0.15
        for pos, half in (((r, h / 2, 0), (wall, h / 2, r)), ((-r, h / 2, 0), (wall, h / 2, r)),
                          ((0, h / 2, r), (r, h / 2, wall)), ((0, h / 2, -r), (r, h / 2, wall))):
            b.add_shape_box(-1, xform=wp.transform(wp.vec3(*pos), wp.quat_identity()), hx=half[0], hy=half[1],
                            hz=half[2], cfg=cfg)
        g = np.arange(-r + 2 * wall, r - 2 * wall, sep) + 0.5 * sep
        gy = np.arange(0.0, 0.12, sep) + 0.5 * sep
        X, Y, Z = np.meshgrid(g, gy, g, indexing="ij")
        P = np.stack([X.ravel(), Y.ravel(), Z.ravel()], 1)
        density = 1000.0
        add_particles(b, P, sep, density, dict(friction=0.0, tensile_yield_ratio=1.0, yield_stress=0.0))
    model = b.finalize()
    mc = SolverImplicitMPM.Config()
    mc.voxel_size = s["voxel"] if s["voxel"] > 0.0 else 2.0 * sep
    for k, v in opts.items():
        setattr(mc, k, v)
    solver = SolverImplicitMPM(model, mc)
    s0, s1 = model.state(), model.state()
    P0 = s0.particle_q.numpy().astype(np.float64)
    substeps = int(s["substeps"])
    dt = 1.0 / 24.0 / substeps
    steps = int(round(s["secs"] * 24 * substeps))
    mass_g = whole(density * sep**3 * len(P) * 1e3)
    lines = []
    nan_at = None
    for i in range(steps):
        solver.step(s0, s1, None, None, dt)
        solver.project_outside(s1, s1, dt)
        s0, s1 = s1, s0
        q = s0.particle_q.numpy().astype(np.float64)
        if not np.all(np.isfinite(q)):
            nan_at = i
            break
        if scene == "slope":
            down = -float(np.mean((q - P0) @ t))
            vel = -float(np.mean(s0.particle_qd.numpy().astype(np.float64) @ t))
            lines.append("%d %d %d 0 0 0\n" % (i, whole(down * 1e9), whole(vel * 1e6)))
        else:
            out = int(np.sum((np.abs(q[:, 0]) > r + wall) | (np.abs(q[:, 2]) > r + wall)))
            lines.append("%d %d 0 0 0 0\n" % (i, out))
    with open(argv[1], "w") as f:
        f.write("CONTACT dt_ns %d h0_nm 0 vx0_ums 0 mu_ppm %d mass_g %d steps %d\n" % (
            whole(dt * 1e9), whole((s["mu"] if scene == "slope" else 0.0) * 1e6), mass_g, len(lines)))
        f.writelines(lines)
    print("STATS mpm_collider scene %s margin %g voxel %g secs %g substeps %d particles %d steps %d%s engine newton %s "
          "extra %s" % (scene, s["margin"], mc.voxel_size, s["secs"], substeps, len(P), len(lines),
                        "" if nan_at is None else " nan_at_step %d" % nan_at, newton.__version__,
                        " ".join("opt.%s=%s" % (k, opts[k]) for k in opts) or "none"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
