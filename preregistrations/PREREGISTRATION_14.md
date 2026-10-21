# Fourteenth pre-registration: SemiImplicit's joint limit, its joint stiff enough to be one

Registered 20 October 2026, after the design probes of runs 077, 079, 084 and 086. Registered before any play of this
registration existed. To be played once, as run 087, on Newton 1.7.0 as released.

## The question

Issue 16: Newton's joint limit (`joint_force`) applies its damper until the angle is back at the limit, so it pulls a
joint back as it leaves. Study 11 fixed it on Featherstone. SemiImplicit shares the law, but plays a joint as a penalty
between two bodies (`joint_attach_ke`, `joint_attach_kd`): with Newton's default attachment (1e4 N/m) a strike on a heavy
arm is the soft joint's, not the limit's (run 084), and on a light arm the attachment is past its explicit bounds (runs
077, 079). With the attachment stiff enough to be a joint (1e6 N/m) the strike was within 0.008 rad of the no-tension
spring-dashpot as released (run 086). On arms and steps no probe used: does SemiImplicit's limit, its joint a joint,
turn a strike back where the spring and damper kept from pulling do?

## The right answer

The linear spring-dashpot kept from pulling (Schwager and Poeschel, Granular Matter 9, 465-469, 2007): an arm striking it
keeps the speed fraction e(z) = exp(-(z / sqrt(1 - z^2)) (pi - arctan(2 z sqrt(1 - z^2) / (1 - 2 z^2)))), z = kd / (2
sqrt(ke I)), and an arm released level onto a limit at -L turns back at -arcsin((1 - e^2) sin L) (Study 11's closed
form).

## Engine and rig

Newton 1.7.0 from PyPI as released, Study 7's environment. The rig `tools/nwt_joint.py` as committed at this
registration. Warp's CPU device. Measured by Senua AI's `sx_contact` (`swing`, each play's statistics line) and judged
by its `rule`.

## The scenes, registered parameters

One arm on one hinge released level under gravity onto its lower limit, Newton's limit (`limit_ke` 1e4, `limit_kd` 10),
2 s, on SemiImplicit with `joint_attach_ke=1e6` (its default damping), at 0.1 and 0.025 ms:

- **A4**: 4 kg, half-size 0.18 m, centre 0.45 m from the joint, limits -1 and 1 rad: kept from pulling it turns back
  at **-0.233 rad**. Its attachment's explicit bounds (the body's own inertia 0.0864 kg m^2): 0.59 ms for the spring,
  1.7 ms for the damper.
- **A1.5**: 1.5 kg, half-size 0.12 m, centre 0.35 m, limits -0.9 and 0.9 rad: **-0.388 rad**. Bounds 0.24 and 0.29 ms.

Reported, not ruled: the same with Newton's default attachment, and on Featherstone as released and with Study 11's
limit patch.

## The rules

| Rule | Statement | Kind |
|---|---|---|
| R1 a number | Every SemiImplicit play with the stiff attachment a number throughout | all_eq |
| R2 the strike | Where the arm turns back after its first strike within 0.02 rad of the closed form, both arms and both steps | all_in |

## What it decides

When R1 and R2 hold, issue 16 on SemiImplicit shows no departure beyond 0.02 rad with its joint stiff enough to be one,
and issue 16 is resolved: fixed and validated on Featherstone (Study 11), no departure on SemiImplicit; SemiImplicit's
default attachment stays a property of its penalty joints, reported. A rule that fails is reported as failed, and the
issue stays open.
