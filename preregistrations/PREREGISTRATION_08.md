# Eighth pre-registration: the fixes proposed upstream, measured

Registered 19 October 2026, before any play of this registration existed. To be played once, as run 053.

## The question

Three of the fixes proposed in Newton's open pull requests apply to Newton 1.7.0 ([the fixes already out
there](../docs/fixes-in-the-wild.md)). Measured as they stand, on 1.7.0, against the same rules Senua AI's own patches
were held to, beside Senua AI's patch for the same issue: do they hold?

| Pull request (its head when taken) | Our issue | The rules it is held to |
|---|---|---|
| [#4010](https://github.com/newton-physics/newton/pull/4010), rigid contact friction within the Coulomb cone (draft; 23bf6972) | 1 | Study 1's (run 008), R2 to R8 |
| [#4316](https://github.com/newton-physics/newton/pull/4316), XPBD hinge angles that cross plus or minus pi (open, changes requested; 41c03e1b) | 7 | Study 5's (run 037), R2 to R6 |
| [#4317](https://github.com/newton-physics/newton/pull/4317), XPBD joint relaxation made consistent (open; f9521577) | 25, and 8's coupling | reported only (below) |

Study 1's R1 and Study 5's R1 (the patch's off arm byte-identical to the release) read a switch these pull requests do
not have: every arm that plays the patched source plays the pull request. Those lines are reported, not judged.

## The patches

Taken with `gh pr diff` on 19 October 2026, the engine's source files only (the pull requests' tests and changelog
entries are not part of the engine), in [`patches/upstream/`](../patches/upstream/) with their checksums
([`SHA256SUMS`](../patches/upstream/SHA256SUMS)):

- `pr_4316.diff` and `pr_4317.diff` apply to 1.7.0's source as taken, with line offsets only (no fuzz).
- `pr_4010.diff` is written against a later main: its solver files apply with fuzz, and its first solver hunk would add
  an `import math` that 1.7.0's SemiImplicit solver already has. `pr_4010_on_1.7.0.diff` is its rebase: the pull
  request's every change, made in 1.7.0's files (the friction line in `_eval_body_contact`, the function 1.7.0's
  contact kernel launches and the only friction norm on the body contact path; the width's new default and its check
  in both solvers), without the duplicate import. It applies to 1.7.0 with no offset and no fuzz.

## Engines

Newton 1.7.0 from PyPI in Study 7's environment (`newton[sim]==1.7.0`). For each pull request, a source tree (the
environment's own Newton package, copied, with the diff applied, no fuzz allowed) first on the path; the release with
nothing ahead of it as the stock arm. Warp's CPU device. The rigs as committed (`tools/`), unchanged.

## What is played

The runner, [`validation/run_053_study_08/play.sh`](../validation/run_053_study_08/play.sh), plays each part in a
clean copy of the repository with Study 7's replay ([`replay.sh`](../validation/run_052_study_07/replay.sh), as
validated by Study 7), every patched arm's environment variable pointed at the pull request's environment:

| Part | Pull request | Runs played by their own scripts |
|---|---|---|
| A | #4010 | 008 (Study 1) |
| B | #4316 | 037 (Study 5), 048, 050, 051 |
| C | #4317 | 037 (Study 5), 048, 050, 051 |

Readings by Senua AI's `sx_contact` as Study 7's (sha256 b1d1b2906041219e...). The replayed run folders are kept in
run 053's folder by part.

## The rules

Each judged by `sx_contact rule` from the replayed studies' own rule lines, by
[`judge.sh`](../validation/run_053_study_08/judge.sh), and nowhere else.

| Rule | Statement | Kind |
|---|---|---|
| A1 #4010 holds Study 1 | every Study 1 rule line from R2 to R8, as Study 1's runner judges it with #4010 in its patched arms, holds | eq (lines failing, 0) |
| B1 #4316 holds Study 5 | every Study 5 rule line from R2 to R6, as Study 5's runner judges it with #4316 in its patched arms, holds | eq (lines failing, 0) |

Each pull request holds its study if its rule holds. A rule that fails is reported with every line behind it.

## Predicted from the source, before any play

- **#4010.** Friction becomes Coulomb's times |v| / sqrt(delta^2 + |v|^2) (Warp 1.18's `norm_pseudo_huber`, read: delta
  times sqrt(1 + |v|^2 / delta^2)), never above the cone, fading below the width. Study 1's cube slides at the new
  default width, 1 mm/s, far under its slip speeds: R3's slide predicted to hold, and R4's impact. Study 1's plate is
  played twice: at the solver's default width (the file named 1.0, run 008 passing no width: 1.0 m/s on the release,
  1 mm/s with #4010) and at 0.05 m/s, given. At 1 mm/s R3's plate is predicted to hold; at 0.05 m/s its friction fades
  under about 0.05 m/s and the slide's end lengthens by about delta^2 (1/2 + ln(2 v0 / delta)) / (2 mu g), so R3 is
  not predicted there. R5 (the plate's file the same at both widths) predicted to fail, by construction: friction at a
  slip v is Coulomb's times v / sqrt(delta^2 + v^2), which depends on delta at every slip speed. R2, R6 and R8
  predicted to hold; R7 (the set-down, the drop and the other solvers' slides unchanged) predicted to hold where the
  tangential slip is exactly zero and not predicted where it is merely small. **A1 predicted to fail (R5).**
- **#4316.** The angle of a joint with one rotational degree of freedom is measured within pi of its limit range's
  middle (the child joint frame turned by minus that middle), so a range narrower than 2 pi, past pi or not, reads
  correctly; Study 5's ranges (-0.5 to 5, to 3.6 and to 2.5 rad) are all narrower. Predicted: inside turns past pi
  without being thrown, but R3 (inside byte-identical to none) fails on its bytes, the turned frame changing the
  solve's rounding (the physical difference reported); R4 (held at 3.6 rad) fails, the limit's throw-back (issue 8,
  the limit sized by the arm's inertia about its own centre) being untouched; R5 (none and below byte-identical to
  the release) fails: the swing rows of every hinge near zero swing are now scaled by 2 where 1.7.0 leaves them, which
  for a hard row changes only the rounding (error and gradient scale together). R2 and R6 predicted to hold. **B1
  predicted to fail.**
- **#4317.** A positional row's moment is scaled by the linear relaxation, as its linear part, and the default linear
  relaxation is lowered from 0.7 to 0.5: every XPBD joint play changes. Not predicted beyond that; reported.

## Reported, not deciding

- Every replayed study's whole rule list, the R1 lines included, and every reading its runner measured (Study 1's and
  Study 5's `measured.txt`): each pull request's numbers beside the release's and beside Senua AI's patch on 1.7.0
  (Study 7's replay of runs 008 and 037).
- For B and C, runs 048, 050 and 051 read again: the limit's gain toward pi (048), the swing (050), the levers and
  relaxations (051), beside the record's three forms of the joint-angle patch; run 051's own checks.
- For C, Study 5's rules with #4317.
- Issue 25 itself (a pendulum under a joint torque and gravity with unequal relaxations) needs a joint torque the
  joint rig cannot apply yet; it is a later run.

## The runner and its dry run

[`setup_engine.sh`](../validation/run_053_study_08/setup_engine.sh), `play.sh` and `judge.sh` are committed with this
registration. Before the study, `setup_engine.sh` is run once and each pull request's environment imports Newton from
its tree (`dry/`); no play is made by it.
