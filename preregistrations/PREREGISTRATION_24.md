# Twenty-fourth pre-registration: a light cloth and a box coupled two-way, the feedback the force the cloth exerts

Registered 21 October 2026, after the design probes of runs 112, 116 and 118. Registered before any play of this
registration existed. To be played once, as run 119, on Newton 1.7.0.

## The question

Issue 21 (N13), newton-physics/newton #4698: a light VBD cloth coupled two-way through `SolverCoupledProxy` to a box
the MuJoCo solver plays, the box a lagged proxy in VBD. (A) The wrench VBD harvests for the box is the contact penalty
of its last iterate, 10 to 170 times the force the cloth exerts (run 112); (B) the generic rewind takes the lagged
feedback off a proxy whose harvest does not add it back, pushing it into the cloth (#4698). Senua AI's VBD proxy
coupling patch in its third form, at 2: the proxy rewound by its gravity only (B), and the harvest as the cloth
received it (A): each deformable's unbalanced force at the final iterate, summed over its particles, taken off its
contacts in the share of each contact's force along it, or alike among its contact candidates where none lies along
it, summed over the coupled step's substeps; a deformable that pins hold keeps the explicit harvest. On a cloth on a
box, a cloth on a tall box, a cloth thrown at a free box and a box dropped onto a held cloth, none of whose numbers a
probe used: is the feedback the force the cloth exerts?

## The right answers

- The wrench fed back to the box is the force the cloth exerts on it: on a box the cloth alone touches, at rest, what
  the cloth receives, its weight.
- A box held by the ground under a cloth at rest stays at rest.
- With nothing outside acting on a cloth and a box, their momentum stays what it was.
- A box dropped onto a held cloth that does not damp cannot move faster than it landed, and the cloth carries its
  weight.

## Engines and rigs

Newton 1.7.0 from PyPI (`newton==1.7.0`, Warp 1.18.0, MuJoCo Warp 3.15.0) as released, Study 7's environment, and one
engine made from it by this run's `setup_engine.sh`: the base environment's Newton with Senua AI's VBD proxy coupling
patch's third form applied (no fuzz), first on the path
([`vbd_proxy_coupling_v3_on_1.7.0.diff`](../patches/in_design/vbd_proxy_coupling_v3_on_1.7.0.diff), sha256
77cb8f3f662442d4...); **p1** sets `NEWTON_VBD_PROXY_COUPLING=1`, **p2** sets it to 2, **off** sets nothing. Rig as
committed at this registration: `tools/nwt_cloth_proxy.py` (its box's mass the body's whole mass: the given mass
added to the shape's at Newton's default density). Warp's CPU device; a 4 ms coupled step of two 2 ms substeps on each
side. Measured by Senua AI's `sx_contact` (`rest`, `stop`, `pairg`) on the rig's CONTACT files and judged by its
`rule`.

## The scenes, registered parameters

None of these numbers was used in the probes. The cloth 0.3 m square of 21 x 21 vertices as #4698's; VBD at 15 and 50
iterations; as released, off, p1 and p2.

- **R, a cloth on a box**: a 60 g cloth dropped from 5 cm onto a box of half-sizes 0.09 and 0.03 m with 0.3 kg added
  (2.244 kg), resting on the ground, two-way, 0.6 s.
- **T, a cloth on a tall box**: the same cloth onto a box of half-sizes 0.09 and 0.09 m with 0.3 kg added (6.132 kg),
  whose top the cloth's corners cannot hang down from to the ground; one-way (the feedback recorded, then zeroed) and
  two-way, 0.6 s.
- **W, a throw**: no gravity and no ground; a 50 g cloth sent at 0.7 m/s at #4698's box at rest (2.5 kg), two-way,
  0.3 s.
- **H, a hammock**: a 50 g cloth 0.3 m up, held along its two x edges; a box of half-sizes 0.04 and 0.02 m with 0.15 kg
  added (0.406 kg, weight 3,983 mN) dropped onto it from 3 cm (landing at 767 mm/s), two-way, 2 s.

## The rules

Each judged by `sx_contact rule`, from the measured lines, and nowhere else. "Over the last third" and "over the
second half" are of the play's coupled steps; a box's speed is its velocity up or down (`stop`'s largest speed over the
last third on the box's file); the feedback and the cloth's force are `rest`'s means over the second half.

| Rule | Statement | Kind |
|---|---|---|
| R1 safe when off | Off, every play byte for byte the release's | eq (count) |
| R2 the fault is there | As released, T one-way: the feedback 10 times the force the cloth receives or more, at both counts; W: the momentum at the end twice the cloth's at the start or more, at both counts | ge |
| R3 the feedback the cloth's force | At p2, T one-way: the feedback within 1 in 20 of the force the cloth receives, at both counts | within |
| R4 the box at rest | At p2, R and T two-way: the box's speed over the last third 10 um/s or less, at both counts | all_le |
| R5 momentum kept | At p2, W: the momentum at the end within 1 in 50 of the cloth's at the start, at both counts | within |
| R6 the held cloth | At p2, H: the box's speed over the last third no more than its landing speed, and the feedback within 1 in 10 of its weight, at both counts | all_le, within |
| R7 a number | Every play on a number throughout | all_eq |

Reported, not ruled: every reading at p1, R and T one-way, the box's height.

## What it decides

When R1 to R7 hold, #4698's two faults are fixed and validated on 1.7.0 by the patch at 2: the feedback is the force
the cloth exerts, a box under a cloth stays at rest, momentum is kept, and a held cloth carries a box. Issue 21 is then
fixed in its #4698 part; its other report, #4712 (the implicit MPM solver), is its own question. A rule that fails is
reported as failed, and the part stays open.
