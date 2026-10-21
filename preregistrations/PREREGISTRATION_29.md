# Twenty-ninth pre-registration: one model across engines, each held to the right answer

Registered 21 October 2026, after Study 28 (run 131). Registered before any play of this registration existed. To be
played once, as run 132, on Newton 1.7.0.

## The question

Issue 22: a scene replayed on another engine diverges. Study 28 took MuJoCo C (MuJoCo's own `mj_step`, the MuJoCo
solver's CPU path) as the reference and found Newton's XPBD, SemiImplicit and Featherstone, with the record's friction
chains, playing its slide and hold, and its push at 0.5 ms; at 1 ms MuJoCo C's own push was 4.5% slow, its elliptic
soft friction rising with speed, and Newton's three, right there, were ruled against it, so Study 28's precondition (the
reference right) failed. This registration does not assume either engine is right: each is held to the right answer,
and the transfer is ruled where the reference is right. On a cube and coefficients no study used: does one model play
the same on Newton's solvers as on MuJoCo C wherever MuJoCo C plays it right, and do Newton's solvers play it right
where MuJoCo C does not?

## The right answers

- A Coulomb slide stops at Coulomb's distance, a cube pushed below its friction limit stays still, a cube pushed past it
  accelerates at what is left of the push.
- Two engines playing one model agree wherever each plays the physics; where they disagree, the one that departs from
  the physics is the one at fault.

## Engines and rigs

As Study 28 (run 131's `setup_engine.sh`, copied as this run's): Newton 1.7.0 from PyPI as released; **chain**, the
record's validated friction chains (Studies 15 and 18) with their switches, XPBD at 64 iterations; **MuJoCo C**, the
MuJoCo solver of the release with Senua AI's MuJoCo noslip patch (Study 11), `use_mujoco_cpu=True`, `cone=elliptic`,
`noslip_iterations=10`. Rig as committed at this registration: `tools/nwt_contact.py`. Warp's CPU device. Measured by
Senua AI's `sx_contact` (`creep`, `final`, `stop`) and judged by its `rule`.

## The scenes, registered parameters

None of these numbers was used in a probe or a study. A 1.2 kg cube of half-size 0.05 m on the plane, both shapes'
friction 0.35 (limit 4.116 N), g = 9.8 m/s^2, at 1 ms and 0.5 ms:

- **slide**: sent at 0.7 m/s with no push, 0.6 s. Right answer: 71,429 um.
- **hold**: pushed at 2.058 N (0.5 of the limit) from 0.3 s, 1.2 s. Right answer: held.
- **push**: pushed at 8.232 N (2 times the limit) from 0.3 s, 1.2 s. Right answer: 3.087 m/s at the end.

Played on MuJoCo C, and on XPBD, SemiImplicit and Featherstone, as released and with the chain; the MuJoCo solver's
Warp path (elliptic cone), VBD-ALM and VBD reported.

## The rules

Each judged by `sx_contact rule`, from the measured lines, and nowhere else. "The three" are XPBD, SemiImplicit and
Featherstone with the chain. "Right" is within 1 in 100 of the right answer for the slide and the push, within 10 um/s of
rest for the hold.

| Rule | Statement | Kind |
|---|---|---|
| R1 Newton right | The three right on every scene at both steps | all_within, all_in |
| R2 the transfer | On every scene and step where MuJoCo C is right, each of the three within 1 in 100 of MuJoCo C (the hold: both within 10 um/s of rest), counted | eq (count) |
| R3 the fault is there | As released, at each step, one or more of the three departs from MuJoCo C: its slide by 1 in 10 or more of MuJoCo C's, or its hold creeping 100 um/s or more | eq (count) |
| R4 a number | Every play on a number throughout | all_eq |

Reported, not ruled: every reading; where MuJoCo C is not right, by how much; the Warp path and VBD.

## What it decides

When R1 to R4 hold, issue 22 is resolved as far as these hosts can play it: with the record's patches one model plays
the same on Newton's three as on MuJoCo C wherever MuJoCo C plays the physics, and Newton's three play it right where
MuJoCo C does not; the report's PhysX replay, which these hosts cannot play, is recorded as not played. A rule that fails
is reported as failed, and the issue stays open.
