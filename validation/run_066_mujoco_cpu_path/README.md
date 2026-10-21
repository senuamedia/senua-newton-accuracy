# Run 066: the MuJoCo solver's CPU path (issue 24)

Not registered: a design probe, its predictions pushed with [`play.sh`](play.sh) before any play. Newton 1.7.0 from
PyPI (Study 7's environment, on the second x86-64 host), the MuJoCo solver with `use_mujoco_cpu=True` (MuJoCo's C
engine, `mujoco` 3.15.0, stepping Newton's model) beside its default MuJoCo Warp path. Measured by Senua AI's
`sx_contact` (`rest`, `final`, `stop`, `creep`, `chain`) and judged by its `rule`.

## The question

Users report that the MuJoCo solver's CPU path drops valid contacts, discards applied forces and supports one world
(N9: Newton's compatibility guide, #3805, #3128, #4612). The record plays the MuJoCo Warp path on Warp's CPU device, so
issue 24 was never played. On Newton 1.7.0, read in the source (`solver_mujoco.py`, `_apply_mjc_control`): the CPU path
writes the body forces (`xfrc_applied`), joint forces (`qfrc_applied`) and controls into MuJoCo's data before every
`mj_step`, and collides with MuJoCo's own collision, not Newton's. Does it play the record's scenes as the Warp path
does?

## What is played

The MuJoCo solver, each scene on both paths, at 2 and 0.5 ms:

- **K1 a drop**: the cube (1 kg, half-size 0.05 m) from 80 mm, friction 0.5, 1 s: the ground's mean force over the
  second half (its weight, 9,800 mN).
- **K2 a push in free space**: no gravity, 1 m up, pushed by 0.05 N from rest, 1 s: **50,000 um/s** at the end.
- **K3 a slide**: from 1 m/s on the ground, friction 0.5, 0.5 s: the distance slid.
- **K4 a hold**: run 001's (friction 0.5, 2.94 N from 0.5 s, 2 s): the creep. Reported.
- **K5 a joint torque**: run 054's arm under 1 N m, 0.05 s: the angle.
- **K6 a free chain**: Study 9's chain, 2 s, no gravity: its kinetic energy at the end, per million of its start.

## Predictions (pushed before the plays)

| Check | Prediction | Why |
|---|---|---|
| K0 | Every CPU-path play a number throughout | MuJoCo's C engine in 64 bits on these scenes |
| K1 | The CPU path's ground force within 1 in 100 of the Warp path's, at both steps | The contacts are MuJoCo's own on the CPU path; a box on a plane gives its four corners in both |
| K2 | Both paths 50,000 um/s within 1 in 1,000, at both steps | The body force is written into `xfrc_applied` every step in 1.7.0: if the report's discarded forces stood, the CPU path would read 0 |
| K3 | The CPU path's slide within 1 in 100 of the Warp path's | The same pyramidal cone and solver settings, converted once |
| K5 | The CPU path's angle within 1 in 100 of the Warp path's | The joint force through `qfrc_applied` |
| K6 | The CPU path's chain energy within 1 in 1,000 of the Warp path's, at both steps | The same Euler integrator; run 014 found the Warp path equal to MuJoCo's C engine on a chain to the part per million |

Not played: more than one world (the CPU path takes one, by its own documentation and code: `separate_worlds` is off
for it), which needs a scene of several worlds.

## The result: 12 of 12 predictions held

Played 20 October 2026, 09:31 to 09:32 UTC, on the second x86-64 host, from the record at a39c8d3 (these predictions
pushed); `measured.txt` and `checks.txt` made there.

| Reading | 2 ms, Warp path | 2 ms, CPU path | 0.5 ms, Warp path | 0.5 ms, CPU path |
|---|---|---|---|---|
| K1 the drop's ground force, mN (weight 9,800) | 9,800 | 9,800 | 9,800 | 9,800 |
| K2 the push in free space after 1 s, um/s (50,000) | 50,000 | 50,000 | 50,001 | 50,001 |
| K3 the slide, um | 101,354 | 101,354 | 102,176 | 102,176 |
| K4 the hold's creep, um/s (reported) | 1,293 | 1,293 | 1,293 | 1,293 |
| K5 the torque's angle, urad | 5,166 | 5,166 | 5,017 | 5,017 |
| K6 the chain's kinetic energy at the end, per million | 1,009,410 | 1,009,408 | 1,002,383 | 1,002,383 |

Every CPU-path play is a number throughout. Its files are not the Warp path's: the drop's, the slide's, the hold's and
the chain's differ from the Warp path's in their low digits on 1 to 3,836 lines (MuJoCo's C engine in 64 bits against
MuJoCo Warp in 32), the push's and the 2 ms torque's are the same, which is how the CPU path was checked to have run.

## What it shows

**The reported faults of the MuJoCo solver's CPU path are not there on Newton 1.7.0** on these scenes: its contacts
carry the weight, its applied body force and joint force act, and it gives the Warp path's readings to the micrometre.
The hold creeps 1,293 um/s on both (issue 6). One world only, by its code; not played. Held to registered rules in
[Study 11](../../docs/studies/11-mujoco-noslip-cpu-featherstone-limit.md).
