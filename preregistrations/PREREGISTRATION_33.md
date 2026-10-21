# Thirty-third pre-registration: a fast body kept from passing through a thin slab

Registered 21 October 2026, after run 060 and the host checks that followed it. Registered before any play of this
registration existed. To be played once, as run 136, on Newton 1.7.0.

## The question

Issue 20's tunnelling (N12): a body goes through a thin slab wherever one step carries it past it whole, and Newton's
speculative contacts, as run 060 turned them on, changed nothing. The host checks after it traced why. Newton's
collision pipeline already writes the falling cube's contacts a step ahead within its own contact gap (0.1 m by
default), so run 060's cubes, all 5 cm above the slab, were caught with or without speculative contacts; what let them
through is the solve. XPBD at its default two iterations corrects only part of a step's deep predicted overlap, and the
next step's collision finds the cube past the slab's middle; at 64 iterations, with speculative contacts for a cube
further away than the gap, it stops on the slab. SemiImplicit's and Featherstone's penalty contact acts on no contact
that is still apart, so a contact found apart at the step's start gets nothing however fast it closes. Senua AI's
speculative normal patch, with `NEWTON_SPECULATIVE_NORMAL=1`, gives such a contact, in the record's Coulomb pass after
the step's integration, the normal impulse that keeps it apart at the step's end, its closing speed cut to d / dt
(Catto, speculative contacts, GDC 2013), never pulling. On a cube, slab, speeds and steps no run used: does each of
XPBD, SemiImplicit and Featherstone keep the cube from passing through?

## The right answers

- A body falling onto a slab does not pass through it, however thin the slab and however far one step carries the body.
- Nothing else changes: a slide and a hold play as before.

## Engines and rigs

Newton 1.7.0 from PyPI (`newton==1.7.0`, Warp 1.18.0, MuJoCo Warp 3.15.0) as released, Study 7's environment, and
engines made from it by this run's `setup_engine.sh`, all no fuzz, first on the path: **chain**, the base environment's
Newton with the record's validated friction chains (Studies 15 and 18), their switches set, XPBD at 64 iterations; and
the chain with Senua AI's speculative normal patch
([`semi_speculative_normal_on_chain.diff`](../patches/in_design/semi_speculative_normal_on_chain.diff), sha256
d5c8189d5943cac5...): **off** without `NEWTON_SPECULATIVE_NORMAL`, **on** with it set to 1. Speculative contacts are
Newton's own: `CollisionPipeline(speculative_contact_gap_max=1)`, the step's dt passed to `collide`. **The
configuration**: XPBD with the chain at 64 iterations and speculative contacts; SemiImplicit and Featherstone on, with
speculative contacts. Rig as committed at this registration: `tools/nwt_contact.py` (its `slab`, `vz0`, `specgap`).
Warp's CPU device. Measured by Senua AI's `sx_contact` (`final`: the cube's lowest face's height at the end; `stop`,
`creep`) and judged by its `rule`.

## The scenes, registered parameters

None of these numbers was used in a run. A 0.8 kg cube of half-size 0.04 m, friction 0.5, onto a static slab 6 mm
thick, its top at the plane's height, 0.1 s, at 4 ms and 2 ms:

- **inside the gap**: 4 cm above the slab, falling at 70 m/s (a step carries it 280 and 140 mm).
- **beyond the gap**: 0.3 m above the slab, falling at 120 m/s (480 and 240 mm).

As released (each solver's defaults, no speculative contacts), with the configuration, and off (the patch's tree, the
switch unset, speculative contacts on) beside the chain with speculative contacts. And, for what else might change, a
slide (sent at 1 m/s on the plane, 0.6 s) and a hold (pushed at 0.6 of its friction limit, 2.352 N, from 0.3 s, 1.2 s),
at 0.5 ms, with the configuration and with the chain without speculative contacts. The MuJoCo solver, as released and
with speculative contacts, reported.

## The rules

Each judged by `sx_contact rule`, from the measured lines, and nowhere else. "The three" are XPBD, SemiImplicit and
Featherstone. "Through" is the cube's lowest face below the slab's bottom (6 mm under its top) at the end; "kept" is it
at or above the slab's middle (3 mm under its top).

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

When R1 to R5 hold, issue 20's tunnelling is fixed: on XPBD by Newton's own configuration (64 iterations and speculative
contacts), on SemiImplicit and Featherstone by Senua AI's speculative normal patch with speculative contacts. Issue 20's
force calibration, grasps and point clouds, which need a GPU, stay unplayed. A rule that fails is reported as failed,
and the tunnelling stays open.
