# Seventh pre-registration: the record on Newton 1.7.0

Registered 19 October 2026, before any play of this registration existed. To be played once, as run 052.

## The question

This record was made on Newton 1.6.1. Newton 1.7.0 was released on 14 October 2026 (MuJoCo and MuJoCo Warp 3.15 in
place of 3.12, Warp 1.18.0 unchanged). Do the record's findings and its validated patches hold on 1.7.0? Every run,
001 to 051, is played again by its own script on 1.7.0, with the record's patches rebased onto it, and compared with
the record.

## What 1.7.0 changed in the code the findings were traced to

Read in the two releases' source before this registration (both taken from PyPI and checked file for file):

- Every source line a finding was traced to is unchanged: XPBD's swing gradient, its hemisphere flip, its 1e-4 speed
  floor and its anchor rows' angular relaxation (F13, F14, F17); `joint_force`'s limit damper (F16); the contact
  kernel's Huber-norm friction direction (F1).
- The functions the patches copy are unchanged, byte for byte: XPBD's `solve_body_joints` and `apply_body_deltas`, its
  restitution kernels, VBD's `update_body_velocity`, the MuJoCo solver's limit conversion, and every helper the patches
  import.
- One function they copy changed: SemiImplicit's and Featherstone's body contact moved from the kernel
  `eval_body_contact` into a function `_eval_body_contact` that the kernel launches, and it now subtracts a contact's
  tangential surface velocity from the slip, zero unless a mesh authors one (none in this record).

## The patches on 1.7.0

Rebased in [`patches/newton-1.7.0/`](../patches/newton-1.7.0/) (its README says how), one file per family, each family's latest form (which
carries its earlier forms' switch values):

| Patch | How it was rebased |
|---|---|
| `unit_friction_direction.diff` | The change made in a copy of 1.7.0's `_eval_body_contact` (a three-way merge of the 1.6.1 copy's change onto it: only the friction lines differ from 1.7.0's), launched by a copy of 1.7.0's kernel |
| `contact_damping_no_pull.diff` | The same, for the normal force, in copies of 1.7.0's function and of the unit-direction copy's; applied on top of the first, as on 1.6.1 |
| `xpbd_restitution_friction_v2.diff` | The 1.6.1 file as it stands, applied without offset |
| `vbd_carried_velocity_v2.diff` | The same |
| `mujoco_limit_force_space.diff` | The same |
| `xpbd_joint_angle_v3.diff` | The same (switch values 1, 2 and 3: runs 035 to 051's three forms) |

The checksums are listed in [`patches/newton-1.7.0/SHA256SUMS`](../patches/newton-1.7.0/SHA256SUMS), committed with
this registration.

## Engines

- **1.7.0**: Newton 1.7.0 from PyPI (`newton[sim]==1.7.0`, which resolves MuJoCo 3.15.0, MuJoCo Warp 3.15.0, Warp
  1.18.0, NumPy 2.5.4) in its own environment; each patched engine is that environment with the PyPI package's source,
  patched, first on the path.
- **1.6.1, the control**: Newton 1.6.1 from PyPI with the record's environment (MuJoCo 3.12.0); each patched engine
  the same way, from the PyPI 1.6.1 source and the record's 1.6.1 patch files of the same families.

Every run's own script picks its engines from its environment variables (`STOCK_VENV`, `PATCHED_VENV`,
`XPBD_VENV`, `NORMAL_VENV`, `VBD_VENV`, `XLIM_VENV`, `MJLIM_VENV`, `XSG_VENV`, `V3_VENV`); scripts that play the
release with the environment on are run with the release's environment on. Warp's CPU device. The rigs as committed
(`tools/`), unchanged.

## What is played

The runner, [`validation/run_052_study_07/replay.sh`](../validation/run_052_study_07/replay.sh), in a clean copy of
the repository for each engine: every run's kept outputs cleared (its README, its scripts and their committed inputs
kept), then every run 001 to 051 played by its own script, in order, so a run that reads an earlier run's files reads
the replayed ones. Readings are made by Senua AI's `sx_contact` as built for the latest runs (sha256 of the binary
b1d1b2906041219e...) and its contact suite runner (553d46ecdaf2bd95...). Then
[`judge.sh`](../validation/run_052_study_07/judge.sh) compares every file the record keeps with the replay's, byte for
byte. Set aside from the byte comparison, because they cannot be the same on a new engine or a new day, and reported:
start and finish times, logs, the provenance files that list a patched source's state, and the engine's version in
each rig's STATS line (compared with the version set aside).

## The rules

Each judged by `sx_contact rule`, from the counts `judge.sh` makes, and nowhere else.

| Rule | Statement | Kind |
|---|---|---|
| R1 the record plays on 1.7.0 | every run's script runs to its end and every file the record keeps for it is written | eq (files missing, 0) |
| R2 unchanged kernels play the same | every kept play file of SemiImplicit, Featherstone, XPBD and VBD, release and patched arms, is byte-identical on 1.7.0 to the record's, and its STATS line too with the version set aside (predicted from the source: the code these solvers run for the record's scenes is unchanged, and the one physics change, the surface velocity, is zero) | eq (such files that differ, 0) |
| R3 the validated studies hold | in the replayed rules of Studies 1, 2, 3, 4 and 6, every rule line holds, as each study's own runner judges it | eq (rule lines failing, 0) |
| R4 Study 5 as it was | Study 5's rule lines read on 1.7.0 as on 1.6.1: R4's two failing lines fail, every other line holds | eq (lines that read differently, 0) |

The study holds if every rule holds. A rule that fails is reported with its numbers and every file behind it.

Reported, not deciding:

- **The MuJoCo solver on 1.7.0.** MuJoCo Warp moved from 3.12 to 3.15, so its plays may differ. Every MuJoCo solver
  play file is compared; where one differs, the run's own predictions and the findings it supports (F3, F7, F8, F12,
  F15 and Study 6) are read again from the replayed files.
- **The control on 1.6.1.** The same replay on 1.6.1 with the same patch families: whether the whole record plays
  again byte for byte. A file that differs on both engines is not 1.7.0's doing (for instance a run made with an
  earlier form of a patch than its family's latest); a file that differs only on 1.7.0 is.
- **Readings that differ while every file they read is the same**: the measure, not the engine, reported and traced.

If R2 holds, every finding on SemiImplicit, Featherstone, XPBD and VBD stands on 1.7.0 with its numbers unchanged.

## The runner and its dry run

`setup_engine.sh` (each engine's environments and patched trees, with a manifest), `replay.sh` and `judge.sh` are
committed with this registration. Before the study they are played once with `DRY=1`:
runs 006 and 011 only (two short probes, VBD and the MuJoCo solver), on 1.7.0, into `dry/`, only to check that the
runner clears, replays, compares and counts; no rule is read from it.
