# Thirteenth pre-registration: SemiImplicit's joint angle, its D6 fault sized from Study 12

Registered 20 October 2026, after Study 12 (run 078), whose fault rule for the two-axis D6 (R4) failed at 0.5 ms while
every rule of the fix held. Registered before any play of this registration existed. To be played once, as run 080, on
Newton 1.7.0.

## The question

Issue 27: SemiImplicit does not hold a driven joint at rest past a full turn, nor a two-axis D6. The fix, Senua AI's
SemiImplicit joint patch, `NEWTON_SEMI_JOINT_ANGLE=1` ([`semi_joint_on_1.7.0.diff`](../patches/in_design/semi_joint_on_1.7.0.diff)):
a single rotational DOF measured within pi of its reference (pull request #4316's rule), a D6's rotation read about its
own axes. On scenes and steps no earlier play used, is the fault there as released, and is it gone with the fix? Study
12's R4 asked the release's D6 to drift 0.05 rad in 600 steps; at 0.5 ms (0.3 s) it drifted 0.0495 rad. Here the D6 is
played for 1 s or more, and its fault rule asks for a drift of 0.02 rad, twenty times the fix's tolerance.

## The right answer

A body at rest at its drive's target, nothing else acting on it, stays at rest there.

## Engines and rigs

Newton 1.7.0 from PyPI as released, Study 7's environment, and the patch's engine made by Study 12's
[`setup_engine.sh`](../validation/run_078_study_12/setup_engine.sh). The rig `tools/nwt_rest.py` as committed at this
registration. Warp's CPU device. Measured by Senua AI's `sx_contact` (`final`) and judged by its `rule`.

## The scenes, registered parameters

- **T1, a drive past a full turn the other way**: #4547's body (1 kg, unit inertia, no gravity) on a revolute about z
  driven at 4 N m/rad toward -7.6 rad, started there at rest; 1,200 steps at 2 ms and at 0.25 ms; SemiImplicit with
  Newton's defaults and as the report sets it (no angular damping, no joint attachment); as released, with the switch
  unset, and set. As released its angle reads -7.6 + 4 pi = 4.966 rad, and the drive pulls 4 x 4 pi = 50.3 N m: after
  one step 100,531 and 12,566 urad/s.
- **T2, the two-axis D6**: #4540's D6 (axes y and z, targets 0.2 and 0.4 rad) driven at 3 N m/rad; 1,500 steps at 1 ms
  and 2,000 steps at 0.5 ms; the same settings and environments.

## The rules

| Rule | Statement | Kind |
|---|---|---|
| R1 safe when off | With the switch unset every play byte for byte the release's | eq (count) |
| R2 the fault is there (the drive) | As released T1 turns at 10,000 urad/s or more after one step (its speed's size; it turns the negative way), at both steps and settings | all_ge |
| R3 held past a full turn | With the patch T1's speed within 100 urad/s of 0 after one step and after 1,200, and its reading within 1 mrad of its start, at both steps and settings | all_in, near |
| R4 the fault is there (the D6) | As released T2's first angle at 0.22 rad or more at the end, at both steps and settings | all_ge |
| R5 the D6 held | With the patch T2's angles within 1 mrad of 0.2 and 0.4 rad at the end, at both steps and settings | near |

## What it decides

Issue 27 is fixed on SemiImplicit by the patch's angle half when R1 to R5 hold. A rule that fails is reported as
failed, and the issue stays open.
