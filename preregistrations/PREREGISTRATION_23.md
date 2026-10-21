# Twenty-third pre-registration: VBD's spinning body still, its contacts settling, in displacement form

Registered 21 October 2026, after Study 22 (run 114) and the design probe of run 115. Registered before any play of
this registration existed. To be played once, as run 117, on Newton 1.7.0.

## The question

Issue 13 on VBD-ALM (F12): a body spinning about a centre of mass off its origin, nothing acting on it, has its centre
drift, faster as the step shrinks: VBD reads the velocity back from its 32-bit poses. Senua AI's VBD displacement patch
(pull request #4721's displacement form in 1.7.0's rigid solve) held the centre still at every step in Study 22 (R3),
which did not validate the patch: 10 m out a free chain's loss did not fall with the step at the smallest step (issue
12, a cost in the joints' evaluation the patch does not reach, and not this registration's question), and its slide
moved 1.4% from the release's at 0.075 ms. Run 115 showed the release's slide itself comes apart as the step shrinks
(F2: 13% short at 0.0375 ms, or never stopping), where the patch's settles within 0.14%: the release was not the right
comparison. The right answer for a slide played at ever smaller steps is a distance that settles. On a spinning body,
slides and a hold no probe used: does the patch keep the centre still and contacts settled?

## The right answers

- A body with nothing acting on it keeps its centre of mass where it was, or moving as it was.
- A body slid along the ground plays the same slide however small the step, once the step is small enough: its
  distance settles as the step shrinks. A body held by friction stays held.

## Engines and rigs

Newton 1.7.0 from PyPI (`newton==1.7.0`, Warp 1.18.0, MuJoCo Warp 3.15.0) as released, Study 7's environment, and one
engine made from it by this run's `setup_engine.sh`: the base environment's Newton with Senua AI's VBD displacement
patch applied (no fuzz), first on the path ([`vbd_displacement_on_1.7.0.diff`](../patches/in_design/vbd_displacement_on_1.7.0.diff),
sha256 685c333b840ae7a4...); **on** sets `NEWTON_VBD_DISPLACEMENT=1`, **off** does not. Rig as committed at this
registration: `tools/nwt_contact.py`. Warp's CPU device. Measured by Senua AI's `sx_contact` (`creep`, `stop`) and
judged by its `rule`.

## The scenes, registered parameters

None of these numbers was used in the probes or in Study 22.

- **S, a spinning body**: a 1.7 kg cube of half-size 0.045 m whose box sits 0.03 m along its x from its origin,
  turning at 3.5 rad/s about z through its centre of mass, 1 m above the ground, no gravity, 1.2 s; on VBD and
  VBD-ALM; at 1.2, 0.24 and 0.06 ms; as released, off and on.
- **L, two slides** on VBD-ALM: L1, a 0.8 kg cube of half-size 0.04 m sent along the ground at 1.0 m/s at friction 0.4,
  0.6 s; L2, a 1.5 kg cube of half-size 0.05 m at 0.6 m/s at friction 0.55, 0.4 s; at 1.2, 0.24, 0.06 and 0.03 ms; as
  released, off and on.
- **H, a hold** on VBD-ALM: a 0.9 kg cube of half-size 0.035 m resting on the ground at friction 0.5, pushed sideways
  from 0.3 s at 2.2 N (50% of its friction's limit), 1.2 s, with Study 17's contact history and sticky matching; at
  1.2 and 0.06 ms; as released, off and on.

## The rules

Each judged by `sx_contact rule`, from the measured lines, and nowhere else.

| Rule | Statement | Kind |
|---|---|---|
| R1 safe when off | Off, every play byte for byte the release's | eq (count) |
| R2 the fault is there | As released, S's centre on VBD-ALM 100 um/s or more from still at 0.06 ms | ge |
| R3 the centre still | On, S's centre within 3 um/s of still at every step on both paths | all_in |
| R4 the slides settle | On, each slide's distance at 0.24 and 0.06 ms within 1 in 200 of its play at 0.03 ms | all_within |
| R5 the hold kept | On, the hold within 10 um/s of still at both steps | all_in |
| R6 a number | Every play on a number throughout | all_eq |

Reported, not ruled: every reading, the slides at 1.2 ms, the slides and the hold as released.

## What it decides

When R1 to R6 hold, issue 13 is fixed and validated on VBD-ALM (and on VBD) by the displacement patch, which lands as
a validated copy; with Study 9 on the MuJoCo solver, issue 13 is resolved. A rule that fails is reported as failed,
and the issue stays open.
