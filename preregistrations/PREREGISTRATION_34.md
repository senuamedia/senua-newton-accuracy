# Thirty-fourth pre-registration: a fast body kept from passing through a thin slab, the patch on contacts strictly apart

Registered 21 October 2026, after Study 33 (run 136) and the host checks that followed it. Registered before any play of
this registration existed. To be played once, as run 137, on Newton 1.7.0.

## The question

Issue 20's tunnelling (N12): a body goes through a thin slab wherever one step carries it past it whole. Study 33 (6 of 8)
found none through with Newton's own configuration on XPBD (64 iterations and speculative contacts) and with Senua AI's
speculative normal patch on SemiImplicit and Featherstone, but the patch moved those two solvers' slide by 1 in 204
against the registered 1 in 1,000. The host checks after it traced the move: the slide's cube starts exactly touching the
plane (separation 0), the patch's first form took a contact at separation 0 as still apart, and its normal impulse
carried the cube's weight for the first step with no friction, one step's friction impulse missing (the slide 0.5 mm
long, as measured). A contact exactly touching is not apart, and the penalty contact catches a shallow one at the next
step; the patch's third form ([`semi_speculative_normal_v3_on_chain.diff`](../patches/in_design/semi_speculative_normal_v3_on_chain.diff),
sha256 e9678069462fb759...) acts on contacts strictly apart (separation above 0) and is otherwise the first. On the host
it kept every drop as the first form did and played the slide and the hold byte for byte as the chain does. (Its second
form, counting the patch's impulse in the friction cone, let Featherstone's cube through and is not registered.) On a
cube, slab, speeds and steps no run used: does each of XPBD, SemiImplicit and Featherstone keep the cube from passing
through, with nothing else changed?

## The right answers

- A body falling onto a slab does not pass through it, however thin the slab and however far one step carries the body.
- Nothing else changes: a slide and a hold play as before.

## Engines and rigs

Newton 1.7.0 from PyPI (`newton==1.7.0`, Warp 1.18.0, MuJoCo Warp 3.15.0) as released, Study 7's environment, and
engines made from it by this run's `setup_engine.sh`, all no fuzz, first on the path: **chain**, the base environment's
Newton with the record's validated friction chains (Studies 15 and 18), their switches set, XPBD at 64 iterations; and
the chain with the patch's third form: **off** without `NEWTON_SPECULATIVE_NORMAL`, **on** with it set to 1.
Speculative contacts are Newton's own: `CollisionPipeline(speculative_contact_gap_max=1)`, the step's dt passed to
`collide`. **The configuration**: XPBD with the chain at 64 iterations and speculative contacts; SemiImplicit and
Featherstone on, with speculative contacts. Rig as committed at this registration: `tools/nwt_contact.py` (its `slab`,
`vz0`, `specgap`). Warp's CPU device. Measured by Senua AI's `sx_contact` (`final`: the cube's lowest face's height at
the end; `stop`, `creep`) and judged by its `rule`.

## The scenes, registered parameters

None of these numbers was used in a run. A 0.9 kg cube of half-size 0.045 m, friction 0.45, onto a static slab 5 mm
thick, its top at the plane's height, 0.1 s, at 4 ms and 1.5 ms:

- **inside the gap**: 5 cm above the slab, falling at 80 m/s (a step carries it 320 and 120 mm).
- **beyond the gap**: 0.25 m above the slab, falling at 100 m/s (400 and 150 mm).

As released (each solver's defaults, no speculative contacts), with the configuration, and off (the patch's tree, the
switch unset, speculative contacts on) beside the chain with speculative contacts. And a slide (sent at 1.2 m/s on the
plane, 0.6 s) and a hold (pushed at 0.6 of its friction limit, 2.3814 N, from 0.3 s, 1.2 s), at 0.5 ms, with the
configuration and with the chain without speculative contacts. The MuJoCo solver, as released and with speculative
contacts, reported.

## The rules

Each judged by `sx_contact rule`, from the measured lines, and nowhere else. "The three" are XPBD, SemiImplicit and
Featherstone. "Through" is the cube's lowest face below the slab's bottom (5 mm under its top) at the end; "kept" is it
at or above the slab's middle (2.5 mm under its top).

| Rule | Statement | Kind |
|---|---|---|
| R1 safe when off | Off, every SemiImplicit and Featherstone play byte for byte the chain's with speculative contacts | eq (count) |
| R2 the fault is there | As released, each of the three through in both scenes at both steps | all_le |
| R3 kept | With the configuration, each of the three kept in both scenes at both steps | all_ge |
| R4 nothing else changes | With the configuration, the three's slides within 1 in 1,000 of their slides with the chain, and their holds within 10 um/s of rest | within, all_in |
| R5 a number | Every play on a number throughout | all_eq |

Reported, not ruled: every reading, the cube's speed at the end (a cube kept may be thrown back up), and the MuJoCo
solver.

## What it decides

When R1 to R5 hold, issue 20's tunnelling is fixed on Newton's own solvers: on XPBD by Newton's own configuration (64
iterations and speculative contacts), on SemiImplicit and Featherstone by Senua AI's speculative normal patch with
speculative contacts. The MuJoCo solver, whose MuJoCo contact acts on no contact still apart, is reported. Issue 20's
force calibration, grasps and point clouds, which need a GPU, stay unplayed. A rule that fails is reported as failed,
and the tunnelling stays open.
