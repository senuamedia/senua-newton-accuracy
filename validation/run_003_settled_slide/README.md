# Run 003: the slide from a cube already at rest

15 October 2026. Not registered: a design probe following run 002, by [`probe.sh`](probe.sh); reading `reading.txt`.
Run 002's cube was set sliding at the instant it first touched the ground, and narrowing the friction smoothing gave
it a violent first millisecond. Here the cube (1 kg, half-size 0.05 m) is set down from 2 mm, left 0.3 s to settle,
then kicked to 1 m/s along x (the rig's new `kick` setting: the cube's speed set, on the body and its free joint,
before the step that starts at 0.3 s); friction 0.4. Check on the rig: a play without a kick is byte-identical to run
001's. The window that holds the kick at 0.125 ms (300 to 305 ms) is not a reading of friction and is left out.

| Solver, smoothing | Step | Reached, um (Coulomb 127,551) | Came back, um | Deceleration 310 to 320 ms, mm/s2 (Coulomb 3,920) | 330 to 350 ms | Largest turn |
|---|---|---|---|---|---|---|
| SemiImplicit, 1.0 (default) | 0.125 ms | 43,756 | 26,646 | 18,137 | 4,437 | 0.45 rad |
| | 0.031 ms | 43,401 | 26,450 | 24,855 | 3,872 | 0.45 rad |
| SemiImplicit, 0.01 | 0.125 ms | 38,321 | 37,889 | 5,355 | 185 | 0.61 rad |
| | 0.031 ms | 37,993 | 37,546 | 4,864 | 51 | 0.61 rad |
| Featherstone, 1.0 | 0.125 ms | 43,801 | 26,697 | 18,151 | 4,430 | 0.45 rad |
| | 0.031 ms | 43,439 | 26,494 | 24,900 | 3,867 | 0.45 rad |
| Featherstone, 0.01 | 0.125 ms | 38,455 | 38,024 | 5,349 | 183 | 0.62 rad |
| | 0.031 ms | 38,106 | 37,658 | 4,859 | 51 | 0.62 rad |
| XPBD | 0.125 ms | 127,468 | 0 | 3,919 | 3,919 | 0 |
| | 0.031 ms | 126,460 | 0 | 3,945 | 3,949 | 0 |
| The MuJoCo solver | 0.125 ms | 127,657 | 0 | 3,624 | 4,287 | 0.001 rad |
| | 0.031 ms | 126,654 | 0 | 4,599 | 3,615 | 0.001 rad |

## What it shows

- **Starting from rest does not help SemiImplicit and Featherstone.** Kicked from rest, the cube tips further than when
  it was set sliding at touch-down (0.45 rad with the default smoothing, against 0.22 in run 001), reaches about a third
  of Coulomb's distance and rocks back by two thirds of it (all of it with the smoothing at 0.01). The onset of run 002
  is not an artefact of touch-down: it comes with the kick, whatever the cube was doing before.
- **XPBD slides exactly as in run 001** (the same distances to the micrometre), at Coulomb's deceleration, without
  turning.
- **The MuJoCo solver slides Coulomb's distance** (within 0.7%), its deceleration over a window swinging between
  3,615 and 4,599 mm/s2: the hop of the MuJoCo deep dive's run 008, through Newton.
- A tipping cube hides the friction law behind its rocking. Run 004 slides a flat plate, which cannot tip.
