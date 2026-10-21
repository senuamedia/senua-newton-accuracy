# Run 067: MuJoCo's recommended configuration through Newton (issue 15)

Not registered: a design probe, its predictions pushed with [`play.sh`](play.sh) before any play. Newton 1.7.0 from
PyPI, and the same with Senua AI's noslip patch in design first on the path
([`mujoco_noslip_on_1.7.0.diff`](../../patches/in_design/mujoco_noslip_on_1.7.0.diff), sha256 954d4fe5b9bba993...).
Measured by Senua AI's `sx_contact` (`creep`, `stop`, `rest`) and judged by its `rule`.

## The question

MuJoCo recommends the elliptic cone with its noslip solver for contacts that must hold. Newton does not pass noslip
to the MuJoCo solver (issue 15, F7), and with the elliptic cone alone a held cube creeps 765 um/s (run 013), as
MuJoCo's C engine does. Read in the source: MuJoCo Warp 3.15 refuses a positive `noslip_iterations` ("noslip solver not
implemented", `mujoco_warp/_src/io.py`), so noslip can only reach MuJoCo's C engine, the solver's CPU path, which run
066 found plays the record's scenes as the Warp path does. The patch gives `SolverMuJoCo` `noslip_iterations` and
`noslip_tolerance`, set on MuJoCo's spec as every other solver option is. Does the CPU path then hold a cube at rest?

## What is played

Run 001's hold (1 kg, half-size 0.05 m, friction 0.5, pushed by 2.94 N, 0.6 of what friction holds, from 0.5 s, 2 s)
on the MuJoCo solver's CPU path, at 2 and 0.5 ms: the pyramidal cone and the elliptic, each without and with 10 noslip
iterations; the patch's tree with noslip unset beside the release, on the CPU and the Warp paths; a slide from 1 m/s
(friction 0.5) and a drop from 80 mm with the elliptic cone, without and with noslip; and the Warp path given noslip.

## Predictions (pushed before the plays)

| Check | Prediction | Why |
|---|---|---|
| N0 | With noslip unset the patch's tree gives the release's files byte for byte (6 of 6, both paths) | Nothing is set on the spec |
| N1 | As released the hold creeps 500 um/s or more on both cones; with noslip it is held within 10 um/s on both, at both steps | MuJoCo's noslip pass removes the slip a soft contact allows, within the friction cone |
| N2 | The Warp path given noslip refuses it, with MuJoCo Warp's own message | Read in the source |
| N4 | With noslip the slide's distance within 1 in 100 of the same play without it | Noslip keeps friction inside the cone; a slide is at the cone's edge |
| N5 | With noslip the dropped cube's ground force within 1 in 100 of its weight, 9,800 mN | Noslip acts on friction only |

## The result: 4 of 12 checks held; the patch's first form does not reach the CPU path

Played 20 October 2026 on the Newton host, from the record at 70653b7 (these predictions pushed); `measured.txt` and
`checks.txt` made there.

| The hold's creep, um/s (the answer 0) | 2 ms | 0.5 ms |
|---|---|---|
| The CPU path, pyramidal cone | 1,293 | 1,293 |
| The CPU path, elliptic cone | 765 | 765 |
| With noslip (either cone) | the solver is not made | the solver is not made |

- **N0 held** (6 of 6 files byte for byte with noslip unset), **N1's fault held** (1,293 and 765 um/s on the two
  cones, as run 013 and run 066 read), **N2 held** (the Warp path refuses noslip with MuJoCo Warp's message).
- **Every play given noslip on the CPU path failed to make its solver**, so N1's hold, N4 and N5 were not measured
  (8 checks, read by the rule as the wrong count of numbers): Newton makes MuJoCo Warp's model from the compiled
  MuJoCo model on both paths (`_convert_to_mjc` calls `mujoco_warp.put_model` whatever `use_mujoco_cpu` is), and MuJoCo
  Warp refuses a positive `noslip_iterations` there too. The prediction's premise, that noslip set on the spec reaches
  the C engine alone, was wrong; read in the traceback (`runs/log_n1_hold_elliptic_noslip_0.002.txt`).
- The patch's second form
  ([`mujoco_noslip_v2_on_1.7.0.diff`](../../patches/in_design/mujoco_noslip_v2_on_1.7.0.diff)) sets noslip on the
  compiled model the C engine steps, after MuJoCo Warp's model is made from it; [run 069](../run_069_mujoco_noslip_v2/README.md)
  plays it with these predictions unchanged.
