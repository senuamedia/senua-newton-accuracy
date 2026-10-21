# Run 030: a body spinning about a centre of mass off its origin (N8)

15 October 2026, 09:24 to 09:26 UTC, on the Newton host, by [`play.sh`](play.sh), whose predictions were pushed with
the rig's new settings before the plays. Not registered: a probe of a reported issue. Newton 1.6.1 from PyPI. Reading
`reading.txt`, made with Senua AI's `sx_contact` (`creep`, `stop`), re-made byte for byte on the laptop from the same
files. In the logs the home folder is written `~/`.

## The question

Users report that on Featherstone a body whose centre of mass is off its origin drifts under pure rotation
(N8; [#1366](https://github.com/newton-physics/newton/issues/1366),
[#12](https://github.com/newton-physics/newton/issues/12)). With nothing acting on a spinning body, its centre of mass
must stay where it is.

## The rig

[`tools/nwt_contact.py`](../../tools/nwt_contact.py) gains three settings: `gravity=0`, `comx` (the box, and so the
centre of mass, placed that far along the body's x from its origin) and `wz0` (a spin about z at the start, about the
centre of mass, which starts at rest; Newton 1.6's free-joint velocity is the centre of mass's, world frame). Each is a
no-op at its default: four earlier plays made again with the changed rig are byte-identical to their kept files (run
001's hold on SemiImplicit and slide on VBD-ALM, run 004's plate on XPBD, run 007's drop at 2.5 ms on XPBD).

## What was played

A 1 kg cube, half-size 0.05 m, 1 m above the ground, no gravity, spinning at 5 rad/s about z for 2 s, its centre of
mass 0.05 m off its origin, and on Featherstone also at its origin. The rig's speed column is the centre of mass's
along x; the right answer is 0.

| The centre of mass's speed, um/s: mean over the second half, and the largest in the last third | 10 ms | 2.5 ms | 0.625 ms |
|---|---|---|---|
| Featherstone, centre of mass off the origin | 0 and 0 | 0 and 1 | -2 and 3 |
| Featherstone, at the origin | 0 and 0 | 0 and 0 | 0 and 0 |
| SemiImplicit, off the origin | 0 and 0 | 0 and 0 | 0 and 0 |
| XPBD, off the origin | 0 and 0 | 0 and 0 | 0 and 0 |
| **The MuJoCo solver**, off the origin | **5,754 and 12,498** | **1,431 and 3,117** | **336 and 734** |
| **VBD-ALM**, off the origin | 0 and 2 | 3 and 13 | **-201 and 352** |

The MuJoCo solver's centre of mass travels 13.1 mm in the 2 s at 10 ms, 3.2 mm at 2.5 ms and 0.69 mm at 0.625 ms.

| Prediction | Result |
|---|---|
| P1: on Featherstone with the centre of mass off the origin, it moves faster than 10 um/s at every step | **Failed**: 3 um/s at most |
| P2: on Featherstone with the centre of mass at the origin, it stays (10 um/s or less) | Held |
| P3: SemiImplicit, XPBD, the MuJoCo solver and VBD-ALM keep it at rest (10 um/s or less) | Held on SemiImplicit and XPBD. **Failed** on the MuJoCo solver at every step and on VBD-ALM at 2.5 and 0.625 ms |
| Checks: four earlier plays byte for byte with the changed rig | Held |

No play stopped being a number.

## What it shows

- **The reported Featherstone drift does not occur in Newton 1.6.1** on this body: its centre of mass stays within
  3 um/s, as SemiImplicit's and XPBD's do.
- **The MuJoCo solver moves the centre of mass of a body spinning about it**, at a speed proportional to the step
  (5.8 mm/s, 1.4 mm/s and 0.34 mm/s, a quarter for each step 4 times smaller): first order, as an integrator's error
  is. Whether MuJoCo's C engine does the same was not played here.
- **VBD-ALM's centre of mass moves more as the step shrinks** (0.2 mm/s at 0.625 ms), the pattern of VBD's other
  errors at small steps; not traced.
