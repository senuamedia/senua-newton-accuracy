# Third pre-registration: SemiImplicit's and Featherstone's normal contact, damped in both phases and kept from pulling

Registered 15 October 2026, after design probes (runs 017, 020 and 021). Registered before any play of this
registration existed. To be played once, as run 033.

## The question

SemiImplicit's and Featherstone's body contact damps the normal only while the contact closes, so a body dropped with
no restitution rebounds, more as the step shrinks (F11; runs 007, 017). The patch in design
`patches/in_design/contact_damping_no_pull.diff`, applied on top of Study 1's validated `unit_friction_direction.diff`,
makes the normal force the linear spring-dashpot in both phases kept from pulling, min(ke d + kd vn, 0), with Newton's
own ke and kd (Schwager and Poeschel, Granular Matter 9, 465-469, 2007). On scenes the probes did not use, inside the
range where Newton's explicit integration can carry it: is the rebound there with Study 1's patch alone, is it gone
with this patch, does nothing else get worse, and with the switches unset is the patched Newton the release byte for
byte?

## Where the rules apply, and why

Runs 020 and 021 found that two of the probe checks failed outside the patch's reach, in Newton's explicit integration
of the contact, which the patch does not change. This registration states its rules where that integration is inside
its limits, and plays and reports the steps outside them. Both limits are derived, not read from the probes' numbers
(run 021):

- **The normal.** A body's speed into the ground decays at c_n = 4 kd / m on four corners. Integrated explicitly, a
  damper gives v' = v (1 - h c_n): it never turns the speed round while h c_n is at most 1 (its monotone limit), and is
  stable only while h c_n < 2 (Belytschko, Liu and Moran, Nonlinear Finite Elements for Continua and Structures, Wiley
  2000, section 6.3). Above 1 the damper itself can throw the body off in its first contact step, before the contact
  opens, where the patch acts. **The drop's rules apply where 4 kd h / m is at most 1.**
- **Friction.** On a cube the corners' slip decays at c_t = 4 kf (1 / m + r^2 / I) = 10 kf / m. **The hold's rule
  applies where 10 kf h / m is at most 1**, the same monotone criterion; run 021 found the hold's creep not steady at
  h c_t = 1.8 and above.

With Newton's defaults (ke 2,500 N/m, kd 100 N s/m, kf 1,000 N s/m per contact) and this study's 3 kg cube, the normal's
limit is h at most 7.5 ms, and friction's 0.3 ms.

## Engines and arms

- **stock**: Newton 1.6.1 from PyPI with run 001's environment.
- **patched**: Newton v1.6.1 from source (commit 713fecd) with `unit_friction_direction.diff` (sha256
  dd4042afa2894458...) and `contact_damping_no_pull.diff` (sha256 15d7489e80b018ab...) applied, in its own environment,
  every dependency as stock's (run 020's).

| Arm | Engine | `NEWTON_UNIT_FRICTION_DIRECTION` | `NEWTON_CONTACT_DAMPING_NO_PULL` |
|---|---|---|---|
| stock | stock | unset | unset |
| off | patched | unset | unset |
| unit | patched | 1 | unset |
| on | patched | 1 | 1 |

Rig as committed at this registration: `tools/nwt_contact.py`, SemiImplicit and Featherstone, their own defaults
otherwise. Measured by Senua AI's `sx_contact` (`bounce`, `creep`, `rest`, `pull`) and judged by its `rule`. Warp's CPU
device.

## The scenes, registered parameters

None of these numbers was used in the probes. A cube of 3 kg, half-size 0.06 m.

- **The drop**: from 70 mm, friction 0, 0.5 s. Right answer with no restitution: no rebound. Ruled at 6, 3, 1.5, 0.75
  and 0.375 ms (4 kd h / m = 0.8 to 0.05). Played and reported, not ruled: 12 ms (1.6) and 15 ms (2.0).
- **The slide**: on the ground at 1.2 m/s, friction 0.35, 0.3 s (it stops at 0.35 s). Right answer: friction over the
  normal force 3,500 per 10,000. At 1.5 and 0.375 ms.
- **The rest**: on the ground, friction 0.35, 1 s. Right answer: the ground carries the weight, 29,400 mN. At 1.5 and
  0.375 ms.
- **The lift**: on the ground, lifted with three times the weight (88.2 N) from 0.3 s, 0.4 s. Right answer: the ground
  never pulls. At 1.5 and 0.375 ms.
- **The hold**: on the ground, friction 0.45, pushed along x with 7.938 N (0.6 of what friction holds) from 0.4 s,
  1.5 s. Ruled at 0.2 and 0.1 ms (10 kf h / m = 0.67 and 0.33), where the creep is the viscous friction law's own:
  the push over four corners' kf, 1,985 um/s (the right answer of Coulomb's law, 0, is F4, which neither patch
  addresses). Played and reported, not ruled: 0.75 ms (2.5).
- **Other solvers**: the drop at 1.5 ms on XPBD, stock and with both switches set.

## The rules

Each judged by `sx_contact rule`, from the measured lines, and nowhere else.

| Rule | Statement | Kind |
|---|---|---|
| R1 safe when off | Every file the off arm plays is byte-identical to the stock arm's | eq (identical files, files) |
| R2 the rebound is there | unit, both solvers: the drop rebounds at least 20 per 10,000 of its height at 0.75 and 0.375 ms | all_ge |
| R3 no rebound | on, both solvers: the drop rebounds at most 10 per 10,000 at the five ruled steps | all_le |
| R4 the slide | on, both solvers: friction over the normal force within 1 in 100 of 3,500 at both steps | all_within |
| R5 the rest | on, both solvers: the ground's mean force within 1 in 100 of 29,400 mN at both steps | all_within |
| R6 the lift | on, both solvers: the ground's lowest force 0 or more at both steps | all_ge |
| R7 the hold | on, both solvers: the mean speed within 1 in 100 of 1,985 um/s at 0.2 and 0.1 ms | all_within |
| R8 other solvers | XPBD's drop with both switches set is byte-identical to stock's | eq |
| R9 nothing blows up | unit and on: no play's state stops being a number | eq (plays with nan_at_step, 0) |

The study holds if every rule holds. A rule that fails is reported as failed, with its numbers, and the patch stays in
design.

Reported, not deciding: the drops at 12 and 15 ms and the hold at 0.75 ms in every arm, with the reason above; the
unit arm's slide, rest, lift and hold.

## The runner and its dry run

`validation/run_033_study_03/play.sh`, committed with this registration. Before the study it is played once with
`DRY=1`: the on arm only, with throwaway parameters (the suite's 2 kg cube, half-size 0.04 m, at 5 ms and 1.25 ms),
into `dry/`, only to check that it runs to the end and writes every measured line; no rule is read from it.
