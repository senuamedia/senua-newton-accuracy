# Run 014: the two-link chain on Newton's solvers

15 October 2026. Not registered: a design probe on the Newton host, by [`play.sh`](play.sh) (pushed before its
plays); reading `reading.txt`, re-made byte for byte on the laptop from the same files. The rig
[`tools/nwt_chain.py`](../../tools/nwt_chain.py) is the first deep dive's `sdx_chain` and the MuJoCo deep dive's
`mjc_chain` scene and format, read by the same measure, Senua AI's `sx_contact chain`. The scenes are the MuJoCo deep
dive's run 007: the free chain (arms of 1.2 and 0.6 kg, no gravity, set turning at 2.5 and 1.5 rad/s) and the swinging
chain (gravity, released at rest from 0.4 and -0.7 rad). Each is played for 2 s at 10 ms over 1, 4, 16 and 64, on
every Newton solver that plays joints, as released, and with the one option beside each that matters here.

Before any play, the rig's start state was checked against MuJoCo's run 007 files. The first line of every play (the
state before any step) is the same, byte for byte, on every solver, for both scenes.

**Two plays.** The first (03:47 to 03:56 UTC, kept in [`first_play/`](first_play/)) read 64 of 80 plays. The 16
SemiImplicit plays crashed in the rig: once their state passed about 1e32, its conversion to micro-units overflowed in
32-bit arithmetic. The rig was corrected (conversion in 64-bit arithmetic; a state beyond the format's 64-bit whole
numbers ends the file with a STATS line saying where) and all 80 were played again, 04:03 to 04:12 UTC. Every rig
exited 0. The readings below are the second play's.

## The free chain: nothing acts on it, so its energy and its angular momentum must stay as they were

Kinetic energy after 2 s, and angular momentum about the first joint, as a change from the start:

| Solver | 10 ms | 2.5 ms | 0.625 ms | 0.156 ms |
|---|---|---|---|---|
| Featherstone, energy | **+9.72%** | +2.48% | +0.61% | +0.15% |
| Featherstone, momentum | **+6.60%** | +1.81% | +0.45% | +0.11% |
| The MuJoCo solver (implicitfast, Newton's default; Euler is the same to the byte), energy | **+9.72%** | +2.48% | +0.61% | +0.15% |
| The same, momentum | **+6.60%** | +1.81% | +0.45% | +0.11% |
| The MuJoCo solver with RK4, energy | 0 (3 ppm) | 0 (1 ppm) | 0 (3 ppm) | 0 (5 ppm) |
| The same, momentum, largest along the way | 1 ppm | 2 ppm | 3 ppm | 5 ppm |
| XPBD, energy | **-30.1%** | -11.0% | -3.3% | -0.91% |
| XPBD, momentum | **-11.3%** | -3.5% | -0.94% | -0.23% |
| VBD, energy | **-46.0%** | -11.3% | -3.2% | -3.8% |
| VBD, momentum | **-22.8%** | -3.6% | -0.87% | -1.7% |
| VBD with `rigid_compliant_alm`, energy | **-45.9%** | -11.2% | -3.1% | -7.6% |
| VBD with `rigid_compliant_alm`, momentum | **-22.8%** | -3.5% | -0.79% | -2.7% |
| SemiImplicit, with or without its angular damping | **blows up** | blows up | blows up | blows up |

MuJoCo's C engine on the same scene (run 007 of the MuJoCo deep dive): +9.72% and +6.60% at 10 ms under Euler, the
same to the part per million as Featherstone and the MuJoCo solver here. The kinetic energy at the end, per million of
the start: 1,097,162 under MuJoCo's C engine, 1,097,162 under Featherstone, 1,097,161 under the MuJoCo solver; the
momentum's change, per million: 66,018, 66,018 and 66,017. Under RK4, MuJoCo's C engine keeps both to 1 ppm.

## The swinging chain: gravity only, so its total energy must stay as it was

The largest departure of the total energy over the 2 s, as a share of the largest kinetic energy:

| Solver | 10 ms | 2.5 ms | 0.625 ms | 0.156 ms |
|---|---|---|---|---|
| Featherstone | 12.2% | 17.0% | 6.2% | 1.7% |
| The MuJoCo solver (implicitfast or Euler) | 12.2% | 17.0% | 6.2% | 1.7% |
| The MuJoCo solver with RK4 | 1.1% | 0.0010% | 0.0005% | 0.0013% |
| XPBD | **117.3%** | 49.5% | 21.1% | 8.3% |
| VBD | **72.1%** | 58.2% | 24.0% | 5.2% |
| VBD with `rigid_compliant_alm` | **71.5%** | 58.2% | 27.6% | 11.3% |
| SemiImplicit, with or without its angular damping | **blows up** | blows up | blows up | blows up |

MuJoCo's C engine: 12.2%, 17.0%, 6.2% and 1.7% under Euler; 1.1%, 0.0012%, 0.0001% and 0.0001% under RK4.

## SemiImplicit blows up

Every SemiImplicit play leaves the range of the format's 64-bit whole numbers (a number of its state past about 9.2
million, in metres, metres a second or radians) long before its 2 s: at the 7th step at 10 ms, the 10th or 11th at
2.5 ms, the 19th or 20th at 0.625 ms, and after 0.40 s to 0.97 s at 0.156 ms (`runs/*_semi*.stats`,
`out_of_range_at_step`). Its angular damping, on (0.05, as released) or off, changes the step at which it does so
only at the finest step. SemiImplicit holds a joint
together with an explicit penalty, by default `joint_attach_ke` 10,000 and `joint_attach_kd` 100; whether that is the
cause is not tested.

## What the probe shows

- **Featherstone and the MuJoCo solver add energy and momentum to a free chain, exactly as MuJoCo's C engine does.**
  They gain 9.7% of its kinetic energy and 6.6% of its angular momentum in 2 s at 10 ms, and the error falls in
  proportion to the step: first order. Newton's three readings agree with MuJoCo's to the part per million, in 32-bit
  arithmetic against 64-bit.
- **The MuJoCo solver's RK4 keeps a free chain's energy and momentum to 5 ppm at every step**, and the swinging
  chain's energy to 1.1% at 10 ms and 0.0013% or better below it, the floor of 32-bit arithmetic: as MuJoCo's C engine
  does.
- **XPBD and VBD take energy out of a free chain**: 30% and 46% at 10 ms, less as the step shrinks to 0.625 ms.
  XPBD's loss keeps falling at 0.156 ms; VBD's does not: at 0.156 ms it loses more than at 0.625 ms (3.8% against
  3.2%; with `rigid_compliant_alm`, 7.6% against 3.1%). At 10 ms XPBD keeps 69.9% of the energy and 88.7% of the
  momentum; SuperDex as shipped kept 70.0% and 88.4% of the same chain's (the first deep dive's Study 12).
- **SemiImplicit cannot play this chain at any step played.**
- Featherstone's angular damping (0.05 as released) changes nothing here: with it and without it, every file is the
  same to the byte.

Next: the swinging chain with the MuJoCo solver's RK4 on contact (MuJoCo's C engine found RK4 puts contact
refinement out of order); SemiImplicit's chain against `joint_attach_kd`.
