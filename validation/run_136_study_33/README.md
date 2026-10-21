# Run 136: Study 33, a fast body kept from passing through a thin slab (issue 20's tunnelling)

The thirty-third registered study ([`PREREGISTRATION_33.md`](../../preregistrations/PREREGISTRATION_33.md)), played once
with [`play.sh`](play.sh) on the engines made by [`setup_engine.sh`](setup_engine.sh): Newton 1.7.0 as released; with
the record's validated friction chains (`chain`); and the chain with Senua AI's speculative normal patch
([`semi_speculative_normal_on_chain.diff`](../../patches/in_design/semi_speculative_normal_on_chain.diff), sha256
d5c8189d5943cac5...), its switch unset (`off`) and set (`on`).

After run 060 (speculative contacts as turned on changed nothing): on the host, Newton's pipeline already writes a cube's
contacts a step ahead within its contact gap (0.1 m), so run 060's cubes, 5 cm above the slab, were caught with or
without speculative contacts; XPBD at its default two iterations corrects only part of a step's deep overlap and the
next collision finds the cube past the slab's middle (at 64 iterations it stops on the slab at 60 and 150 m/s, and with
speculative contacts from 0.4 m above); SemiImplicit's and Featherstone's penalty contact acts on no contact still
apart. The patch's switch `NEWTON_SPECULATIVE_NORMAL=1` records a contact the force pass finds still apart and, in the
record's Coulomb pass after the step's integration, gives it the normal impulse that keeps it apart at the step's end
(its closing speed cut to d / dt, never pulling), shared among the body's such contacts, on its total over the sweeps.
A second form that also closed touching contacts by impulse was tried on the host and dropped: with the penalty spring
left almost no depth the Coulomb pass's friction bound, the penalty's normal force, fell to nearly nothing.

## What it found

Played 20 October 2026 (UTC) on the second x86-64 host (`started.txt`, `finished.txt`); the measured lines in
`measured.txt`, the rules in [`rules.txt`](rules.txt). **6 of 8 rule lines held; R4's SemiImplicit and Featherstone
slides failed.**

| The cube's lowest face at the end, mm (the slab 6 mm, its top at 0) | in the gap, 4 ms | in, 2 ms | beyond, 4 ms | beyond, 2 ms |
|---|---|---|---|---|
| As released, XPBD, SemiImplicit, Featherstone | -4,850 to -7,011 | -5,209 to -7,010 | -11,751 | -11,750 |
| XPBD, the configuration | 0.000 | 0.000 | 0.000 | 0.000 |
| SemiImplicit, the configuration | +913 (thrown up at 9.1 m/s) | -0.70 | +7,153 (thrown up) | -0.72 |
| Featherstone, the configuration | +913 (thrown up at 9.1 m/s) | -0.72 | -0.72 | -0.72 |
| The MuJoCo solver, as released and with speculative contacts (reported) | -7,011 | -7,010 | -11,751 | -11,750 |

- R1 held (8 of 8 plays off byte for byte the chain's with speculative contacts). R2 held: as released all three go
  through in every scene at both steps. **R3 held: with the configuration none goes through**: XPBD stops on the slab
  (7 nm, at rest), SemiImplicit and Featherstone rest on it except where a 4 ms step brings the cube to it at speed,
  where the penalty contact throws it back up (as the record's F5 and F11 bounce). R4's XPBD slide held (byte for byte)
  and its holds held (6, 0, 0 um/s).
- **R4 failed on SemiImplicit and Featherstone's slides**: 102,681 and 102,684 um with the patch against 102,181 and
  102,183 with the chain (Coulomb's 102,041), 1 in 204 longer against the registered 1 in 1,000. Not traced here; a
  likely cause is the patch's normal impulse at a sliding box's lightly loaded corners, which the Coulomb pass's friction
  bound (mu times the penalty's normal impulse) does not count, so those corners carry load without friction.
- The MuJoCo solver goes through with or without speculative contacts, the same bytes: its contact acts on no contact
  still apart.
- By the registration issue 20's tunnelling stays open: fixed on XPBD by Newton's own configuration in every scene
  played; on SemiImplicit and Featherstone the patch keeps the cube from passing through, and moves a slide by 0.5%.
- After the run, not registered (host checks on the second x86-64 host): a second form whose Coulomb pass counts the
  patch's normal impulse in each contact's friction cone, and gives a contact still apart that the pass holds friction
  as any other, plays SemiImplicit's and Featherstone's slide and hold byte for byte as the chain does and keeps
  SemiImplicit's cube from passing through, but on Featherstone lets it through (from 0.4 m at 150 m/s it ends 9.3 m
  below: the first sweep tilts the cube until one contact is left). Counted in the sharing but given no friction
  (Featherstone kept, as the first form), or given friction but not counted (Featherstone diverges at its first step),
  it is the friction on a contact still apart that Featherstone's joint-space pass does not take. Not registered;
  another form is needed for Featherstone.
- Also after the run (the implicit MPM solver, #4712's leak): a swept form of `project_outside` (each particle's step
  tested from its start, `x - v dt`, against the collider seen from there) cuts the cup's leak but does not close it
  (no margin, a 14 mm voxel at 12 substeps: 706 particles out to 459; 8 mm at 8 substeps: 731 to 529): most of what
  crosses a wall is carried across by the grid, not caught at the particles.
