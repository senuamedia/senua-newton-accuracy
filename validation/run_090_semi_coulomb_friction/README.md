# Run 090: SemiImplicit's friction as Coulomb's law at the step's end (issues 6 and 9)

Not registered: a design probe, its predictions pushed with [`play.sh`](play.sh) before any play. Newton 1.7.0 from
PyPI, and the same with Senua AI's SemiImplicit Coulomb friction patch in design first on the path
([`semi_coulomb_friction_on_1.7.0.diff`](../../patches/in_design/semi_coulomb_friction_on_1.7.0.diff), sha256
29d8410a7499af91..., switch `NEWTON_SEMI_COULOMB_FRICTION=1`).

## The patch

SemiImplicit's contact friction is a force, vt / H(vt) times min(kf H(vt), mu N), integrated explicitly: below mu N /
kf it is viscous, so a held load creeps at its push over the corners' kf (issue 6), and the explicit kf settles only
under steps of about 1.25 m / (10 kf) (issue 9; run 021). The patch takes friction out of the force pass (a copy of the
stock function with its friction line left out and each contact recorded: its normal force, normal, lever arms, mu and
bodies) and, after the step's integration, applies at each contact the tangential impulse that stops its slip, shared
among the body's contacts, no larger than mu times the normal impulse the force pass applied (Coulomb's cone), as XPBD
applies friction at the velocity level (Mueller et al. 2020, section 3.6); the pose follows the velocity's change over
the step.

## What is played

On SemiImplicit, as released, with the switch unset and set: run 001's hold (1 kg, half-size 0.05 m, friction 0.5,
pushed by 2.94 N, 0.6 of what friction holds, from 0.5 s, 2 s) at 2 ms (issue 9's scene), 0.5 and 0.125 ms; a slide
from 1 m/s at friction 0.5, 0.5 s, whose Coulomb distance is v^2 / (2 mu g) = 102,041 um; the contact suite.

## Predictions (pushed before the plays)

| Check | Prediction |
|---|---|
| C0 | With the switch unset every play byte for byte the release's; with it set every play a number |
| C1 | As released the hold moves at 300 um/s or more (either way) at every step; with the patch within 10 um/s of still |
| C2 | With the patch the slide within 1 in 100 of Coulomb's 102,041 um at every step |
| C3 | The suite's T06 (held below the friction limit) passes with the patch, and no verdict that passes as released is lost |

Reported: the release's slide (it stops at 44% of Coulomb's distance, Study 1), the suite's other verdicts.

## What it found

Played 20 October 2026 on the second x86-64 host (`started.txt`, `finished.txt`); the measured lines in
`measured.txt`, the checks in [`checks.txt`](checks.txt), the suites under `suites/`. **4 of 7 checks held.**

| Check | Result |
|---|---|
| C0 | Held: with the switch unset the 6 plays byte for byte the release's; with it set every play a number |
| C1 | Held as released (115,435, 6,601 and 735 um/s at 2, 0.5 and 0.125 ms); **failed** with the patch: 8,821, 2,205 and 551 um/s |
| C2 | Held: the slide 101,561, 102,281 and 102,467 um against Coulomb's 102,041 (as released 225,539, 39,431 and 38,291 um) |
| C3 | **Failed**: T06 fails (44,128 and 2,757 um/s); T08, which passes as released, is lost |

- **The slide is Coulomb's at every step**, where as released it is more than twice too long at 2 ms and 38% to 39%
  of it at the smaller steps; the suite's steady sliding (T02: 3,999 and 4,000 per 10,000 for 4,000) and its friction
  over an impact (T10) pass with the patch and fail as released, and its friction at impact (T05) is 3,999 to 4,000
  from the second step on (3,325 at the first). The suite passes 5 of 10 with the patch, 4 as released.
- **The hold creeps in proportion to the step**: 8,821, 2,205 and 551 um/s, each a quarter of the one before as the
  step is quartered, about one and a half times the speed the push gives the cube in one step (2.94 m/s^2 times the
  step). One sweep shares a body's slip among its contacts, and each corner's effective mass carries the turn the
  impulse gives the cube, so the sweep stops only part of the slip it finds; what it leaves each step is the creep.
  Run 092 makes the pass more than once a step.
- **T08 is lost**: the refinement chain's readings fall from 6,347,336 to 7,339 over the first four halvings, rise to
  9,988 at the fifth and fall to 2,244 at the sixth; as released they fall at every halving, from 7,241,120 to 20,486.
