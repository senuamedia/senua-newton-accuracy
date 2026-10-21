# Twenty-first pre-registration: nothing a solver ignores goes unsaid, and SemiImplicit plays a loop

Registered 21 October 2026, after runs 056 and 063. Registered before any play of this registration existed. To be
played once, as run 110, on Newton 1.7.0.

## The question

Issue 19 (N7, newton-physics/newton #2428): joint features silently ignored. Run 056 found a joint's velocity limit
applied by no solver and its effort limit by the MuJoCo solver only; run 063 a loop-closing joint's limit and drive
ignored by the MuJoCo solver (MuJoCo's equality constraints cannot carry them) and by Featherstone (which plays a tree,
the loop joint left out), and SemiImplicit unable to play the loop at all; nothing said, in any play. Newton 1.7.0's
solver docstrings list these features as not supported, solver by solver, but nothing is said when a model that sets
one is played. Upstream's answer for the MuJoCo solver's loop joints (#2428's thread) is a warning naming what is
dropped, pull request #3552. Senua AI's joint-feature warnings patch makes every solver, when made, name each joint
feature the model configures that its documentation says it does not apply, and the joints that configure it.
SemiImplicit's loop is its explicit joint damper (issue 10): with `joint_attach_kd=0`, Newton's own option and
Study 9's fix for issue 10, it played run 063's loop and applied its drive. On joints and loops no run used: is every
ignored feature named, is nothing said where nothing is ignored, does nothing else change, and does SemiImplicit play
the loop?

## The right answer

A solver that does not apply a feature a model sets says so when the model is played; one that applies it plays it.

## Engines and rigs

Newton 1.7.0 from PyPI as released, Study 7's environment, and one engine made from it by this run's
`setup_engine.sh`: the base environment's Newton with pull request #3552 rebased onto 1.7.0
([`pr_3552_on_1.7.0.diff`](../patches/upstream/pr_3552_on_1.7.0.diff), its docstring hunk placed by hand, the code
unchanged) and Senua AI's joint-feature warnings patch on it
([`joint_feature_warnings_on_pr3552.diff`](../patches/in_design/joint_feature_warnings_on_pr3552.diff), switch
`NEWTON_WARN_IGNORED_JOINT_FEATURES=1`), first on the path; **on** sets the switch, **off** does not. Rigs as committed
at this registration: `tools/nwt_joint.py`, `tools/nwt_loop.py`. Warp's CPU device. Each play's error stream kept; the
warnings counted in it by the runner; the loop read by Senua AI's `sx_contact` (`final`) and judged by its `rule`.

## The scenes, registered parameters

None of these numbers was used in runs 056 or 063.

- **J, a limited joint**: the joint rig's arm (0.8 kg, half-size 0.04 m, its centre 0.3 m out) driven toward 0.7 rad
  (target_ke 40, target_kd 4) with a velocity limit of 1.5 rad/s and an effort limit of 0.6 N m, no gravity, 0.3 s at
  1 ms; on Featherstone, SemiImplicit, XPBD, VBD and the MuJoCo solver; as released, off and on.
- **P, a plain joint**: the same arm and drive with no velocity or effort limit; the same solvers; on.
- **L, a loop**: the loop rig's arm (1.3 kg, half-size 0.045 m, its centre 0.4 m out), joint B carrying a drive toward
  0.45 rad (drivek 60, drived 6) and limits -0.9 and 0.9 rad, 1.2 s at 0.2 ms; on Featherstone and the MuJoCo solver,
  as released and on; on SemiImplicit with `joint_attach_kd=0`, on.

## The rules

| Rule | Statement | Kind |
|---|---|---|
| R1 named | On, J's warning names the velocity limit on all five solvers and the effort limit on all but the MuJoCo solver; L's names the loop-closing joint on Featherstone, and #3552's names its limits and drive on the MuJoCo solver | eq (count of the 12 expected names found) |
| R2 nothing where nothing is ignored | On, P's error streams carry no warning naming a joint feature | eq (count) |
| R3 off says nothing new | Off, J's error streams carry no Senua AI warning | eq (count) |
| R4 nothing else changes | Every J play off and on byte for byte the release's, and every L play on byte for byte the release's | eq (count) |
| R5 SemiImplicit plays the loop | With `joint_attach_kd=0` SemiImplicit's L a number throughout, joint A at rest within 1 mrad of B's drive target 0.45 rad at the end, slower than 0.01 rad/s | all_eq, near, in |

Reported, not ruled: each warning's text, every play's last state.

## What it decides

When R1 to R5 hold, issue 19 is fixed and validated: nothing a solver does not apply goes unsaid, by Senua AI's
patch with pull request #3552, and SemiImplicit plays a loop-closing joint, applying its drive, with Newton's own
configuration. A rule that fails is reported as failed, and the issue stays open.

## Amended before the play (21 October 2026)

The runner's dry run showed SemiImplicit's joint J stopping being a number within ten steps at the registered 1 ms,
and its loop at the dry run's 1 ms, both SemiImplicit's explicit joint attachment (issue 10). Before any play of this
registration, J, P and L are played at 0.05 ms (a step neither run 056 nor run 063 used, 0.3 s and 1.2 s as
registered), and SemiImplicit with `joint_attach_kd=0` in every scene, as Study 9 fixed issue 10. The rules are
unchanged.
