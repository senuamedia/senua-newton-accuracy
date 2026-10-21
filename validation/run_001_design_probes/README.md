# Run 001: design probes on Newton v1.6.1, every solver

15 October 2026. Not registered: design probes, to find where to look. Played by [`probe_01.sh`](probe_01.sh) on an
AWS EC2 machine (Intel Xeon Platinum 8488C, Ubuntu 24.04.5, Python 3.12.3), Warp's CPU device, Newton installed from
PyPI as `newton[sim]==1.6.1` (the full environment in `environment.txt`: Warp 1.18.0, MuJoCo Warp 3.12.0, MuJoCo
3.12.0). The one-cube rig [`tools/nwt_contact.py`](../../tools/nwt_contact.py), Newton's own Python API, writes the
first deep dive's format, so Senua AI's measuring program, `sx_contact`, built for Linux, reads these runs unchanged
(reading `reading.txt`). Every solver with its own defaults; Newton's shape defaults (contact stiffness ke 2,500,
damping kd 100, friction stiffness kf 1,000, restitution 0). The cube is a free body, 1 kg, half-size 0.05 m; gravity
9.8 m/s2. The scenes are the MuJoCo deep dive's probe 01, at 2 ms and 1/4, 1/16 and 1/64 of it, on six solvers:
XPBD, Featherstone, SemiImplicit, the MuJoCo solver (MuJoCo Warp), VBD on its current default contact path, and VBD
with `rigid_compliant_alm=True`, the path Newton 1.6 says will become its default ("VBD-ALM").

The rig was corrected twice before these plays and the whole probe played again with it as committed: it now sets
the starting velocity on the free joint as well as on the body (Featherstone and the MuJoCo solver read joint
coordinates; a first quick pass gave them no starting velocity), and it ends a file at the step before the engine's
state stops being a number, saying where in its statistics (`nan_at_step`).

## Every solver

**Deterministic:** each solver played the hold twice, byte-identical, on the CPU.

