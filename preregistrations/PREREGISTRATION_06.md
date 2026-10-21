# Sixth pre-registration: the MuJoCo solver's joint limit with the stiffness and damping Newton gives it

Registered 15 October 2026, after design probes (runs 036, 039 and 042). Registered before any play of this
registration existed. To be played once, as run 043.

## The question

Newton converts a joint limit's `limit_ke` and `limit_kd` for the MuJoCo solver with a factor `dof_invweight0 *
(1 - dmax)`, but MuJoCo's soft limit already holds with d^2 k / invweight, so the limit keeps only (1 - dmax) of each,
0.05 by default (F15). The patch in design `patches/in_design/mujoco_limit_force_space.diff`, with
`NEWTON_MUJOCO_LIMIT_FORCE_SPACE=1`, converts by `dof_invweight0` alone. On an arm the probes did not use: is the fault
there as released; with the patch, does an arm struck on its limit turn back where Newton's spring and damper send it;
does nothing without a limit change; and with the switch unset, is the patched Newton the release byte for byte?

## The right answer

A joint limit is one-sided: it pushes an arm out and cannot pull it back in, as a contact (Study 3). Released level
onto its lower limit at angle L (gravity along -y), an arm strikes the limit's spring and damper (stiffness ke,
damping kd, its inertia about the joint I, damping ratio z = kd / (2 sqrt(ke I))) and keeps of its speed
e = exp(-(z / sqrt(1 - z^2)) (pi - arctan(2 z sqrt(1 - z^2) / (1 - 2 z^2)))), the linear spring-dashpot kept from
pulling (Schwager and Poeschel, Granular Matter 9, 465-469, 2007; run 042 found the patched limit within 0.011 rad of
it). It then turns back at asin(sin L (1 - e^2)). Gravity during the strike is neglected in this form; the tolerance
allows for it.

## Engines and arms

- **stock**: Newton 1.6.1 from PyPI with run 001's environment.
- **patched**: Newton v1.6.1 from source (commit 713fecd) with `mujoco_limit_force_space.diff` (sha256
  77925587f1591155...) applied, in its own environment, every dependency as stock's (run 039's).

| Arm | Engine | `NEWTON_MUJOCO_LIMIT_FORCE_SPACE` |
|---|---|---|
| stock | stock | unset |
| off | patched | unset |
| on | patched | 1 |

Rig as committed at this registration: `tools/nwt_joint.py`, the MuJoCo solver, its own defaults otherwise, Newton's
default limit_ke 1e4 and limit_kd 10. Measured by Senua AI's `sx_contact swing` (the arm's turning points; the second
is where it turns back after the strike) and byte comparisons, judged by its `rule`. Warp's CPU device. Two steps no
probe used, 0.8 ms and 0.16 ms, both where h sqrt(ke / I) is at most 1 (0.42 and 0.08 at the lighter arm).

## The scenes, registered parameters

None of these numbers was used in the probes. An arm 0.35 m long (a cube of half-size 0.035 m at its end), released
level with gravity, 1.5 s; I = 0.12332 m.

- **struck**: limits -0.8 and 1 rad, masses 0.3 kg (z = 0.2600) and 3 kg (z = 0.0822). Right answer: it turns back at
  -0.5726 rad and -0.2821 rad.
- **free**: no limits, 0.3 and 3 kg. Right answer: unchanged by the patch, which acts only on limits.

## The rules

Each judged by `sx_contact rule`, from the measured lines, and nowhere else.

| Rule | Statement | Kind |
|---|---|---|
| R1 safe when off | Every file the off arm plays is byte-identical to the stock arm's | eq (identical files, files) |
| R2 the fault is there | stock: the arm turns back at least 0.1 rad higher than the right answer, at both masses and steps | all_ge |
| R3 the strike | on: the arm turns back within 0.03 rad of the right answer, at both masses and steps | all_ge and all_le |
| R4 nothing else changes | on: the free arm byte-identical to stock's, at both masses and steps | eq (identical files, files) |
| R5 nothing blows up | on: no play's state stops being a number or leaves the format's range | eq (such plays, 0) |

The study holds if every rule holds. A rule that fails is reported as failed, with its numbers, and the patch stays in
design.

Reported, not deciding: how far past the limit the arm goes in every arm; the struck arm at 10 ms (h sqrt(ke / I) of
5.2 and 1.6), played and not ruled.

## The runner and its dry run

`validation/run_043_study_06/play.sh`, committed with this registration. Before the study it is played once with
`DRY=1`: the on arm only, with throwaway parameters (run 036's arm at 1 kg, 2.5 ms), into `dry/`, only to check that it
runs to the end and writes every measured line; no rule is read from it.
