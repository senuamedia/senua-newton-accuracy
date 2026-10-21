# Fifth pre-registration: XPBD's joint angle tracked continuously past pi

Registered 15 October 2026, after design probes (runs 032 and 035). Registered before any play of this registration
existed. To be played once, as run 037.

## The question

XPBD throws a joint that turns past pi inside limits it never reaches (F13, run 032): its joint solve compares the
limits with an angle in [-pi, pi]. The patch in design `patches/in_design/xpbd_joint_angle_unwrap.diff`, with
`NEWTON_XPBD_JOINT_ANGLE_UNWRAP=1`, keeps each revolute joint's last angle, unwrapped, and adds to the measured angle the
whole turns that bring it nearest the last. On scenes the probes did not use, a single arm on one hinge (no second body
to pull the joint off its limit, run 035): is the fault there as released; with the patch, does a joint inside its
limits play past pi as with none, and is a joint that reaches a limit beyond pi held at it; is every play in which no
joint passes pi the release's; and with the switch unset, is the patched Newton the release byte for byte?

## Engines and arms

- **stock**: Newton 1.6.1 from PyPI with run 001's environment.
- **patched**: Newton v1.6.1 from source (commit 713fecd) with `xpbd_joint_angle_unwrap.diff` (sha256
  ce0fe02dcf4b2ebe...) applied, in its own environment, every dependency as stock's (run 035's).

| Arm | Engine | `NEWTON_XPBD_JOINT_ANGLE_UNWRAP` |
|---|---|---|
| stock | stock | unset |
| off | patched | unset |
| on | patched | 1 |

Rig as committed at this registration: `tools/nwt_joint.py`, solver XPBD, its own defaults otherwise. Measured by Senua
AI's `sx_contact` (`final`: the last step's joint angle and speed) and byte comparisons, judged by its `rule`. Warp's
CPU device. Every scene at two steps no probe used: 1.6 ms and 0.32 ms.

## The scenes, registered parameters

None of these numbers was used in the probes. One arm: 1.5 kg, a cube of half-size 0.03 m whose centre is 0.3 m from
the joint; no gravity; set turning at 3 rad/s from 0 rad (it passes pi at 1.047 s).

- **none**: no limits, 1.6 s. Right answer: it turns on at 3 rad/s.
- **inside**: limits -0.5 and 5 rad, 1.6 s (it reaches 4.8 rad and never its limit). Right answer: as with none.
- **reach**: limits -0.5 and 3.6 rad, 1.6 s (it reaches 3.6 rad at 1.2 s). Right answer: held at 3.6 rad.
- **below**: limits -0.5 and 2.5 rad, 1.4 s (it reaches 2.5 rad at 0.83 s, before pi). Right answer: held at 2.5 rad,
  the joint never passing pi.

## The rules

Each judged by `sx_contact rule`, from the measured lines, and nowhere else.

| Rule | Statement | Kind |
|---|---|---|
| R1 safe when off | Every file the off arm plays is byte-identical to the stock arm's | eq (identical files, files) |
| R2 the fault is there | stock: inside differs from none at both steps (no file identical) | eq (identical files, 0) |
| R3 inside, as with none | on: inside byte-identical to on's none, at both steps | eq (identical files, files) |
| R4 reach, held at the limit | on: reach's last angle within 1 in 72 (0.05 rad) of 3,600,000 urad, and its last speed within 0.1 rad/s of 0, at both steps | all_within; all_le and all_ge |
| R5 nothing else changes | on: none and below byte-identical to stock's, at both steps | eq (identical files, files) |
| R6 nothing blows up | on: no play's state stops being a number | eq (plays with nan_at_step, 0) |

The study holds if every rule holds. A rule that fails is reported as failed, with its numbers, and the patch stays in
design.

Reported, not deciding: every play's last angle and speed in every arm.

## The runner and its dry run

`validation/run_037_study_05/play.sh`, committed with this registration. Before the study it is played once with
`DRY=1`: the on arm only, with throwaway parameters (an arm of 1 kg, half-size 0.05 m, 0.5 m long, at 2.5 ms), into
`dry/`, only to check that it runs to the end and writes every measured line; no rule is read from it.
