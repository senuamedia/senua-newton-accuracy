# Twenty-eighth pre-registration: one model across engines, MuJoCo C as the reference

Registered 21 October 2026. Registered before any play of this registration existed. To be played once, as run 131, on
Newton 1.7.0.

## The question

Issue 22: a scene replayed on another engine diverges. The report replays against PhysX, which these hosts do not
have; the engine they do have is MuJoCo C, MuJoCo's own `mj_step`, reached through the MuJoCo solver's CPU path
(`use_mujoco_cpu=True`), which plays MuJoCo's answer to the model Newton hands it. Within Newton the record measured
one model playing differently by solver because two frictions were combined differently (run 059), fixed by Study 26;
the record's other contact fixes (Studies 15 and 18) changed how XPBD, SemiImplicit and Featherstone hold and slide. As
released and with those fixes, does one model transfer from MuJoCo C to Newton's own solvers?

## The right answers

- One model plays one way, whichever engine plays it, within what the engines' own step discretisation allows: a
  Coulomb slide stops at Coulomb's distance, a cube pushed below its friction limit stays still, a cube pushed past it
  accelerates at what is left of the push.
- The reference is itself right: MuJoCo C, with MuJoCo's recommended configuration (the elliptic cone and noslip,
  Study 11), plays those answers.

## Engines and rigs

Newton 1.7.0 from PyPI (`newton==1.7.0`, Warp 1.18.0, MuJoCo Warp 3.15.0, MuJoCo 3.15.0) as released, Study 7's
environment, and one engine made from it by this run's `setup_engine.sh`, no fuzz, first on the path: **chain**, the
base environment's Newton with the record's validated friction chains (SemiImplicit's and Featherstone's:
`unit_friction_direction`, `contact_damping_no_pull`, `semi_coulomb_friction`, `featherstone_coulomb_friction`, Study
18; XPBD's: `xpbd_no_speed_floor`, `xpbd_friction_total`, Study 15), their switches set
(`NEWTON_XPBD_NO_SPEED_FLOOR=1`, `NEWTON_XPBD_FRICTION_TOTAL=1`, `NEWTON_UNIT_FRICTION_DIRECTION=1`,
`NEWTON_CONTACT_DAMPING_NO_PULL=1`, `NEWTON_SEMI_COULOMB_FRICTION=1`, `NEWTON_SEMI_COULOMB_FRICTION_ITERATIONS=64`,
`NEWTON_FEATHERSTONE_COULOMB_FRICTION=64`), XPBD at 64 iterations. **MuJoCo C**: the MuJoCo solver of an engine made the
same way with Senua AI's MuJoCo noslip patch ([`mujoco_noslip.diff`](../patches/newton-1.7.0/mujoco_noslip.diff), Study 11:
the option 1.7.0 cannot set, issue 15), `use_mujoco_cpu=True`, `cone=elliptic`, `noslip_iterations=10`. Rig as
committed at this registration:
`tools/nwt_contact.py`. Warp's CPU device. Measured by Senua AI's `sx_contact` (`creep`, `final`, `stop`) and judged by
its `rule`.

## The scenes, registered parameters

None of these numbers was used in a probe. A 0.8 kg cube of half-size 0.045 m on the plane, both shapes' friction 0.45
(limit 3.528 N), g = 9.8 m/s^2, at 1 ms and 0.5 ms:

- **slide**: sent at 0.9 m/s with no push, 0.6 s. Right answer: 91,837 um.
- **hold**: pushed at 2.1168 N (0.6 of the limit) from 0.3 s, 1.2 s. Right answer: held.
- **push**: pushed at 5.292 N (1.5 of the limit) from 0.3 s, 1.2 s. Right answer: 1.9845 m/s at the end.

Played on MuJoCo C, and on XPBD, SemiImplicit and Featherstone (ruled), the MuJoCo solver's Warp path with the
elliptic cone, VBD-ALM and VBD (reported), as released and with the chain.

## The rules

Each judged by `sx_contact rule`, from the measured lines, and nowhere else. "The three" are XPBD, SemiImplicit and
Featherstone.

| Rule | Statement | Kind |
|---|---|---|
| R1 the reference is right | MuJoCo C's slide within 1 in 100 of 91,837 um, its hold within 10 um/s of rest, its push within 1 in 100 of 1.9845 m/s, at both steps | all_within, all_in |
| R2 the fault is there | As released, at each step, one or more of the three departs from MuJoCo C: its slide by 1 in 10 or more of MuJoCo C's, or its hold creeping 100 um/s or more | eq (count) |
| R3 the slide transfers | With the chain, the three's slides within 1 in 100 of MuJoCo C's at both steps | within |
| R4 the hold transfers | With the chain, the three's holds within 10 um/s of rest at both steps | all_in |
| R5 the push transfers | With the chain, the three's final speeds within 1 in 100 of MuJoCo C's at both steps | within |
| R6 a number | Every play on a number throughout | all_eq |

Reported, not ruled: every reading, the MuJoCo solver's Warp path and VBD.

## What it decides

When R1 to R6 hold, issue 22 is resolved as far as these hosts can play it: one model transfers from MuJoCo C to
XPBD, SemiImplicit and Featherstone with the record's patches, with Study 26 for two frictions combined; what the
Warp path and VBD do is reported beside it. A rule that fails is reported as failed, and the issue stays open.

## Amendment before any play

21 October 2026, after the dry run and before any play: the dry run found that 1.7.0's MuJoCo solver takes no
`noslip_iterations` (issue 15, which Study 11 resolved with Senua AI's MuJoCo noslip patch), so MuJoCo C's engine,
`mjc`, carries that patch, as Study 11's did; nothing else changed.
