# Run 006: VBD's free fall against the height it falls at

15 October 2026. Not registered: a design probe, by [`probe.sh`](probe.sh) (its prediction written into it and pushed
before the plays); reading `reading.txt`. Run 001 found VBD's free fall wrong in a way that grows as the step shrinks,
and the pattern fit positions held in 32-bit floats. If that is the cause, the error depends on the height the cube
falls at, nothing else changed: the spacing between neighbouring 32-bit numbers is 3.7 nm near 0.06 m, 14.9 nm near
0.15 m, 119 nm near 1.05 m and 954 nm near 10.05 m, while a step's fall from rest, g dt^2, is 153 nm at 0.125 ms and
9.6 nm at 0.031 ms. The cube (1 kg, half-size 0.05 m) falls freely for 50 ms from four heights at those two steps, on
VBD, VBD-ALM and, for reference, XPBD. The reading is the mean acceleration over the 50 ms, from the rig's files
(right answer 9,800 mm/s2).

| The cube's centre at | VBD, 0.125 ms | VBD, 0.031 ms | VBD-ALM, 0.125 ms | VBD-ALM, 0.031 ms | XPBD, both steps |
|---|---|---|---|---|---|
| 0.15 m | 9,536 | 15,258 | 9,536 | 15,258 | 9,799 |
| 1.05 m | 7,629 | **0** | 7,629 | **0** | 9,799 |
| 10.05 m | **0** | **0** | **0** | **0** | 9,799 |

The lowest height played, the centre at 0.06 m (10 mm above the ground), is not a reading: the cube reaches the ground
within the 50 ms, as XPBD's play shows. A fault of the probe's design, not of the engine.

Where the reading is 0 the cube does not move at all: at 10.05 m its height stays at exactly 10,000,000,000 nm and its
speed at 0 for every step (`runs/fall_vbd_10_0.000125.txt`). The rig takes the contact force from the change in the
cube's momentum, so it writes a force of 9,800 mN there; nothing touches the cube.

## What it shows

- **VBD's free fall depends on the height it falls at, as 32-bit positions predict.** Where a step's fall is less than
  the spacing of 32-bit numbers at the cube's height, the cube does not fall: released 10 m up, it hangs in the air at
  both steps; released 1 m up, it hangs at 0.031 ms and falls at 78% of gravity at 0.125 ms, where a step's fall
  (153 nm) is just above the spacing (119 nm). VBD-ALM, the coming default, does the same. XPBD, which also holds its
  positions in 32-bit floats, falls at gravity's rate at every height and step. The results fit VBD reading its
  velocity back from the change in a position already rounded, where XPBD carries the velocity itself.
- The known issue list had VBD as experimental (N13); this is a finding of this record (F1, now measured): a body
  that cannot fall from a height of 10 m, or 1 m at a small step.
