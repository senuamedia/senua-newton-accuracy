# Thirty-fifth pre-registration: a fast body kept from passing through a thin slab, every contact given its normal

Registered 21 October 2026, after Study 34 (run 137) and the host checks that followed it. Registered before any play of
this registration existed. To be played once, as run 138, on Newton 1.7.0.

## The question

Issue 20's tunnelling (N12): a body goes through a thin slab wherever one step carries it past it whole. With Newton's
own configuration XPBD kept the cube on the slab in every scene of Studies 33 and 34. On SemiImplicit and Featherstone,
Senua AI's speculative normal patch (a normal impulse in the record's Coulomb pass after the step, keeping a contact
still apart from closing past the surface within the step) kept the cube in Study 33 but moved a slide whose cube starts
touching (its weight carried for a step without friction), and its third form, on contacts strictly apart, kept the
slides but let a cube that lands touching at speed through (Study 34). The host checks that followed found what each
case needs and one fault more:

- A contact the pass holds must take friction on that impulse: the cone counts the patch's normal impulse beside the
  penalty's (the second form).
- Featherstone's pass solves its impulses with the joint-space inertia built where the step left the joints; the normal
  impulse moves a fast body back within the pass (40 cm), and a rotation through that offset reads as slip, friction
  answering with more rotation sweep after sweep (traced: 0.001 to 149 rad/s over 48 sweeps of one step). Rebuilt where
  the joints are each sweep, it converges.
- A contact that lands touching at speed, or a hair inside, must be kept from closing further too: the pass gives a
  closed contact the impulse that stops its closing (as if touching), never pulling.

The patch's fourth form ([`semi_speculative_normal_v4_on_chain.diff`](../patches/in_design/semi_speculative_normal_v4_on_chain.diff),
sha256 97407bbb600c175f...) does all three. On the host it kept every drop of Studies 33 and 34 on both solvers, most at
rest on the slab, and held the holds; the slides stop dead and run 0.24 to 0.38% shorter than the chain's, within 0.25%
of Coulomb's distance. Because it changes how a contact stops, this registration rules the slides against Coulomb's
distance, the record's bar for a slide (Study 18), not against the chain. On a cube, slab, speeds and steps no run used:
does each of XPBD, SemiImplicit and Featherstone keep the cube from passing through, the slide and the hold right?

## The right answers

- A body falling onto a slab does not pass through it, however thin the slab and however far one step carries the body.
- A slide stops at Coulomb's distance; a cube pushed below its friction limit stays still.

## Engines and rigs

Newton 1.7.0 from PyPI (`newton==1.7.0`, Warp 1.18.0, MuJoCo Warp 3.15.0) as released, Study 7's environment, and
engines made from it by this run's `setup_engine.sh`, all no fuzz, first on the path: **chain**, the base environment's
Newton with the record's validated friction chains (Studies 15 and 18), their switches set, XPBD at 64 iterations; and
the chain with the patch's fourth form: **off** without `NEWTON_SPECULATIVE_NORMAL`, **on** with it set to 1.
Speculative contacts are Newton's own: `CollisionPipeline(speculative_contact_gap_max=1)`, the step's dt passed to
`collide`. **The configuration**: XPBD with the chain at 64 iterations and speculative contacts; SemiImplicit and
Featherstone on, with speculative contacts. Rig as committed at this registration: `tools/nwt_contact.py` (its `slab`,
`vz0`, `specgap`). Warp's CPU device. Measured by Senua AI's `sx_contact` (`final`: the cube's lowest face's height at
the end; `stop`, `creep`) and judged by its `rule`.

## The scenes, registered parameters

None of these numbers was used in a run. A 0.7 kg cube of half-size 0.035 m, friction 0.4, onto a static slab 4 mm
thick, its top at the plane's height, 0.1 s, at 3 ms and 1 ms:

- **inside the gap**: 6 cm above the slab, falling at 90 m/s (a step carries it 270 and 90 mm).
- **beyond the gap**: 0.35 m above the slab, falling at 110 m/s (330 and 110 mm).

As released (each solver's defaults, no speculative contacts), with the configuration, and off (the patch's tree, the
switch unset, speculative contacts on) beside the chain with speculative contacts. And a slide (sent at 1.1 m/s on the
plane, 0.6 s; Coulomb's distance 154,337 um) and a hold (pushed at 0.6 of its friction limit, 1.6464 N, from 0.3 s, 1.2
s), at 0.5 ms, with the configuration and with the chain without speculative contacts. The MuJoCo solver, as released
and with speculative contacts, reported.

## The rules

Each judged by `sx_contact rule`, from the measured lines, and nowhere else. "The three" are XPBD, SemiImplicit and
Featherstone. "Through" is the cube's lowest face below the slab's bottom (4 mm under its top) at the end; "kept" is it
at or above the slab's middle (2 mm under its top).

| Rule | Statement | Kind |
|---|---|---|
| R1 safe when off | Off, every SemiImplicit and Featherstone play byte for byte the chain's with speculative contacts | eq (count) |
| R2 the fault is there | As released, each of the three through in both scenes at both steps | all_le |
| R3 kept | With the configuration, each of the three kept in both scenes at both steps | all_ge |
| R4 the slide and the hold right | With the configuration, the three's slides within 1 in 100 of Coulomb's distance, and their holds within 10 um/s of rest | all_within, all_in |
| R5 a number | Every play on a number throughout | all_eq |

Reported, not ruled: every reading, the cube's speed at the end (a cube kept may be thrown back up), the slides with the
chain, and the MuJoCo solver.

## What it decides

When R1 to R5 hold, issue 20's tunnelling is fixed on Newton's own solvers: on XPBD by Newton's own configuration (64
iterations and speculative contacts), on SemiImplicit and Featherstone by Senua AI's speculative normal patch with
speculative contacts. The MuJoCo solver, whose MuJoCo contact acts on no contact still apart, is reported. Issue 20's
force calibration, grasps and point clouds, which need a GPU, stay unplayed. A rule that fails is reported as failed,
and the tunnelling stays open.
