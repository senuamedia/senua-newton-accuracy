# Run 052: Study 7, the record on Newton 1.7.0

The seventh registered study ([PREREGISTRATION_07.md](../../preregistrations/PREREGISTRATION_07.md)), played on the
Newton host on 19 October 2026 by [`replay.sh`](replay.sh) in a clean copy of the repository for each engine, judged by
[`judge.sh`](judge.sh); the engines set up by [`setup_engine.sh`](setup_engine.sh); the runner's dry run in
[`dry/`](dry/). Read in [Study 7](../../docs/studies/07-newton-1.7.0.md).

## What is kept

- [`v170/`](v170/): the 1.7.0 replay's judgement (`compare_1.7.0.txt`, every kept file SAME, DIFFERS, MISSING or SET
  ASIDE; `summary_1.7.0.txt`; `rules.txt`; `judge_output.txt`), its replay status, each run's error stream, the
  engine's manifest, and `r2_traced.txt`, R2's twelve kernel-family files read with the engine's version masked and
  their lines sorted (by [`r2check2.sh`](r2check2.sh); [`r2check.sh`](r2check.sh) the version masking alone).
- [`v161/`](v161/): the 1.6.1 control's, the same, and its three judgements in turn (`judge_output_first.txt`,
  `judge_output_window1.txt`, `judge_output.txt`, the last the control's record) with their replay statuses.

- [`readings/`](readings/): the replayed files the [study's page](../../docs/studies/07-newton-1.7.0.md) quotes, as the
  replay made them (`r170/` on 1.7.0, `r161/` the control; their sha256 in `SHA256SUMS`, checked against the host's):
  Study 1's measured lines and rules (the stock slide's 84,071 and 83,869 um), the MuJoCo solver's elliptic suite's
  verdicts (T07's 984,000 um/s), run 014's chain reading (F8's 88,302 ppm) and run 030's spins (13,216 at 10 ms).

The replayed copies themselves (about 3 GB, every run's outputs) stay on the host; the compare lists name every file
and its verdict.

## Played

- **1.7.0**, 03:59 to 08:46 UTC: 51 of 51 scripts ran to their end (exit 0); judged: 2,204 files the same, 136
  differ, 89 missing, 491 set aside.
- **1.6.1, the control**, 09:23 to 13:52 UTC. While it played, the host's disk filled (about 13:00 to 13:13 UTC, three
  other runs' copies staged beside it): its runs 038 to 043 lost files, and the bytecode of the MuJoCo-limit patch's
  tree (`src_mjlim`, 155 files) was written truncated, so its imports failed. Runs 038 to 043 were played again (13:53
  to 14:16), the truncated bytecode was cleared (Python rewrites it from the source), and runs 039, 042 and 043 were
  played again (14:19 to 14:36). Judged then: **every play file of every solver the same as the record's** (1,334 of
  1,334), 89 missing (the same 89 as on 1.7.0), 19 differ (10 combined stats files whose lines differ in order, 9
  readings), 491 set aside.

## The rules (1.7.0)

R1 failed (89 missing: run 014's kept `first_play/`, 83 files written by no script, and 6 `rc.txt` files written by
the command that launched runs 014 to 020); R2 failed (23 files: 12 MuJoCo solver files the judge counted under other
solvers, 9 combined stats files differing in line order and version, and run 032's two VBD plays past pi, 1.7.0's
winding fix); R3 and R4 held. Every SemiImplicit, Featherstone and XPBD play file is the same on 1.7.0, and every VBD
play file but those two.
