# The patches to MuJoCo Warp 3.15.0

MuJoCo Warp as Newton 1.7.0's environment installs it (`mujoco-warp==3.15.0`, Study 7's environment). Checksums in
[`SHA256SUMS`](SHA256SUMS).

| File | Applied to | What it does |
|---|---|---|
| [`noslip.diff`](noslip.diff) | MuJoCo Warp 3.15.0 | MuJoCo's noslip solver (`solNoSlip`, with its helpers and `mju_QCQP2`, `mju_QCQP3`, `mju_QCQP`) ported as a module run after MuJoCo Warp's main solve, per world, then MuJoCo's finish and M qacc for the implicit integrators; MuJoCo's `noslip_iterations` and `noslip_tolerance` carried into MuJoCo Warp's options, which refused a positive count. Nothing of it runs with MuJoCo's default 0. Not with the discrete integrator or sleeping. With the record's Newton noslip patch ([`../newton-1.7.0/mujoco_noslip.diff`](../newton-1.7.0/mujoco_noslip.diff)), **validated** by [Study 25](../../docs/studies/25-mujoco-warp-noslip.md) (issue 15, 14 of 14 rule lines) |
