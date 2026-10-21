# Twelfth pre-registration: SemiImplicit's joint angle, and Featherstone's limit integrated implicitly

Registered 20 October 2026, after the design probes of runs 062, 068, 070, 076 and 077. Registered before any play of
this registration existed. To be played once, as run 078, on Newton 1.7.0.

## The question

Two open issues each have a fix measured in design probes but never held to rules registered in advance. On scenes and
steps no probe used: is each fault there as released, and is it gone with its fix?

| Issue | The fault | The fix | Measured in |
|---|---|---|---|
| 27 | SemiImplicit does not hold a driven joint at rest past a full turn, nor a two-axis D6 | Senua AI's SemiImplicit joint patch, `NEWTON_SEMI_JOINT_ANGLE=1` ([`semi_joint_on_1.7.0.diff`](../patches/in_design/semi_joint_on_1.7.0.diff)): a single rotational DOF measured within pi of its reference (pull request #4316's rule), a D6's rotation read about its own axes | runs 062, 077 |
| 28 | Featherstone diverges on serial arms the MuJoCo solver plays | Senua AI's Featherstone limit patch, `NEWTON_FEATHERSTONE_LIMIT=3` ([`featherstone_limit_v2_on_1.7.0.diff`](../patches/in_design/featherstone_limit_v2_on_1.7.0.diff)): the limit integrated linearly implicitly, kept only where the force it applies pushes | runs 055, 068, 070, 076 |

## The right answers

- A body at rest at its drive's target, nothing else acting on it, stays at rest there.
- A link resting on a joint limit under gravity stays at rest on it, a little past it (its weight's moment over the
  limit's stiffness), and every state is a number.

## Engines and rigs

Newton 1.7.0 from PyPI (`newton==1.7.0`, Warp 1.18.0, MuJoCo Warp 3.15.0) as released, Study 7's environment, and two
engines made from it by this run's `setup_engine.sh`, each the base environment's Newton with one diff applied (no
fuzz), first on the path: the SemiImplicit joint patch; the Featherstone limit patch. Rigs as committed at this
registration: `tools/nwt_rest.py`, `tools/nwt_joint.py`, `tools/nwt_chain.py`. Warp's CPU device. Measured by Senua
AI's `sx_contact` (`final`, and each play's statistics line) and judged by its `rule`.

## The scenes, registered parameters

None of these numbers was used in the probes.

- **S1, a drive past a full turn** (27): #4547's body (1 kg, unit inertia, no gravity) on a revolute about z driven at
  3 N m/rad toward 8.1 rad, started there at rest; 800 steps at 1 ms and at 0.5 ms; SemiImplicit with Newton's defaults
  and as the report sets it (no angular damping, no joint attachment); as released, with the switch unset, and set. As
  released its angle reads 8.1 - 4 pi, and the drive pulls 3 x 4 pi = 37.7 N m: after one step 37,699 and 18,850 urad/s.
  The rig reads the joint through `newton.eval_ik`, which wraps too; held is read from the speed and from the reading
  staying put.
- **S2, the two-axis D6** (27): #4540's D6 (axes y and z, targets 0.2 and 0.4 rad) driven at 5 N m/rad; 600 steps at 2
  ms and at 0.5 ms; the same two settings and three environments.
- **S3, a light arm on its limit** (28): 0.08 kg, half-size 0.012 m, centre 0.025 m out (I = 5.768e-5 kg m^2), released
  level under gravity onto its lower limit at -0.6 rad (upper 0.6), Newton's limit (1e4 and 10), 0.2 s; Featherstone as
  released, with the switch unset, and `=3`; at 1/240 s, 2 ms, 0.5 ms and 50 us. Its explicit bound is 11.5 us.
- **S4, a serial arm on its limit** (28): two links of 0.06 kg, half-size 0.012 m, centres 0.025 m from their joints,
  the joints 0.05 m apart, released level under gravity, the first joint onto its lower limit at -0.6 rad (upper 0.6),
  the second free, 0.25 s; the same environments and steps.

## The rules

Each judged by `sx_contact rule`, from the measured lines, and nowhere else.

| Rule | Statement | Kind |
|---|---|---|
| R1 safe when off (27) | With the switch unset every S1 and S2 play byte for byte the release's | eq (count) |
| R2 the fault is there (27) | As released S1 turns at 10,000 urad/s or more after one step, at both steps and settings | all_ge |
| R3 held past a full turn (27) | With the patch S1's speed within 100 urad/s of 0 after one step and after 800, and its reading within 1 mrad of its start, at both steps and settings | all_in, near |
| R4 the fault is there (27) | As released S2's first angle at 0.25 rad or more after 600 steps, at both steps and settings (run 062's drift: to 0.43 at 2 N m/rad) | all_ge |
| R5 the D6 held (27) | With the patch S2's angles within 1 mrad of 0.2 and 0.4 rad after 600 steps, at both steps and settings | near |
| R6 safe when off (28) | With the switch unset every S3 and S4 play byte for byte the release's | eq (count) |
| R7 the fault is there (28) | As released S3 and S4 stop being a number at every step | all_ge (the step it stops) |
| R8 a number (28) | At `=3` every S3 and S4 play a number throughout | all_eq |
| R9 at rest on the limit (28) | At `=3` the limited joint's last angle within 1 in 100 of -0.6 rad, and its last speed within 10,000 urad/s of 0, at every step | all_within, all_in |

Reported, not ruled: where each arm first turns back after its first strike (at large steps the implicit limit, which
acts only from the step after the joint passes it, throws it back up before it settles: run 070), the second link's
motion, and every reading at every step.

## What it decides

Issue 27 is fixed on SemiImplicit by its joint patch's angle half when R1 to R5 hold. Issue 28 is fixed on Featherstone
by the limit patch's third form when R6 to R9 hold. A rule that fails is reported as failed, and its issue stays open.
