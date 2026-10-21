# Second pre-registration: XPBD with its restitution option, no bounce and Coulomb's friction at an impact

Registered 15 October 2026, after design probes (runs 015, 016 and 018). Registered before any play of this
registration existed. To be played once, as run 019.

## The question

XPBD with a restitution of 0 bounces 4% to 12% of a drop (runs 001, 007). Its own option `enable_restitution` removes
the bounce but takes friction at an impact down to 4% to 43% of Coulomb's (run 015): its restitution pass applies
normal impulses only, while XPBD bounds friction by the position pass's own normal correction. The patch in design
`patches/in_design/xpbd_restitution_friction_v2.diff`, with `NEWTON_XPBD_RESTITUTION_FRICTION=2`, solves that pass with
Coulomb's friction on the normal impulse it applies, and takes friction back where the pass pulls a contact down
(run 018: the five checks held on the suite). On scenes the probes did not use: does Newton as released still bounce
and, with `enable_restitution`, still lose friction at an impact; with the patch on, is there no bounce and is the
friction at and after an impact Coulomb's; does nothing else change; and with the switch unset, or with the pass not
run, is the patched Newton the release byte for byte?

## Engines and arms

- **stock**: Newton 1.6.1 from PyPI with run 001's environment (`validation/run_001_design_probes/environment.txt`).
- **patched**: Newton v1.6.1 from source (commit 713fecdc...) with the patch file of sha256 a572b966c46067e1...
  applied, in its own environment with every dependency as stock's (a copy of run 005's patched environment).

| Arm | Engine | `NEWTON_XPBD_RESTITUTION_FRICTION` | XPBD's `enable_restitution` |
|---|---|---|---|
| stock_plain | stock | unset | off (as released) |
| stock_res | stock | unset | on |
| off_plain | patched | unset | off |
| off_res | patched | unset | on |
| on_plain | patched | 2 | off |
| on_res | patched | 2 | on |

Rig as committed at this registration: `tools/nwt_contact.py`, solver XPBD, its own defaults otherwise. Measured by
Senua AI's `sx_contact` (`bounce`, `impact`, `settle`) and judged by its `rule`. Warp's CPU device. Every scene at two
steps no probe used: 4 ms and 0.4 ms.

## The scenes, registered parameters

None of these numbers was used in the probes. A cube of 1.4 kg, half-size 0.035 m.

- **The drop**: from 60 mm, friction 0, 0.6 s. Right answer with a restitution of 0: no rebound.
- **The oblique impact**: from 50 mm at 2.5 m/s along x, friction 0.35, 0.5 s. Right answer: friction over the
  impact, and over the impact and the 0.1 s after it, 3,500 per 10,000 of the normal impulse (the cube still slides
  then: Coulomb's deceleration stops it after 0.73 s).
- **Nothing else**: the cube set on the ground sliding at 1.8 m/s, friction 0.35, 1 s; set on the ground at rest,
  friction 0.35, 1 s; and set on the ground and pushed along x with 2.881 N from 0.3 s, 0.6 of what friction 0.35
  holds, 1 s. None of these lands.

## The rules

Each judged by `sx_contact rule`, from the measured lines, and nowhere else.

| Rule | Statement | Kind |
|---|---|---|
| R1 safe when off | Every file off_plain plays is byte-identical to stock_plain's, and every file off_res plays to stock_res's | eq (identical files, files) |
| R2 the defects are there | stock_plain: the drop rebounds at least 100 per 10,000 of its height at both steps; stock_res: friction over the impact at most 3,150 per 10,000 (0.9 of Coulomb's) at both steps | all_ge, all_le |
| R3 no bounce | on_res: the drop rebounds at most 10 per 10,000 at both steps | all_le |
| R4 the impact | on_res: friction over the impact within 1 part in 100 of 3,500 at both steps | all_within |
| R5 after the impact | on_res: friction over the impact and the 0.1 s after it within 1 part in 100 of 3,500 at both steps | all_within |
| R6 nothing else changes | on_res: the slide, the rest and the push, at both steps, byte-identical to stock_res's | eq (identical files, files) |
| R7 nothing when the pass does not run | Every file on_plain plays is byte-identical to stock_plain's | eq (identical files, files) |
| R8 nothing blows up | on_plain and on_res: no play's state stops being a number | eq (plays with nan_at_step, 0) |

The study holds if every rule holds. A rule that fails is reported as failed, with its numbers, and the patch stays in
design.

Reported, not deciding: the largest turn of the cube in the oblique impact in each arm (`most_tilt_urad`).

## The runner and its dry run

`validation/run_019_study_02/play.sh`, committed with this registration. Before the study it is played once with
`DRY=1`: the stock_res arm only, with throwaway parameters (the suite's cube and scenes at 5 ms), into `dry/`, only to
check that it runs to the end and writes every measured line; no rule is read from it.
