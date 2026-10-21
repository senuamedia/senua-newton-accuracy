# Run 142: Study 39, VBD's legacy path far from the origin, its poses carried and its joint stabilisation off (issue 12)

The thirty-ninth registered study ([`PREREGISTRATION_39.md`](../../preregistrations/PREREGISTRATION_39.md)), played once
with [`play.sh`](play.sh) on the engines made by [`setup_engine.sh`](setup_engine.sh): Newton 1.7.0 with Senua AI's VBD
displacement patch (`dsp`), and with the displacement patch and Senua AI's VBD pose carry
([`vbd_pose_carry_on_displacement.diff`](../../patches/in_design/vbd_pose_carry_on_displacement.diff), Study 36's), its
switch unset (`off`) and set (`on`), `NEWTON_VBD_DISPLACEMENT=1` in every play. Every play on VBD's legacy path
(`rigid_compliant_alm=False`) with Newton's own `rigid_avbd_joint_alpha=0`, but `ona`: the carry set at the default
alpha, 0.95 (reported).

## What it found

Played 21 October 2026 (UTC) on the Newton host (`started.txt`, `finished.txt`); the measured lines in `measured.txt`,
the rules in [`rules.txt`](rules.txt). **10 of 15 rule lines held.**

The free chain's largest energy departure, ppm:

| | 0.4 ms | 0.2 ms | 0.1 ms | 0.05 ms | 0.025 ms |
|---|---|---|---|---|---|
| Off, at the origin | 5,584 | 2,882 | 897 | 104 | 137 |
| Off, 20 m out | 7,988 | 2,452 | 4,587 | 5,486 | 9,301 |
| Off, 50 m out | 13,062 | 9,162 | 6,046 | 4,667 | 7,837 |
| On, at the origin | 5,649 | 2,790 | 1,157 | 612 | 138 |
| On, 20 m out | 6,433 | 2,909 | 1,463 | 624 | 206 |
| On, 50 m out | 6,205 | 2,485 | 1,281 | 606 | 159 |
| On at alpha 0.95 (reported), at the origin | 6,137 | 3,130 | 1,415 | 618 | 159 |
| On at alpha 0.95, 20 m out | 5,417 | 2,844 | 1,547 | 1,820 | 2,378 |
| On at alpha 0.95, 50 m out | 6,773 | 3,008 | 1,582 | 4,227 | 8,651 |

- R1 held: with the switch unset all 24 plays byte for byte the displacement patch's.
- R2 held: unset, 9,301 ppm at 20 m and 7,837 at 50 m at 0.025 ms, against 137 at the origin.
- R3 failed at four of its five steps: set, the far chain within 1 in 10 of the origin's at 0.05 ms only (624 and 606
  against 612); at 0.4 ms 20 m out is 13.9% above it, at 0.2 ms 50 m out 10.9% below, at 0.1 ms 26% and 11% above, at
  0.025 ms 49% and 15% above (206 and 159 against 138).
- R4 held: set, the departure falls at every halving of the step at 0, 20 and 50 m.
- R5 failed in one of its three lines: the spinning body's centre still (0 um/s at every step) and the hold still
  (0 um/s at both steps) held; the slide does not settle as the step shrinks (126,534, 136,249, 174,209 and 226,201 um
  from 1.2 to 0.03 ms). That is VBD's legacy path's own cold slide, which Study 17 found wrong: with the carry unset it
  is the same to 41 um (226,188 um at 0.03 ms).
- R6 held: every play a number throughout.

## What it decides

**Issue 12's VBD legacy part stays open**, as the registration says of a failed rule. With Senua AI's displacement patch
and pose carry and Newton's own `rigid_avbd_joint_alpha=0` the far chain's loss falls with the step at every distance,
206 and 159 ppm at 0.025 ms 20 and 50 m out against 9,301 and 7,837 with the carry unset, but it is not within the
registered 1 in 10 of the origin's at four of five steps. At the default alpha, 0.95, the far chain's departure grows
again at the smallest steps (2,378 and 8,651 ppm at 0.025 ms): the legacy joint stabilisation, formed from the 32-bit
poses, is the second 32-bit read the host check after Study 36 traced. The legacy path's slide, wrong as released
(Study 17), is the same with the carry.

## Checked

- Fetched from the Newton host with the host's sha256 list of the run's 267 files, every file the same.
- Every reading and rule made again on the laptop from the kept files (21 October 2026): all 87 readings and all 15
  rule lines byte for byte `measured.txt` and `rules.txt`.
