# Twenty-second pre-registration: VBD's rigid solve in displacement form

Registered 21 October 2026, after the design probes of runs 104, 108, 111 and 113. Registered before any play of this
registration existed. To be played once, as run 114, on Newton 1.7.0.

## The question

Issue 13 on VBD-ALM (F12): a body spinning about a centre of mass off its origin, nothing acting on it, has its centre
drift, faster as the step shrinks. Issue 12 on VBD (F9, N20, newton-physics/newton #4720): a free chain loses its
energy, more as the step shrinks, and far more away from the world's origin (runs 045, 113): VBD adds each iteration's
increment to its 32-bit poses and reads the velocity back from them. Pull request #4721 proposes a displacement form
for VBD's sparse path; Senua AI's VBD displacement patch takes it into 1.7.0's rigid solve: each body keeps its
displacement from the inertial target apart from its pose, and the velocity is the forward step's plus that
displacement over the step. It held the spinning body still at every step, made the chain's loss fall with the step at
the origin, 10 m and 100 m out, and kept contacts' play (runs 111, 113). On a body, a chain and contacts no probe used:
does it?

## The right answers

- A body with nothing acting on it keeps its centre of mass where it was, or moving as it was.
- A chain with nothing acting on it keeps its energy; a scheme's own error in it falls as the step shrinks; and where
  the chain is does not change what it does. In 32-bit numbers far from the origin some cost is the numbers' own: 100 m
  out a joint-space solver pays it too (run 113: Featherstone 11.6 times its departure at the origin), so there the
  departure is read against Featherstone's at the same place, and ruled only on falling with the step.

## Engines and rigs

Newton 1.7.0 from PyPI (`newton==1.7.0`, Warp 1.18.0, MuJoCo Warp 3.15.0) as released, Study 7's environment, and one
engine made from it by this run's `setup_engine.sh`: the base environment's Newton with Senua AI's VBD displacement
patch applied (no fuzz), first on the path ([`vbd_displacement_on_1.7.0.diff`](../patches/in_design/vbd_displacement_on_1.7.0.diff),
sha256 685c333b840ae7a4...); **on** sets `NEWTON_VBD_DISPLACEMENT=1`, **off** does not. Rigs as committed at this
registration: `tools/nwt_contact.py`, `tools/nwt_chain.py`. Warp's CPU device. Measured by Senua AI's `sx_contact`
(`creep`, `chain`, `stop`) and judged by its `rule`.

## The scenes, registered parameters

None of these numbers was used in the probes.

- **S, a spinning body** (13): a 2.1 kg cube of half-size 0.035 m whose box sits 0.025 m along its x from its origin,
  turning at 5 rad/s about z through its centre of mass, 1 m above the ground, no gravity, 1.5 s; on VBD and VBD-ALM;
  at 1.5, 0.3 and 0.075 ms; as released, off and on.
- **C, a free chain** (12): links of 1.0 and 0.8 kg, half-size 0.04 m, the first's centre 0.22 m from its joint, the
  second joint 0.45 m out, the second's centre 0.2 m beyond it, at 0 and 0.5 rad turning at 1.9 and -0.9 rad/s, no
  gravity, 2 s; on VBD as released, off and on, and on Featherstone as released; at 1.5, 0.375 and 0.09375 ms; the
  first joint at the world's origin, 10 m and 100 m along x.
- **H, contacts**: on VBD-ALM, a hold: a 1.4 kg cube of half-size 0.04 m resting on the ground at friction 0.6, pushed
  sideways from 0.4 s at 4.53 N (55% of its friction's limit), 1.6 s, with Study 17's contact history and sticky
  matching; and a slide: a 1.1 kg cube of half-size 0.045 m sent along the ground at 0.8 m/s at friction 0.45, 0.5 s;
  at 1.5 and 0.075 ms; as released, off and on.

## The rules

Each judged by `sx_contact rule`, from the measured lines, and nowhere else. A chain's departure is its largest
departure from its energy over the play (`energy_largest_drift_ppm`).

| Rule | Statement | Kind |
|---|---|---|
| R1 safe when off | Off, every S, C and H play byte for byte the release's | eq (count) |
| R2 the fault is there | As released, S's centre on VBD-ALM 100 um/s or more from still at 0.075 ms; C at the origin departs further at 0.09375 ms than at 0.375 ms; C 10 m out departs at 0.375 ms 5 times as far as at the origin or more | ge, ge, ge |
| R3 the centre still | On, S's centre within 3 um/s of still at every step on both paths | all_in |
| R4 the chain's loss falls with the step | On, C at the origin departs at each step at most 1 in 2.5 as far as at the step 4 times longer | all_ge |
| R5 where the chain is | On, C 10 m out departs within 1 in 3 of C at the origin at every step; C 100 m out departs no further at each step than at the step 4 times longer | all_within, all_ge |
| R6 contacts kept | On, the hold within 10 um/s of still at both steps; the slide within 1 in 100 of the release's at both | all_in, all_within |
| R7 a number | Every play on a number throughout | all_eq |

Reported, not ruled: every reading, Featherstone's at each place and step, the chain's momentum (about the world's
origin, so not the chain's away from it), the hold and the slide as released.

## What it decides

When R1 to R7 hold, issue 13 is fixed and validated on VBD-ALM (and VBD) by the displacement patch, and with Study 9
on the MuJoCo solver, issue 13 is resolved; and issue 12's VBD part, the growth of its loss as the step shrinks from
its 32-bit poses, is fixed and validated, what is left of its loss being the scheme's own first-order error, which the
step bounds. A rule that fails is reported as failed, and the part stays open.
