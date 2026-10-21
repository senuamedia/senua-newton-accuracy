# Run 060: a fast cube onto a thin slab, with and without speculative contacts (issue 20's tunnelling)

Not registered: a trace. Its play script [`play.sh`](play.sh) and the predictions below were pushed before its plays.
Newton 1.7.0 as released. The rig [`tools/nwt_contact.py`](../../tools/nwt_contact.py) gains `slab=` (the ground a
static box this thick, its top at the plane's height), `vz0=` (the cube's starting speed along z) and `specgap=` (the
collision pipeline's speculative contacts on, `CollisionPipeline(speculative_contact_gap_max=...)`, the step's dt
passed to `collide`); a play setting none of them is unchanged (check C0).

## Read in the source (Newton 1.7.0)

Newton's collision pipeline detects contacts at the step's start; it has speculative contacts (shapes' boxes swept
by their velocity over the step, `geometry/broad_phase_*.py`, "speculative-contact swept-AABB tests"), off unless
`speculative_contact_gap_max` is given (`sim/collide.py`: `_speculative_enabled = speculative_contact_gap_max is not
None`). The record's rigs use the default.

## What is played

One cube (1 kg, half-size r = 0.05 m) 5 cm above a static slab 10 mm or 2 mm thick (D), falling at 20, 60 or 150
m/s, 0.1 s, at 1 and 4 ms, on XPBD and Featherstone, speculative contacts off and on (gap 1 m). Above: the cube's lowest
face above the slab's bottom at the end.

**Disclosed before the plays:** the rig's change was checked on the host by four drops on XPBD at 1 ms onto the 10 mm
slab, at 5 and 60 m/s, speculative contacts off and on: all four ended above the slab (the 60 m/s cube thrown back up
at 17.6 m/s), the speculative setting changing nothing at those speeds.

## Predictions, before the plays (by the geometry: a step carries the cube |v| dt)

- Speculative contacts off: the cube goes through the slab where a step carries it past the slab whole,
  |v| dt > D + 2r, 110 and 102 mm (150 m/s at 1 ms, and 60 and 150 m/s at 4 ms, on both slabs); where |v| dt <
  r + D/2, 55 and 51 mm, the overlap that is caught has the cube's centre above the slab's middle and it is pushed back
  (20 m/s at 1 ms, on both slabs); between (20 m/s at 4 ms, 80 mm; 60 m/s at 1 ms, 60 mm), not predicted. (Corrected
  before any play: the first push of this README put 20 m/s at 4 ms and 60 m/s at 1 ms on the 2 mm slab among the
  pushed back, against its own numbers.)
- Speculative contacts on: above the slab at every speed and step (the swept test catches the approach).
- Every play a number throughout; C0 holds.

## What was found

Played on the Newton host, 2026-10-19T14:02:34Z to 2026-10-19T14:06:27Z. Reading [`reading.txt`](reading.txt) (the last
step's height of the cube's lowest face and its speed along z), checks [`checks.txt`](checks.txt) (65 of 97 held).
C0 held.

| Speed, step (a step carries the cube) | XPBD, 10 and 2 mm slabs | Featherstone, 10 and 2 mm slabs |
|---|---|---|
| 20 m/s, 1 ms (20 mm) | above: thrown back up at 5.8 m/s | above: back up at 2.8 m/s |
| 20 m/s, 4 ms (80 mm) | **through** | above: back up at 12.3 m/s |
| 60 m/s, 1 ms (60 mm) | above: back up at 19.6 m/s | **through** |
| 60 m/s, 4 ms (240 mm) | **through** | **through** |
| 150 m/s, 1 and 4 ms (150, 600 mm) | **through** | **through** |

- **The geometry held where it predicted:** through wherever a step carries the cube past the slab whole (60 m/s at 4
  ms, 150 m/s at both steps, both solvers, both slabs), pushed back where the caught overlap stays above the slab's
  middle (20 m/s at 1 ms); in the band between, the two solvers part (XPBD through at 20 m/s and 4 ms and back at 60
  m/s and 1 ms, Featherstone the other way round). The slab's thickness, 10 or 2 mm, changes no outcome here.
- **Speculative contacts, as turned on here, change nothing:** with `speculative_contact_gap_max=1` and the step's dt
  passed to `collide`, every play is byte for byte the play without them. The prediction failed. Not traced: whether
  the solvers use the contacts the speculative path writes, and how the pipeline's own gap (`rigid_gap`, 0.1 m by
  default) bears on it, were not read.
- **Every cube that stays above is thrown back up**, faster at the higher speed (19.6 m/s from 60 m/s on XPBD), as the
  record's F5 and F11 bounces with no restitution asked for: no play holds the cube at rest on the slab within 0.1 s.
- Issue 20's tunnelling on 1.7.0: Newton's discrete contact lets a body through a slab a step carries it past; the
  speculative option, as documented and set here, did not stop it.

Every reading and check of this run was made again on the laptop, byte for byte, from its kept files, with a build of
[the measure](../../measure/README.md) (20 October 2026).
