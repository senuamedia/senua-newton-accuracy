# Eleventh pre-registration: MuJoCo's recommended configuration through Newton, the MuJoCo solver's CPU path, and Featherstone's limit kept from pulling

Registered 20 October 2026, after the design probes of runs 066, 067, 068, 069 and 070. Registered before any play of
this registration existed. To be played once, as run 072, on Newton 1.7.0.

## The question

Four open issues each have a fix or an answer measured in a design probe but never held to rules registered in
advance. On scenes and steps no probe used: is each fault there as released, and is it gone with its fix?

| Issue | The fault | The fix | Measured in |
|---|---|---|---|
| 15 | MuJoCo's recommended configuration (the elliptic cone with noslip) cannot be set through Newton | Senua AI's noslip patch, second form ([`mujoco_noslip_v2_on_1.7.0.diff`](../patches/in_design/mujoco_noslip_v2_on_1.7.0.diff)), on the solver's CPU path (MuJoCo Warp refuses noslip) | runs 067, 069 |
| 6, the MuJoCo solver's part | A load inside the friction limit is not held | The same configuration | run 069 |
| 24 | The MuJoCo solver's CPU path drops contacts and discards applied forces (N9) | None needed if the fault is not there on 1.7.0 | run 066 |
| 16, Featherstone's part | Featherstone's joint limit pulls the joint back as it leaves | Senua AI's Featherstone limit patch, its first form, `NEWTON_FEATHERSTONE_LIMIT=1` ([`featherstone_limit_v2_on_1.7.0.diff`](../patches/in_design/featherstone_limit_v2_on_1.7.0.diff), which holds all three forms) | runs 068, 070 |

## The right answers

- **A load inside the friction limit is held**: a cube pushed with less force than its friction can hold does not
  slide (Coulomb's law), and a slide or a weight is not changed by what holds it.
- **The CPU path plays a scene as the Warp path does**: the same contacts, the same applied forces.
- **A joint limit kept from pulling** (the linear spring-dashpot that never pulls, Schwager and Poeschel, Granular
  Matter 9, 465-469, 2007): an arm striking it keeps the speed fraction e(z) = exp(-(z / sqrt(1 - z^2)) (pi -
  arctan(2 z sqrt(1 - z^2) / (1 - 2 z^2)))), z = kd / (2 sqrt(ke I)) the limit's damping ratio, and an arm released
  level onto a limit at -L turns back at -arcsin((1 - e^2) sin L) (run 042's closed form, which gives its -0.815 rad).

## Engines and rigs

Newton 1.7.0 from PyPI (`newton==1.7.0`, Warp 1.18.0, MuJoCo Warp 3.15.0, MuJoCo 3.15.0) as released, Study 7's
environment, and two engines made from it by this run's `setup_engine.sh`, each the base environment's Newton with one
diff applied (no fuzz), first on the path: the noslip patch's second form; the Featherstone limit patch. Rigs as
committed at this registration: `tools/nwt_contact.py`, `tools/nwt_joint.py`. Warp's CPU device. Measured by Senua
AI's `sx_contact` (`creep`, `stop`, `rest`, `final`, `swing`) and judged by its `rule`.

## The scenes, registered parameters

None of these numbers was used in the probes.

- **E1, a hold** (15, 6): a 1.5 kg cube of half-size 0.04 m on the ground, friction 0.6, pushed by 6.174 N (0.7 of what
  friction holds) from 0.4 s, 1.6 s; the MuJoCo solver's CPU path, the elliptic cone, without noslip and with 5 noslip
  iterations; at 1 and 4 ms. The creep is the mean speed over the run's second half; the right answer 0.
- **E2, a slide**: the same cube from 0.8 m/s on the ground, friction 0.6, 1 s, CPU path, elliptic cone, without and
  with noslip, at 1 and 4 ms.
- **E3, a drop**: a 0.8 kg cube of half-size 0.03 m from 50 mm, friction 0.3, 1 s; CPU path, elliptic cone with noslip,
  at 1 and 4 ms: the ground's mean force over the second half, the weight 7,840 mN.
- **E4, the CPU path beside the Warp path** (24), Newton's default MuJoCo configuration, at 1 and 4 ms: E3's drop
  without noslip; the 0.8 kg cube with no gravity, 1 m up, pushed by 0.04 N from rest, 1.2 s: **60,000 um/s** at the
  end; an arm of 1.6 kg, half-size 0.04 m, centre 0.35 m out, under 0.7 N m from rest, 0.04 s.
- **E5, a strike** (16): an arm of half-size 0.04 m, centre 0.35 m out, released level under gravity onto its lower
  limit at -0.8 rad (limits -0.8 and 0.8, Newton's limit_ke 1e4 and limit_kd 10), 2 s, at 0.3 kg and 2 kg (z = 0.260
  and 0.101), on Featherstone as released, with the patch's switch unset, and at `=1`, at 0.2 and 0.05 ms. Kept from
  pulling it turns back at **-0.572 rad** (0.3 kg) and **-0.327 rad** (2 kg).

## The rules

Each judged by `sx_contact rule`, from the measured lines, and nowhere else.

| Rule | Statement | Kind |
|---|---|---|
| R1 safe when off (15) | With noslip unset, E1's two files without noslip on the patch's tree byte for byte the release's | eq (count) |
| R2 the fault is there (15, 6) | Without noslip the hold creeps at least 100 um/s, at both steps | all_ge |
| R3 held (15, 6) | With noslip the creep within 10 um/s of 0, at both steps | all_in |
| R4 the slide kept | With noslip the slide within 1 in 100 of the slide without, at both steps | within |
| R5 the weight kept | With noslip the drop's ground force within 1 in 100 of 7,840 mN, at both steps | all_within |
| R6 the CPU path's contacts (24) | The CPU path's drop: its ground force within 1 in 100 of the Warp path's, at both steps | within |
| R7 the CPU path's forces (24) | The push: both paths within 1 in 1,000 of 60,000 um/s, at both steps | all_within |
| R8 the CPU path's joint force (24) | The torque: the CPU path's angle within 1 in 100 of the Warp path's, at both steps | within |
| R9 the CPU path plays (24) | Every CPU-path play a number throughout | all_eq |
| R10 safe when off (16) | With the switch unset, E5's four plays byte for byte the release's | eq (count) |
| R11 the fault is there (16) | As released the arm turns back more than 0.01 rad lower than the closed form, at both masses and steps | all_le |
| R12 kept from pulling (16) | At `=1` within 0.02 rad of the closed form, at both masses and steps | all_in |

Reported, not ruled: more than one world on the CPU path (not played: the CPU path takes one, by its own code),
SemiImplicit's limit (which the patch does not change), and every reading at every step.

## What it decides

Issue 15 is fixed on the MuJoCo solver's CPU path by the noslip patch with the elliptic cone, and the MuJoCo solver's
part of issue 6 with it, when R1 to R5 hold; on the Warp path issue 15 waits on MuJoCo Warp's noslip. Issue 24's
reported faults are not there on Newton 1.7.0 when R6 to R9 hold. Issue 16 is fixed on Featherstone by the limit
patch's first form when R10 to R12 hold; its SemiImplicit part stays open. A rule that fails is reported as failed, and
its issue stays open.