**Free fall** (the first 50 ms of the drop, read from the rig's files; right answer 9,800 mm/s2):

| | 2 ms | 0.5 ms | 0.125 ms | 0.031 ms |
|---|---|---|---|---|
| XPBD, Featherstone, SemiImplicit, the MuJoCo solver | 9,800 | 9,800 | 9,799 | 9,799 |
| VBD, VBD-ALM | 9,801 | 9,775 | 9,536 | **15,258** |

**At rest** every solver's ground carries the weight exactly (9,800 mN) at every step. How deep the cube rests (the
rig's last line):

| | 2 ms | 0.5 ms | 0.125 ms | 0.031 ms |
|---|---|---|---|---|
| XPBD | 70 um | 4.4 um | 0.27 um | 0.015 um |
| Featherstone, SemiImplicit | 980 um | 980 um | 979 um | 978 um |
| The MuJoCo solver | 17 um | 17 um | 17 um | 18 um |
| VBD | 1,772 um | 1,944 um | 1,976 um | 2,665 um |
| VBD-ALM | 980 um | 981 um | 989 um | 1,333 um |

## The hold: pushed at 0.6 of the friction limit (right answer: it does not move)

| Creep, um/s | 2 ms | 0.5 ms | 0.125 ms | 0.031 ms |
|---|---|---|---|---|
| XPBD | 10,862 | 2,715 | 680 | 174 |
| Featherstone | unstable | -6,138 | 735 | 735 |
| SemiImplicit | unstable | -6,601 | 735 | 735 |
| The MuJoCo solver | 1,293 | 1,293 | 1,293 | 1,293 |
| VBD | 12,396 | 58,208 | 223,151 | **613,739** |
| VBD-ALM | 1 | 0 | 74 | 406 |

## The slide that ends: 1 m/s, friction 0.4 (Coulomb's distance 127,551 um)

| Distance, um | 2 ms | 0.5 ms | 0.125 ms | 0.031 ms |
|---|---|---|---|---|
| XPBD | 126,594 | 127,293 | 127,468 | 126,460 |
| Featherstone | unstable | **44,204** | **43,339** | **42,982** |
| SemiImplicit | unstable | **44,657** | **43,330** | **42,974** |
| The MuJoCo solver | 126,772 | 127,508 | 127,675 | 126,703 |
| VBD | 180,192 | 193,096 | 224,276, still moving | **890,568, still moving at 0.89 m/s** |
| VBD-ALM | 164,027 | 164,882 | 165,269 | 106,341 |

At 0.031 ms the slide decelerates at 3,946 to 3,959 mm/s2 under XPBD (Coulomb's 3,920). Under SemiImplicit and
Featherstone it decelerates at 8,315 mm/s2 between 5 and 10 ms, 9,608 between 10 and 20 ms, 12,067 between 20 and
30 ms and 36,912 between 30 and 40 ms, as the cube slows: 2.1, 2.5, 3.1 and 9.4 times Coulomb's. While it slides the
cube pitches forward by up to 0.22 rad (12 degrees).

## The drop and the oblique landing

| | 2 ms | 0.5 ms | 0.125 ms | 0.031 ms | Right answer |
|---|---|---|---|---|---|
| Rebound from 100 mm, no friction, per 10,000: XPBD | 1,009 | 1,074 | 1,106 | 1,182 | Newton's restitution is 0 |
| The same: Featherstone, SemiImplicit | unstable | 175 | 189 | 192 | |
| The same: the MuJoCo solver | **not a number at the first contact** (step 71, 286, 1,143, 4,843) | | | | |
| Friction over the impact (2 m/s, friction 0.3), per 10,000: XPBD | 2,999 | 3,000 | 2,999 | 2,999 | 3,000 |
| The same: Featherstone, SemiImplicit | **4,355** | **4,320** | **4,336** | **4,339** | 3,000 |
| The same: the MuJoCo solver | 2,999 | 2,999 | 3,000 | 2,999 | 3,000 |
| The same: VBD | | **629** | **433** | | 3,000 |
| The same: VBD-ALM | | **467** | **438** | | 3,000 |

The blank VBD cells: VBD's free fall is not gravity's, and the rig takes the contact force from the change in the
cube's momentum, so in free fall the error shows as a force of a few tens of mN and the drop's measures read the cube
as already on the ground. They are not readings.

## What the probes point at

- **Newton's MuJoCo solver plays as MuJoCo does.** The same creep at rest as MuJoCo's C engine (1,293 um/s, the MuJoCo
  deep dive's run 001), nearly the same depth at rest (17.08 um at 2 ms, against 17.06 um), Coulomb's friction over
  an impact, and at 2 ms the same slide as
  MuJoCo's C engine plays for a free cube (126,772 um, the MuJoCo deep dive's run 005). With friction 0 it stops being
  a number at the first contact, at every step; MuJoCo Warp warns that a friction under 1e-5 with condim 3 "may cause
  NaN", where MuJoCo's C engine raises it to 1e-5 and plays on.
- **SemiImplicit and Featherstone give friction above Coulomb's limit** (known issue N1): a slide stops at a third of
  Coulomb's distance at every step from 0.5 ms down, the deceleration growing as the cube slows (2.1 times Coulomb's
  near 1 m/s, 9.4 times near the end), and an impact takes 45% more friction than Coulomb allows. The reported cause
  is the Huber norm that smooths the friction's direction (`friction_smoothing`, 1.0 m/s by default): run 002 tests
  it. At rest their friction is a damper: the hold creeps at 735 um/s, the push over four corners' friction stiffness
  (2.94 N over 4 x 1,000 N s/m), and the cube rests 0.98 mm deep, its weight over four corners' contact stiffness. At
  2 ms both are unstable on this cube with their defaults: it hops and tumbles (it turns by up to 1.65 rad).
- **XPBD gets the slide and the impact right**, creeps at rest in proportion to the step (10.9 mm/s at 2 ms to 0.17 mm/s
  at 0.031 ms), and bounces 10% to 12% of the drop height with a restitution of 0, more as the step is refined.
- **VBD's motion gets worse as the step is refined.** Its free fall runs 0.25% slow at 0.5 ms, 2.7% slow at 0.125 ms
  and 56% fast at 0.031 ms; its hold creeps faster (12 mm/s to 614 mm/s) and its slide goes further (41% past
  Coulomb's distance at 2 ms; at 0.031 ms it never stops). The pattern fits positions held in 32-bit floats: at
  0.031 ms gravity moves the cube 9.6 nm a step, less than the 14.9 nm between neighbouring 32-bit numbers near the
  cube's height of 0.15 m; at 0.5 ms the step is 164 of them and the error 0.25%. That is a hypothesis for a study,
  not yet a finding.
- **VBD-ALM**, the coming default, holds at rest at 2 ms and 0.5 ms, but its slide still goes 29% past Coulomb's
  distance and an impact takes a sixth of Coulomb's friction; it falls as VBD does.

Next: run 002, the friction smoothing tested as N1's cause; VBD's free fall against the height and the precision.

Added 15 October 2026, when the record was checked end to end ([`docs/audit.md`](../../docs/audit.md)): the
decelerations above (8,315, 9,608, 12,067 and 36,912 mm/s2) are SemiImplicit's, made with the measure's `accel`;
Featherstone's are 8,315, 9,608, 12,068 and 36,923. The free-fall table and the resting depths were read from the
rig's files without the measure, which has no vertical reading; made again the same way, they are the same.
