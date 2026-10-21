# Reproduce it

Everything here plays on a CPU, on Linux (Warp 1.18.0 publishes no wheel for Intel-based macOS, only for Apple silicon: its file list on PyPI). The rigs and scripts are in this
repository; the measuring program is the Senua AI Robotics Core's, its source as this record's later runs read it in
[`measure/`](../measure/README.md), and the suite's runner is the first deep dive's (`measure/runners/` in
`senuamedia/senua-superdex-accuracy`).

## 1. Newton

```
python3.12 -m venv venv && . venv/bin/activate
pip install "newton[sim]==1.6.1"
```

The exact environment of every run is in [`validation/run_001_design_probes/environment.txt`](../validation/run_001_design_probes/environment.txt)
(Warp 1.18.0, MuJoCo Warp 3.12.0, MuJoCo 3.12.0). For the patch, Newton's source at the commit in
[`UPSTREAM_COMMIT`](../UPSTREAM_COMMIT) with [the patch](patches.md) applied, installed in its own environment with
the same dependencies ([`environment_patched.txt`](../validation/run_005_unit_friction_direction/environment_patched.txt)).

## 2. A play

```
python tools/nwt_contact.py out.txt dt=0.000125 h0=0 vx0=1 mu=0.4 secs=1 solver=semi
python tools/nwt_chain.py chain.txt dt=0.0025 gravity=0 omega1=2.5 omega2=1.5 solver=featherstone
```

The rig's first lines list every setting: the scene, the solver, Newton's own solver options (`opt.<name>=<value>`), a
kick, a plate. It writes one line a step and prints one statistics line.

## 3. A run

Every run folder holds the script that played it, with its usage on its first lines; for example
`validation/run_004_plate/probe.sh <sx_contact>` from the repository root. The suite: `tools/contact_suite.sh <label>
solver=<name>`, read by [`measure/runners/sx_contact_suite.sh`](../measure/runners/sx_contact_suite.sh) (the first deep dive's
runner, published here as well).

## 4. Compare

A replay is compared byte for byte with the files the run kept (`cmp`). Each solver gives the same bytes on a repeated
play on the CPU (run 001); every patched run checks the patched Newton, switch unset, against Newton from PyPI.
