# Run 111: VBD's rigid solve in displacement form (issues 13 and 12)

Not registered: a design probe, its predictions pushed with [`play.sh`](play.sh) before any play. Newton 1.7.0 from PyPI,
and the same with Senua AI's VBD displacement patch in design first on the path
([`vbd_displacement_on_1.7.0.diff`](../../patches/in_design/vbd_displacement_on_1.7.0.diff), sha256 685c333b840ae7a4...,
switch `NEWTON_VBD_DISPLACEMENT=1`).

## The patch

Runs 104 and 108 found VBD's spinning body's centre drifting, faster as the step shrinks, from two sources: the
velocity read back from 32-bit poses, (x - x_prev) / dt, and, with the velocity carried (Study 4's patch), the solve's
own writes of the pose, which the carried velocity takes in as their difference from the inertial target; with the
solve left out VBD plays SemiImplicit's spinning body byte for byte. Pull request #4721 (open, stacked on two others,
against Newton's main) proposes the cure for VBD's sparse path: each body keeps its displacement d from its inertial
target, the inertial term is -m/dt^2 d, the pose x~ + d, and v = v_pred + d/dt. The patch makes that change in 1.7.0's
rigid solve, a turn kept with the displacement as a quaternion: a copy of the solve kernel whose inertial term and pose
update work on d (zeroed each step after the forward step), the pose the inertial target itself where d is zero, and a
velocity update v = v_pred + d/dt, w = w_pred + theta_d/dt in place of the read-back. Off with joint mimics or DAT
truncation, as the pull request's own limitation.

## What is played

As released (`stock`), the patched tree with the switch unset (`off`) and set (`on`): run 074's spinning body (1.5 kg,
half-size 0.04 m, its box 0.03 m off its origin, turning at 4 rad/s about z, no gravity, 2 s) on VBD and VBD-ALM at 2,
0.5, 0.125 and 0.0625 ms; Study 9's free chain on VBD at 2, 0.5 and 0.125 ms; run 044's hold on VBD-ALM cold and with
Study 17's contact history and sticky matching, and a slide, at 2 and 0.125 ms.

## Predictions (pushed before the plays)

| Check | Prediction |
|---|---|
| C0 | `off` byte for byte the release in every play; every `on` play a number |
| C1 | With the patch the spinning body's centre within 3 um/s of still at every step on both paths (SemiImplicit's, run 030) |
| C2 | With the patch the chain's energy drift no larger as the step shrinks: its 32-bit growth gone, what is left the scheme's own |
| C3 | With the patch and the contact history the hold within 10 um/s of still at both steps, and the slide within 1 in 100 of the release's at 2 ms |

Reported: every reading, the chain's momentum, the cold hold.

## What it found

Played 20 October 2026 on the Newton host (`started.txt`, `finished.txt`); the measured lines in `measured.txt`, the
checks in [`checks.txt`](checks.txt). **6 of 6 checks held.**

| Check | Result |
|---|---|
| C0 | Held: `off` 17 of 17 byte for byte the release; every `on` play a number |
| C1 | Held: with the patch the spinning body's centre still, 0 um/s, at every step on both paths |
| C2 | Held: with the patch the chain's energy drift shrinks as the step shrinks |
| C3 | Held: the hold with the contact history 0 and 0 um/s; the slide 138,123 um against 138,121 as released |

| | 2 ms | 0.5 ms | 0.125 ms | 0.0625 ms |
|---|---|---|---|---|
| Spinning body's centre, as released (VBD and VBD-ALM alike) | 19 | 133 | -3,751 | 12,994 um/s |
| With the patch | 0 | 0 | 0 | 0 |
| Free chain's energy, as released | -39,602 | -7,920 | -311,550 ppm | |
| With the patch | -39,653 | -10,787 | -2,463 ppm | |
| Free chain's angular momentum, with the patch | -13,533 | -3,463 | -680 ppm | |

- **The displacement form removes VBD's 32-bit drift**: a body with nothing acting on it keeps its centre still at
  every step, where as released it drifts faster as the step shrinks, 13 mm/s at 0.0625 ms; the free chain no longer
  loses most of its energy at small steps (31% as released at 0.125 ms, 0.25% with the patch).
- **What is left of the chain's loss is first order in the step**: 4.0%, 1.1% and 0.25% at 2, 0.5 and 0.125 ms, each
  about a quarter of the one before, its momentum likewise: the dissipation of VBD's scheme, implicit (backward) Euler,
  which the step bounds and nothing in the patch touches.
- Contacts keep their play: the hold with Study 17's contact history still, the slide the release's to 2 um.
