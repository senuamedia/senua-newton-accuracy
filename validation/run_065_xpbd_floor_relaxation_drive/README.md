# Run 065: XPBD's speed floor, its relaxations and its drive (issues 17, 25 and 26)

Not registered: a design probe, its predictions pushed with [`play.sh`](play.sh) and
[`setup_engine.sh`](setup_engine.sh) before any play. Newton 1.7.0 from PyPI (Study 7's environment), and five engines
made from it by `setup_engine.sh`: Senua AI's speed-floor patch in design
([`xpbd_no_speed_floor_on_1.7.0.diff`](../../patches/in_design/xpbd_no_speed_floor_on_1.7.0.diff), switch
`NEWTON_XPBD_NO_SPEED_FLOOR=1`), pull request #4317, #4317 with the patch, pull request #4318 rebased onto 1.7.0
([`pr_4318_on_1.7.0.diff`](../../patches/upstream/pr_4318_on_1.7.0.diff): one hunk, a class variable, moved below the
block 1.7.0 has between it and its context; #4318 carries its own forms of #4316 and #4317), and #4318 with the patch
in its form for #4318's tree. Measured by Senua AI's `sx_contact` (`final`, `creep`) and judged by its `rule`.

## The questions

- **Issue 17.** After every correction XPBD sets a body's speed to zero when it is under 1e-4 m/s and its turning speed
  when under 1e-4 rad/s (`apply_body_deltas`, read in the source, F17). The patch is the same update without those
  lines. Is a slow body stopped as released and kept with the patch, is Newton the release byte for byte with its
  switch unset, and what does the floor hide?
- **Issue 25.** XPBD at its default relaxations (0.7 linear, 0.4 angular) answers a joint torque 1.75 times too
  strongly (run 054). #4317 scales a positional row's moment by the linear relaxation, as its linear part; run 054
  found it right at 0.1 ms and the arm held at 0.05 ms. Is that hold the floor?
- **Issue 26.** XPBD's drive is a compliance row whose stiffness grows with the iteration count (run 054: 0.69 to 11.1
  times). #4318 adds `joint_drive_mode="pd"`: the drive's `ke` and `kd` at any iteration count, the force clamped at the
  effort limit. Is it the drive's own spring at every count?
- **Issues 7 and 8, reported.** Study 5's four scenes on #4318, beside #4316's (Study 8).

## What is played, and the closed forms

XPBD in every play.

- **A, the floor** (as released, the patch with its switch unset, and set): A1 a free body (no gravity, 1 m up, 1 s)
  at 50 um/s, 1 ms: it keeps 50 um/s. A2 the same body from rest pushed by 0.05 N (1 kg), at 1 and 4 ms: after 1 s,
  **50,000 um/s**. A3 an arm on a hinge (1 kg, half-size 0.05 m, 0.5 m out, no gravity) turning at 50 urad/s: it keeps
  50 urad/s. A4 run 044's hold (1 kg, half-size 0.05 m, friction 0.5, pushed from 0.5 s, 2 s, 32 iterations): 2.94 N
  at 0.125 ms, 1.47 N at 0.5 ms, 2.94 N at 2 ms.
- **B, a torque and gravity** (run 054's arm: 1 kg, 0.05 m, 0.5 m, 0.05 s), at 0.1 and 0.05 ms, as released, with the
  patch, #4317, #4317 with the patch, #4318, #4318 with the patch: under 1 N m from rest **4,967 urad**; released level
  under gravity **-24,338 urad** (run 054's closed forms).
- **C, the drive** (run 054's: 10 N m/rad toward 0 from 0.2 rad at rest, 0.1 s), at 1, 2, 4, 8 and 16 iterations,
  at 0.1 and 0.05 ms: as released, and on #4318 with `joint_drive_mode` `pd` and `implicit`: **161,563 urad**. With an
  effort limit of 0.5 N m (the spring's torque at the start is 2 N m), at 2 iterations, as released and with `pd`: the
  torque is the limit while the spring's is above it (all 0.1 s, the arm at more than 0.05 rad), so theta = 0.2 -
  0.5 t^2 / (2 I), I = 0.25167 kg m^2: **190,066 urad**.
- **D, reported**: Study 5's none, inside (limits -0.5 and 5 rad), reach (-0.5 and 3.6) and below (-0.5 and 2.5) at
  1.6 and 0.32 ms on #4318.

## Predictions (pushed before the plays)

| Check | Prediction | Why |
|---|---|---|
| A0 | The patch's tree with its switch unset gives every A play's file byte for byte the release's (7 of 7) | The stock kernel is launched |
| A1 | As released the free body reads 0 at the end; with the patch 50 um/s (within 1) | 50 um/s is under the floor; nothing else acts |
| A2 | As released, at 1 ms the pushed body never moves (0); at 4 ms it reaches 50,000 um/s (within 1 in 1,000); with the patch 50,000 at both | Each 1 ms step adds 50 um/s, zeroed; each 4 ms step adds 200 um/s, above the floor, and it never falls back under |
| A3 | As released the arm stops (0); with the patch 50 urad/s (within 1 in 10) | 50 urad/s, and the arm's centre at 25 um/s, are under both floors |
| A4 | As released the 0.125 ms hold and the half push read 0; with the patch each between 50 and 200 um/s (run 044's estimate, 95 and 100); the 2 ms hold within 1 in 100 of the release's | The floor hides XPBD's creep where it is under 0.1 mm/s (issue 6); at 2 ms the creep is 15 times above it |
| B1 | As released and with the patch alone the torque answer at least 1.5 times the closed form, at both steps | The floor is not the cause of issue 25 |
| B2 | #4317 and #4318, each with the patch, the torque answer within 1 in 100, at both steps | The consistent rows; nothing under the floor stopped |
| B3 | Gravity within 1 in 100 on all four, at both steps | Gravity's speed gain a step is above the floor at both |
| B4 | #4317 and #4318 alone, at 0.05 ms, the torque answer under a tenth of the closed form | The arm's centre gains 99 um/s a step, under the floor (run 054 read 11 urad) |
| B5 | #4317 and #4318 alone, at 0.1 ms, within 1 in 100 | 199 um/s a step, above the floor (run 054 read 4,964 on #4317) |
| C1 | As released the drive at 1 iteration stays above 165,000 urad and at 16 iterations goes past 0, at both steps | Run 054 |
| C2 | `pd`: within 1 in 400 of 161,563 urad at every iteration count, at both steps | The drive's spring as a joint force, its stiffness its own |
| C3 | `pd` with the effort limit: within 1 in 400 of 190,066 urad | The force clamped at the limit |
| C4 | As released the effort limit is ignored: the play byte for byte the one without it | N17's report |

Reported, not predicted: `implicit` at each count (exact when its iterations converge, by #4318's own account), the
contact suite with the patch (run beside this probe), and D's readings beside Study 8's.

## The result: 32 of 32 predictions held

Played 20 October 2026, 09:24 to 09:29 UTC, on the Newton host, from the record at its commit 5f34e82 (these
predictions pushed); `measured.txt` and `checks.txt`, made there by the measure's host build.

| | As released | The patch, switch unset | The patch |
|---|---|---|---|
| A1 a free body at 50 um/s, after 1 s | 0 | 0 | **50** |
| A2 pushed by 0.05 N from rest, after 1 s (50,000 um/s), 1 ms | 0 | 0 | **50,001** |
| A2, 4 ms | 50,000 | 50,000 | 50,000 |
| A3 an arm turning at 50 urad/s, after 1 s | 0 | 0 | **50** |
| A4 the hold at 0.125 ms, mean creep um/s (the answer 0) | 0 | 0 | **68** |
| A4 the half push at 0.5 ms | 0 | 0 | **104** |
| A4 the hold at 2 ms | 1,531 | 1,531 | 1,531 |

Every play with the switch unset is the release's byte for byte (7 of 7).

| Run 054's arm, the angle after 0.05 s, urad | 0.1 ms | 0.05 ms |
|---|---|---|
| Under 1 N m: the closed form | 4,967 | 4,967 |
| As released | 8,670 | 8,648 |
| The patch alone | 8,670 | 8,659 |
| #4317 | 4,964 | **11** |
| #4317 with the patch | **4,979** | **4,972** |
| #4318 | 4,964 | **11** |
| #4318 with the patch | **4,979** | **4,972** |
| Under gravity: the closed form | -24,338 | -24,338 |
| As released | -24,265 | -24,241 |
| #4317 and #4318, with and without the patch | -24,385 | -24,361 |

| The drive, the angle after 0.1 s, urad (closed form 161,563) | 1 | 2 | 4 | 8 | 16 iterations |
|---|---|---|---|---|---|
| As released, 0.1 ms | 173,011 | 147,266 | 99,348 | 16,921 | -100,950 |
| #4318 `pd`, 0.1 ms | **161,520** | **161,524** | **161,522** | **161,527** | **161,529** |
| #4318 `pd`, 0.05 ms | **161,547** | **161,549** | **161,543** | **161,540** | **161,542** |
| #4318 `implicit`, 0.1 ms (reported) | 161,526 | 161,529 | 161,526 | 161,533 | 161,533 |
| #4318 `implicit`, 0.05 ms (reported) | 161,551 | 161,551 | 161,545 | 161,543 | 161,545 |

With the effort limit of 0.5 N m, `pd` reads 190,058 and 190,067 urad against 190,066; as released the limit changes
nothing (the play byte for byte the one without it). The joint's speed, which XPBD gives through its bodies, is read
less closely than its angle: under `pd` -731,273 to -755,028 urad/s against the closed form's -742,960, and under the
effort limit -196,275 and -217,948 against -198,670.

**D, reported** (Study 5's scenes, #4318; Study 8's #4316 beside them): inside ends as none to the microradian (no throw
past pi, as #4316); reach leaves its limit turning back at 2.49 and 2.55 rad/s (2.82 and 2.62 rad), against #4316's
2.37 and 2.43: the limit's throw-back (issue 8) stands; below ends at 1.28 and 1.06 rad.

## What it shows

- **Issue 17: the speed-floor patch does what it was made for.** A body slower than 0.1 mm/s, a force too small to
  give that speed in one step, and a slow turn are each stopped by XPBD as released and kept with the patch; with its
  switch unset Newton is the release byte for byte. The patch shows what the floor hid: XPBD's creep at rest, 68 and 104
  um/s where the release reads 0, as run 044 estimated (issue 6, still open).
- **Issue 25: #4317 is right, once the floor is off.** Its torque answer, 11 urad at 0.05 ms, is the floor stopping
  the arm (its centre gains 99 um/s a step); with the patch it is within 0.3% at both steps, as #4318's own form.
  Unequal relaxations alone (the patch without #4317) leave the torque answer 1.74 times too strong: the floor is not
  issue 25's cause.
- **Issue 26: #4318's `pd` drive is its own spring at every iteration count**, within 0.03% from 1 to 16 iterations at
  both steps, where the release's drive spans 173,011 to -100,950 urad; it honours the effort limit, which the release
  ignores. `implicit` reads the same to 0.01%.
- **Issues 7 and 8 on #4318:** as #4316, the throw past pi gone and the limit's throw-back left.
- For a study: issue 17 by the patch; issue 25 by #4317 (or #4318) with the patch; issue 26 by #4318's `pd`.
