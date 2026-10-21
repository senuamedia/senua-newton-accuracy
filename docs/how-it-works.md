# How the Senua AI Robotics Core works on Newton

The Senua AI Robotics Core has four parts: World, the simulator; Body, the real-time layer on a robot; Mind, which
perceives and decides; and Measure, which holds a simulator to the right answer. A deep dive uses Measure. Measure
has two halves: the **known-answer harness**, which holds a physics engine to the answers physics gives on the
smallest scenes that have one, and the **gap instrument**, which reads two recordings of the same motion where there is
no textbook answer. This deep dive used the known-answer harness.

## What is Senua AI's here, and what is Newton's

| Part | Whose | What it does |
|---|---|---|
| Newton v1.6.1, and v1.7.0 from run 052 | NVIDIA, Google DeepMind and Disney Research's, unchanged | The engine under test, installed from PyPI (`newton[sim]==1.6.1`, with Warp 1.18.0 and MuJoCo Warp 3.12.0; `newton==1.7.0`, with MuJoCo Warp 3.15.0, for Study 7 and the runs since), on Warp's CPU device; for the patches, built from its source at the pinned commit (on 1.7.0, the patches rebased in `patches/newton-1.7.0/`) |
| Six of its solvers | Newton's | XPBD, Featherstone, SemiImplicit, the MuJoCo solver (MuJoCo Warp), VBD, and VBD on its coming contact path (`rigid_compliant_alm`), each read separately with its own defaults |
| The rigs (`tools/nwt_contact.py`, `nwt_chain.py`, `nwt_joint.py`, `nwt_rest.py`, `nwt_loop.py`) | Written for this record | Thin adapters on Newton's own Python API, its only API: each builds one scene (a cube; a chain of two arms; one arm on a hinge, under a torque, a drive or a limit; a driven joint at rest, in the reports' own scenes; a loop-closing joint), plays it and writes what the bodies did at every step, in the same plain text format as the other deep dives' rigs. They measure nothing |
| The measuring programs | **Senua AI Robotics Core** | Read a rig's file and hold the motion to its right answer: a bounce, a slide that ends, a hold, an impact. The same program measured SuperDex and MuJoCo, grown with every reader the deep dives have needed, its source as this record's later runs read it in [`measure/`](../measure/README.md) ([the record checked](audit.md)) |
| The rules and the verdicts | **Senua AI Robotics Core** | A study's rules are judged by the measuring programs' `rule` command, from the measured numbers, and nowhere else |
| The suite | The first deep dive's | Ten known-answer contact tests, played here with the same scenes, steps and file names, and read by the first deep dive's own runner |
| The patches (`patches/`) | **Senua AI**, changes to Newton's source | Added kernels, launched only when a patch's switch is set; with it unset, Newton plays byte for byte as released |

## Measurement

Each finding starts on the smallest scene with an answer that does not depend on the time step: a cube dropped,
set down, held below its friction limit, pushed above it, set sliding until it stops, landing at an angle; a flat
plate that cannot tip, set sliding from rest; a body falling freely from different heights. Every scene is played at
several steps and on every solver, and plays are repeated to check that Newton gives the same bytes (run 001: the hold on each solver; run 016: XPBD's whole suite).

## Tracing a finding to its cause

A number is not the end of a finding. For Newton's friction, Senua AI read the contact kernel the two solvers share,
wrote down what its friction law predicts (Coulomb's times |v| / H(v), H Warp's Huber norm), pushed that prediction
with the probe before playing it, and then confirmed it on a plate that cannot tip: 2.2 times Coulomb's near 1 m/s at
the default smoothing, 13 times at a smoothing of 0.1, and a 1 m/s slide stopped in 0.69 mm at 0.01 ([run
004](../validation/run_004_plate/README.md)). For VBD's free fall, the prediction from 32-bit positions (the error
depends on the height a body falls at) was pushed before its plays and confirmed: a body 10 m up does not fall ([run
006](../validation/run_006_vbd_free_fall/README.md)).

## Validation

A finding becomes a claim only through a pre-registered study ([`preregistrations/`](../preregistrations/)): the
question, the arms, the scenes and every rule are written and pushed before any play exists, with numbers the probes
did not use; the study is played once; every rule is judged by the measuring programs. A correction is held to five
checks: **required**, **correct**, **nothing else gets worse**, **safe when off** (Newton byte-identical to the release
with the switch unset) and **the solver keeps converging** (here: no play's state stops being a number).

## Patching

Newton is Python and Warp. A patch here is additive: Newton's own kernel is left as it is, the corrected copy sits in
a new module, and the call sites launch it only when the switch is set. Newton built from its source with the patch
applied and the switch unset plays byte for byte as Newton from PyPI. [The patch](patches.md) and its evidence are
published together.

## What the deep dive does not claim

Nothing here is measured against a real robot, and Newton is played on the CPU only: this deep dive ran no GPU compute,
so its GPU path, which may differ, was not measured.
A known-answer test shows where an engine departs from physics; how much a robot's behaviour depends on it is a
separate measurement, made by reading a recorded machine against its simulation.
