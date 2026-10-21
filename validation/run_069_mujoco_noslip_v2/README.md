# Run 069: run 067 again, with the noslip patch's second form (issue 15)

Not registered: a design probe. Run 067's play script and predictions, unchanged but for the patch's file and this
run's folder ([`play.sh`](play.sh)), pushed before any play. Newton 1.7.0 from PyPI, and the same with the noslip
patch's second form first on the path
([`mujoco_noslip_v2_on_1.7.0.diff`](../../patches/in_design/mujoco_noslip_v2_on_1.7.0.diff), sha256
1b8d36101576365d...).

## Why

[Run 067](../run_067_mujoco_noslip/README.md) found that Newton makes MuJoCo Warp's model on the CPU path too, and MuJoCo
Warp refuses noslip, so the first form never reached MuJoCo's C engine. The second form sets `noslip_iterations` and
`noslip_tolerance` on the compiled MuJoCo model the C engine steps, after MuJoCo Warp's model is made from it, when
`use_mujoco_cpu` is set; on the Warp path it sets them on the spec as before, so MuJoCo Warp refuses them with its own
message.

## Predictions

Run 067's, unchanged: N0 safe when off (6 of 6), N1 the release's creep at least 500 um/s on both cones and with noslip
within 10 um/s on both at both steps, N2 the Warp path refuses noslip, N4 the slide within 1 in 100 of the same play
without noslip, N5 the ground force within 1 in 100 of the weight.

## The result: 10 of 12 checks held

Played 20 October 2026, 09:55 to 09:56 UTC, on the second x86-64 host, from the record at 95326ce (these predictions
pushed); `measured.txt` and `checks.txt` made there.

| The hold's creep, um/s (the answer 0) | 2 ms | 0.5 ms |
|---|---|---|
| The CPU path, pyramidal cone | 1,293 | 1,293 |
| The CPU path, pyramidal cone with noslip | 1,293 | 1,293 |
| The CPU path, elliptic cone | 765 | 765 |
| **The CPU path, elliptic cone with noslip** | **0** | **0** |

| With the elliptic cone | Without noslip | With noslip |
|---|---|---|
| The slide from 1 m/s, um, 2 ms | 101,354 | 101,339 |
| The slide, 0.5 ms | 102,037 | 102,026 |
| The ground's force after a drop, mN (weight 9,800) | | 9,800 at both steps |

- **MuJoCo's recommended configuration reaches the C engine through Newton, and holds.** With the elliptic cone and
  noslip the cube pushed at 0.6 of what friction holds does not move at either step, where the elliptic cone alone
  creeps 765 um/s and the default cone 1,293; the slide and the weight are kept within 0.02%. With noslip unset the
  patch's tree is the release byte for byte (6 of 6); the Warp path refuses noslip with MuJoCo Warp's message.
- **N1's high line failed on the pyramidal cone:** with noslip it creeps 1,293 um/s at both steps, as without; at 0.5
  ms its file is the play without noslip byte for byte, at 2 ms it differs from line 10 with the same creep. The
  prediction assumed noslip holds on either cone; it holds on the elliptic one, the cone MuJoCo recommends with it.
- For a study: issue 15 on the CPU path, the elliptic cone with noslip; the Warp path waits on MuJoCo Warp's noslip.
