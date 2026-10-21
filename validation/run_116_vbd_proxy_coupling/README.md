# Run 116: VBD's proxy coupling, the rewind and the realized harvest (issue 21, #4698)

Not registered: a design probe, its predictions pushed with [`play.sh`](play.sh) before any play. Newton 1.7.0 from PyPI,
and the same with Senua AI's VBD proxy coupling patch in design first on the path
([`vbd_proxy_coupling_on_1.7.0.diff`](../../patches/in_design/vbd_proxy_coupling_on_1.7.0.diff), sha256
3c2409a17e4739fb..., made by this run's [`setup_engine.sh`](setup_engine.sh)), by the cloth rig
[`tools/nwt_cloth_proxy.py`](../../tools/nwt_cloth_proxy.py), grown at this run with three scenes and the CONTACT files
the measure reads (its default play byte for byte run 112's).

## The patch

Run 112 found #4698's two faults on 1.7.0. The patch's switch `NEWTON_VBD_PROXY_COUPLING`:

- **=1, the rewind (#4698's B):** SolverVBD rewinds a proxy body by its gravity only when it integrates it. The generic
  rewind also takes the lagged feedback off, which the generic momentum harvest adds back; VBD's explicit harvest
  overwrites the feedback instead, so the proxy was pushed into the cloth by a force nothing balanced, read back as
  more contact force. #4698's own fix, written afresh.
- **=2, the rewind and the realized harvest (#4698's A):** the harvest hands the source solver the contact force as the
  cloth received it. At the step's final iterate one more pass of VBD's particle iteration writes each particle's
  unbalanced force (its inertial, elastic and contact forces) in place of its update; summed over each deformable
  (the particles its triangles, bending edges, tetrahedra and springs join), it is taken off the deformable's
  contacts, each in the share its force along that unbalance has of all of theirs. At a converged iterate that is the
  penalty force exactly; summed over the contacts, the deformable's momentum change less its weight and what its pins
  hold; and a pin's pull stays in its neighbours' elastic forces, so a body resting on a held cloth is still carried.
  Per particle the unbalance did not stay with the contact: a first form taking each particle's own unbalance off its
  own contacts cut #4698's 70 N to 18 N, the cloth's weight being 0.44 N, the stiff membrane carrying the unbalance to
  neighbours that touch nothing; a second, sharing the deformable's by each contact's force size, let friction and
  damping across it move the split (the box pushed up by 1.2 N). Those were checks of the code on the way to it, not
  plays of the record.

## What is played

As released (`stock`), the patched tree with the switch unset (`off`), at 1 (`p1`) and at 2 (`p2`), at 10 and 40 VBD
iterations: #4698's scene one-way and two-way (`rest`); the same on a box 0.16 m tall (`tall`, `box_hz=0.08`), whose
top the cloth's corners cannot hang down from to the ground, one-way and two-way; a 0.2 kg box of half-size 0.05 m
dropped from 3 cm onto the cloth held along two edges 0.3 m up (`hammock`), two-way; and with no gravity and no ground,
the cloth sent at 1 m/s at the 0.5 kg box at rest (`throw`), two-way, 0.3 s. Read by Senua AI's `sx_contact`: `rest`
on the box's and the cloth's CONTACT files (the mean harvested force on the box, and the mean force the cloth
receives, up, over the second half), `fastest` on the box's (its largest speed up or down over the last 50 coupled
steps, 0.2 s), and `pairg` on the two (the momentum they started with and their speeds at the end).

## Predictions (pushed before the plays)

| Check | Prediction |
|---|---|
| C0 | Every play a number; #4698's scene as released run 112's four files byte for byte |
| P1 | `off` byte for byte the release in every play |
| P2 | On the tall box one-way, as released the harvested force at least 10 times the force the cloth receives; at 2, within 1 in 20 of it, at both iteration counts |
| P3 | #4698's scene two-way at 2: the box's largest speed over the last 50 steps 1 mm/s or less, at both counts |
| P4 | The hammock: as released the box thrown, faster than 0.1 m/s over the last 50 steps; at 2 held, slower than 10 mm/s, and the force fed back to it within 1 in 10 of its weight (1,960 mN), at both counts |
| P5 | The throw: as released the momentum at the end at least 1.5 times the cloth's at the start; at 2 within 1 in 20 of it |

Reported: every reading at 1, and #4698's scene one-way.

## What it found

Played 20 October 2026 on the second x86-64 host (`started.txt`, `finished.txt`); the measured lines in `measured.txt`,
the checks in [`checks.txt`](checks.txt). **7 of 16 check lines held; three did not read; two instrument faults.**

**Two instrument faults, found in the readings:**

- **The runner called the measure's `fastest`**, which the hosts' build of Senua AI's measure (sha256 b1d1b2906041219e...)
  predates: it printed its usage, and P3's and P4's speed lines did not read (`rule: unknown kind`). The same quantity,
  the box's largest speed up or down over the last 50 coupled steps, is `stop`'s largest speed over the last third
  (50 of 150 steps); it was read with `stop` from the kept box files, by hand on the host, below. Those readings are
  reported, not checks.
- **The box's mass is not the rig's `box_mass`**: Newton's `add_shape_box` gives the box its default density, 1000
  kg/m^3, so `box_mass` is added to the shape's own: #4698's box (and run 112's) is 2.5 kg, not 0.5, the hammock's box
  0.7 kg, not 0.2 (the MuJoCo box's acceleration is exactly 0.200 of the harvested force over 0.5 kg at every step of
  every throw). P4's weight (1,960 mN) and P5's momentum (the box at 500 g) were sized on the wrong masses: the box's
  weight on the hammock is 6,867 mN, and with the box at 2,500 g the throw's momentum at the end is as in the table.

| Check | Result |
|---|---|
| C0 | Held, 2 lines: every play a number; #4698's scene as released run 112's four files byte for byte |
| P1 | Held: 12 of 12 plays off byte for byte the release's |
| P2 | Held as released (73,882 and 13,100 mN against the cloth's 440); at 2, held at 40 iterations (419), failed at 10 (330, 25% short) |
| P3 | Not read (`fastest`); by `stop`, 1 and 1 um/s at 2 |
| P4 | Speeds not read (`fastest`); force lines failed against the wrong weight: 6,685 and 8,646 mN, the box's weight being 6,867 |
| P5 | As released held at 10 iterations, failed at 40, on the wrong mass; at 2 failed both |

| | as released, 10 / 40 iterations | at 1 | at 2 |
|---|---|---|---|
| #4698's scene one-way, harvested for the box (cloth receives 441) | -72,978 / -18,041 mN | the same | -281 / -387 |
| #4698's scene two-way, box's largest speed over the last 50 steps (by `stop`) | 8,891 / 1,293 um/s | 142 / 49 | 1 / 1 |
| Tall box one-way, harvested (cloth receives 440) | -73,882 / -13,100 mN | the same | -330 / -419 |
| Tall box two-way, box's largest speed (by `stop`) | 502 / 73 um/s | 39 / 34 | 1 / 2 |
| Hammock, mean harvested over the second half (the box's weight 6,867) | 7,059 / 9,140 mN | 7,083 / 7,164 | 6,685 / 8,646 |
| Hammock, box's largest speed (by `stop`; landing speed 767 mm/s) | 737 / 1,788 mm/s | 26 / 1,453 | 275 / 541 |
| Throw, momentum at the end (the cloth's at the start -4.5e6, units of 10 ug m/s) | -66.8e6 / -28.6e6 | -49.8e6 / -19.0e6 | -2.2e6 / -4.0e6 |

- **#4698's faults, and the rewind's part**: as released the harvest is 165 and 41 times the cloth's force, two-way the
  box moves at up to 8.9 mm/s, and the throw's box takes 15 times the momentum the cloth brought. The rewind alone (at
  1) cuts the box's motion 60 to 25 times and does nothing to the harvest's size.
- **The realized harvest (at 2) gives the cloth's force within 25% (10 iterations) and 5% (40)**, and the box under it
  is still to 1 to 2 um/s two-way; on #4698's own scene part of the cloth rests on the ground at its corners, so the
  box takes less than the whole.
- **Two defects of the design, found here**: the throw keeps half its momentum at 10 iterations, 88% at 40:
  the realized harvest read only the coupled step's last substep, where an impact lands in the first; and at the first
  contact step the harvest walked the proxy body's own contact list, which does not yet hold the contact the cloth's
  particles felt. And on the hammock the box's energy grows past its landing (1.79 m/s against 0.77) as released at 40
  iterations; at 2 it stays within it but moves at 0.3 to 0.5 m/s: the hammock does not damp (tri_kd 0), so the right
  answer there is energy that does not grow, not a box at rest.
- What the design does next (checked on the host, not plays of the record): the realized wrench summed over the
  coupled step's substeps and harvested as their mean; every soft contact the particles felt walked, not the body's
  list; and where no contact force at the final iterate lies along the deformable's unbalance (an impact the
  iterations pushed clear, at the first contact step), its contact candidates sharing it alike. On the throw that
  keeps the pair's momentum to 0.1%; the tall box takes 440 mN of the cloth's 440; #4698's box is still to 1 um/s.
