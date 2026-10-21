# Run 118: VBD's proxy coupling, the realized harvest's second form (issue 21, #4698)

Not registered: a design probe, its predictions pushed with [`play.sh`](play.sh) before any play. Newton 1.7.0 from PyPI,
and the same with Senua AI's VBD proxy coupling patch in design, its second form, first on the path
([`vbd_proxy_coupling_v2_on_1.7.0.diff`](../../patches/in_design/vbd_proxy_coupling_v2_on_1.7.0.diff), sha256
8371681d3d54b94a..., made by this run's [`setup_engine.sh`](setup_engine.sh)), by the cloth rig
[`tools/nwt_cloth_proxy.py`](../../tools/nwt_cloth_proxy.py), whose CONTACT files now carry the box's mass as the model
has it (2,500 g for #4698's box, 700 g for the hammock's: run 116's second instrument fault).

## The second form

Run 116 found two defects in the realized harvest; the second form mends them, and the rewind (switch value 1) is the
first form's:

- **Summed over the coupled step's substeps.** The realized wrench is added at each of VBD's substeps from the rewind
  on, and harvested as their mean, so an impact landing in the first substep is not lost.
- **Every soft contact the particles felt.** The wrench is the sum over every soft contact of its body, as the particle
  iteration walks them, not over the body's own contact list, which does not yet hold a contact at its first step.
- **An impact pushed clear.** Where no contact force at the final iterate lies along the deformable's unbalance (the
  iterations pushed the cloth clear of the box, at the first contact step), its contact candidates share it alike.

## What is played

Run 116's plays: as released (`stock`), the patched tree with the switch unset (`off`), at 1 (`p1`) and at 2 (`p2`), at
10 and 40 iterations; #4698's scene and the tall box, one-way and two-way, 0.6 s; the hammock, two-way, now 2 s; the
throw, two-way, 0.3 s. Read by Senua AI's `sx_contact`: `rest` on the box's and the cloth's files, `stop` on the box's
(its largest speed over the last third), `pairg` on the throw's two.

## Predictions (pushed before the plays)

| Check | Prediction |
|---|---|
| C0 | Every play a number; as released and at 1, every play but the hammock run 116's file byte for byte |
| P1 | `off` byte for byte the release in every play |
| P2 | The tall box one-way at 2: the harvested force within 1 in 20 of the force the cloth receives, at both counts |
| P3 | Two-way at 2, #4698's box and the tall box: the box's largest speed over the last third 10 um/s or less |
| P4 | The throw: as released the momentum at the end at least twice the cloth's at the start; at 2, within 1 in 50 of it |
| P5 | The hammock (its box's landing speed 767 mm/s, its weight 6,867 mN): as released at 40 iterations the box faster than its landing; at 2 no faster at either count, and the force fed back over the second half within 1 in 10 of its weight |

Reported: every reading at 1, #4698's scene one-way.

## What it found

Played 20 October 2026 on the Newton host (`started.txt`, `finished.txt`); the measured lines in `measured.txt`, the
checks in [`checks.txt`](checks.txt). **10 of 14 checks held; the hammock's four failed.**

| Check | Result |
|---|---|
| C0 | Held, 3 lines: every play a number; as released and at 1, 20 of 20 plays run 116's files byte for byte |
| P1 | Held: 12 of 12 plays off byte for byte the release's |
| P2 | Held: the tall box one-way at 2, 440 and 440 mN harvested against the 440 the cloth receives, at 10 and 40 iterations |
| P3 | Held: two-way at 2, #4698's box and the tall box at 1 um/s at both counts |
| P4 | Held: as released the throw's momentum at the end 14.8 and 6.4 times the cloth's at the start; at 2, within 1 in 1,200 and 1 in 3,200 of it |
| P5 | Failed, 4 lines: as released at 40 iterations the box is thrown and falls through the cloth to the ground (5.7 mm/s over the last third, at rest there); at 2 it is thrown at 4.5 and 3.1 m/s, its feedback 0 and 3,938 mN over the second half |

The hammock (the box's weight 6,867 mN, its landing speed 767 mm/s), over the second half and the last third of 2 s:

| | 10 iterations | 40 iterations |
|---|---|---|
| As released | thrown, 1.03 m/s; 7,463 mN | thrown, then through the cloth to the ground |
| At 1, the rewind alone | **settled on the cloth, 1.9 mm/s; 6,866 mN** | settled after a throw, 199 mm/s; 6,835 mN |
| At 2, the realized harvest's second form | thrown, 4.5 m/s | thrown, 3.1 m/s |

- **The second form mends run 116's two defects**: the throw keeps its momentum (as released 15 times too much), the
  tall box takes exactly the cloth's force, and the boxes under the cloth are still. The realized wrench's mean over
  the substeps, and every contact walked, give the first contact step's impulse its due.
- **A held cloth is another matter**: the realized harvest throws the box off it at its first contact (70 N fed back
  at step 25), where the explicit harvest with the rewind alone lands it softly and settles it, its feedback within
  0.03% of its weight. The cloth's balance there includes what its held edges carry, and the iterate's elastic forces
  at those edges are as far from converged as its contacts: one balance cannot split them. A deformable that pins
  hold keeps the explicit harvest in the design's third form
  ([`vbd_proxy_coupling_v3_on_1.7.0.diff`](../../patches/in_design/vbd_proxy_coupling_v3_on_1.7.0.diff), sha256
  77cb8f3f662442d4...), which on the host (checks of the code, not plays of the record) holds #4698's box at 1 um/s,
  the tall box's harvest at the cloth's 440 mN, the throw's momentum to 0.1%, and the hammock's box on the cloth, its
  feedback 6,848 mN, under its landing speed.
