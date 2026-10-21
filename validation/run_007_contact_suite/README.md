# Run 007: the first deep dive's ten contact tests, on every Newton solver

15 October 2026. Not registered: a design probe, by [`play.sh`](play.sh) (pushed before its plays); reading
`reading.txt`. The first deep dive's contact suite ([`tools/contact_suite.sh`](../../tools/contact_suite.sh): its
scenes, its steps of 10 ms over 1 to 64, its file names) played on each Newton solver with its defaults, and on
SemiImplicit and Featherstone with the friction patch in design on (run 005); read by the first deep dive's own
runner, `sx_contact_suite.sh`, unchanged, with Senua AI's `sx_contact`. The plays are under `suites/1/<label>/`, each
with its runner's file `verdicts.txt`. One difference from the first deep dive's suite: Newton's cube is free to turn
(its rig has no locked rotation); SuperDex's and MuJoCo's were held level.

| Test | XPBD | Featherstone | SemiImplicit | Featherstone, patched | SemiImplicit, patched |
|---|---|---|---|---|---|
| T01 nothing touches the cube: the chain halves | PASS | PASS | PASS | PASS | PASS |
| T02 steady sliding: Coulomb's friction | PASS | FAIL (4,709 per 10,000 for 4,000) | FAIL (4,695) | PASS | PASS |
| T03 at rest the ground carries the weight | PASS | PASS | PASS | PASS | PASS |
| T04 the bounce does not depend on the step | FAIL (382 to 1,125 per 10,000) | FAIL (16,936 at 10 ms) | FAIL | FAIL | FAIL |
| T05 Coulomb at impact, every step | PASS | FAIL (4,571 to 4,675) | FAIL | PASS | PASS |
| T06 held below the limit does not move | FAIL (54,333 and 3,395 um/s) | FAIL | FAIL | FAIL (2,645 um/s at 0.625 ms) | FAIL |
| T07 pushed above it, it accelerates at (push minus friction) over mass | FAIL (1,079,700 for 980,000 at 10 ms) | FAIL (5,200: the cube barely moves) | FAIL | FAIL (1,019,200 at 0.625 ms) | FAIL |
| T08 the refinement chain falls at every step | FAIL | PASS | PASS | FAIL | FAIL |
| T09 the ground never pulls | PASS | PASS | PASS | PASS | PASS |
| T10 friction over the impact and after it | PASS | FAIL (1,755 at 10 ms; 4,693 to 4,840 below it) | FAIL | PASS | PASS |
| **Passed** | **6 of 10** | **4 of 10** | **4 of 10** | **6 of 10** | **6 of 10** |

At 10 ms, the suite's coarsest step, SemiImplicit and Featherstone with Newton's default contact are unstable on this
cube (run 001 found it at 2 ms already): the 10 ms readings of T04, T06 and T07 come from a cube that hops and turns.

**Not read: the MuJoCo solver, VBD and VBD-ALM.** The runner stops when a measure has nothing to read and gives no
verdicts (`rc 1`):
- The MuJoCo solver: the suite's drop is frictionless, and the MuJoCo solver stops being a number at the first
  contact of a frictionless shape (run 001), so every drop file ends at its first contact (12 plays with
  `nan_at_step`). MuJoCo's C engine raises a friction of 0 to 1e-5 and plays on; a follow-up plays the MuJoCo solver's
  drop at 1e-5, the friction MuJoCo's C engine itself used in its run of this suite.
- VBD and VBD-ALM: their free fall is not gravity's (runs 001, 006), and the rig reads the contact force from the
  cube's change of momentum, so the drop's measures find the cube on the ground from its first step.

## What it shows

- On the first deep dive's own ten tests, Newton's own solvers pass at most six as shipped (XPBD); SemiImplicit and
  Featherstone pass four, failing every friction test.
- **The friction patch in design takes SemiImplicit and Featherstone from four to six**: T02, T05 and T10 pass, the
  same friction tests their stock kernels fail. It was not designed for the rest: the bounce, the creep at rest, the
  instability at 10 ms. T07 at 0.625 ms reads 4% fast with the patch; the cube is free to turn and the suite's push
  acts at its centre, so this is a reading to look at, not yet a finding.
- For comparison under the same runner: MuJoCo as shipped passes nine (the MuJoCo deep dive's run 008); SuperDex's
  results are in the first deep dive's record.

Added 15 October 2026, when the record was checked end to end ([`docs/audit.md`](../../docs/audit.md)): the table
above shows one more effect of the friction patch that this section did not state. With the patch, both solvers
fail T08, the refinement chain (Featherstone's gaps 6,041,432, 651,438, 17,338, 9,176, 11,713 and 2,223: the gap
between 1/16 and 1/32 of the step is larger than the one before it), where both pass without it. Study 1 did not
cover the suite; the patch page and the findings now say so.
