# Run 129: a static friction coefficient on Newton's own solvers (issue 18)

Not registered: a design probe, its predictions pushed with [`play.sh`](play.sh) before any play. Newton 1.7.0 from
PyPI with the record's validated friction chains and pull request #4306 rebased onto 1.7.0 (`chain`), and the same
with Senua AI's static friction patch in design on top
([`static_friction_on_chain.diff`](../../patches/in_design/static_friction_on_chain.diff), sha256 0b693bdab34b4659...),
both made by this run's [`setup_engine.sh`](setup_engine.sh).

## The patch

Issue 18's last part: Newton's shapes carry one friction coefficient, so nothing that sticks before it slides (a
static coefficient above the dynamic one) can be modelled on any solver. Pull request #4306, open upstream, adds the
coefficient to the data model (`ShapeConfig.mu_static`, `Model.shape_material_mu_static`; negative means the same as
`mu`) and no solver reads it. The patch's switch `NEWTON_STATIC_FRICTION=1` (read once) makes the three solvers whose
friction the record has made Coulomb's read it, by the needed-impulse rule (no memory): the friction a contact needs
to stop the slip within the step, when it is within the static limit, is applied whole; otherwise the dynamic limit.

- XPBD, on the step's friction totals (`xpbd_friction_total`, Study 15): a total past the static limit falls back to
  the dynamic limit.
- SemiImplicit and Featherstone, in the Coulomb friction pass (`semi_coulomb_friction`, `featherstone_coulomb_friction`,
  Study 18): the impulse that stops the slip is applied when it is within the static limit, else the dynamic one.
- A pair's static coefficient is the mean of each shape's `max(mu_static, mu)`, the rule the chains use for `mu`.
- The MuJoCo solver cannot follow (MuJoCo has no static coefficient): it warns, once, naming the shapes whose static
  coefficient it does not apply. VBD's contact is not yet covered and is reported.

Unset, nothing changes. On the host, before this probe: XPBD held a pushed cube at 2 um/s and slid as the kinetic case
once moving; SemiImplicit and Featherstone held it at 0 um/s once the push began after the normal force had settled
(0.3 s), and accelerated without the switch.

## What is played

A 1 kg cube of half-size 0.05 m on the plane, both shapes' friction 0.4 and static friction 0.8, at 0.5 ms:

- **hold**: pushed at 5.88 N (0.6 g, between the dynamic limit 3.92 N and the static 7.84 N) from 0.3 s, 1.2 s; the
  right answer is held.
- **kinetic**: sent at 0.5 m/s under the same push from the start, 1 s; the right answer accelerates at 1.96 m/s^2 to
  2.46 m/s (the dynamic coefficient once sliding).
- **break**: pushed at 8.82 N (0.9 g, above the static limit) from 0.3 s, 1.2 s; the right answer breaks away at
  4.9 m/s^2 to 4.41 m/s.
- **slide**: sent at 1 m/s with no push, 0.6 s; the right answer slides 0.1276 m and stays.

On XPBD (no speed floor, friction on the step's totals, 64 iterations), SemiImplicit and Featherstone (the Coulomb
friction pass at 64 sweeps), the MuJoCo solver and VBD-ALM; with the chain, with the patch and the switch unset
(`off`), and set (`on`). Read by Senua AI's `sx_contact` (`creep` for the hold's mean speed over the second half,
`final` for the last speed, `stop` for the slide).

## Predictions (pushed before the plays)

| Check | Prediction |
|---|---|
| C0 | Every play a number |
| P1 | Off, every play byte for byte the chain's |
| P2 | With the chain, the hold slides on XPBD, SemiImplicit and Featherstone (mean speed 100 mm/s or more) |
| P3 | On, the hold held on the three (mean speed within 10 um/s of rest) |
| P4 | On, the kinetic case within 1 in 50 of 2.46 m/s on the three |
| P5 | On, the break within 1 in 20 of 4.41 m/s on the three |
| P6 | On, each of the three's slide within 1 in 50 of its slide with the chain |
| P7 | On, the MuJoCo solver warns once |

Reported: every reading, and the MuJoCo solver's and VBD's plays.

## What it found

Played 20 October 2026 (UTC) on the second x86-64 host (`started.txt`, `finished.txt`); the measured lines in
`measured.txt`, the checks in [`checks.txt`](checks.txt). **10 of 10 checks held.**

| On (the switch set) | hold, mean speed um/s (chain) | kinetic, m/s | break, m/s | slide, um (chain) |
|---|---|---|---|---|
| Right answer | 0 | 2.460 | 4.410 | 127,551 |
| XPBD | 6 (1,176,411) | 2.4598 | 4.4133 | 127,305 (127,297) |
| SemiImplicit | 0 (1,178,500) | 2.4600 | 4.3982 | 127,689 (127,693) |
| Featherstone | 0 (1,178,479) | 2.4599 | 4.3983 | 127,690 (127,694) |
| The MuJoCo solver (warns; plays its dynamic coefficient) | 1,177,087 | 2.4657 | 4.4474 | 127,524 |
| VBD-ALM (not covered) | 1,232,463 | 2.6476 | 4.4436 | 164,897 |

- C0 held; P1 held (20 of 20 plays off byte for byte the chain's); P2 held (with the chain the hold slides at 1.18
  m/s on the three); P3 held (6, 0 and 0 um/s); P4 held (within 1 in 10,000 of 2.46 m/s); P5 held (within 1 in 300 of
  4.41 m/s); P6 held on all three (within 1 in 10,000 of the chain's slide); P7 held (one warning, and only on).
- **With the switch, XPBD, SemiImplicit and Featherstone hold a cube pushed between the two limits and play the
  dynamic coefficient once it slides or breaks away**; each friction reads 0.6 of the normal force while held (the
  push), against 0.4 sliding. The kinetic, break-away and stopping slides are the chain's to 1 in 300.
- The MuJoCo solver plays its dynamic coefficient and says so once, naming the shape. VBD's contact is not yet covered:
  its plays are byte for byte the chain's, and its slides depart from the right answer as released (the slide 29 %
  long, the kinetic case 7.6 % fast), which this run does not explain.
- What remains for issue 18's static part: VBD's contact, and the coefficient's import (USD), then a study.
