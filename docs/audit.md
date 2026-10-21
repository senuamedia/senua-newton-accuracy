# The record checked end to end

An end-to-end audit of this record, 15 to 20 October 2026. Every run is played again by its own scripts and every file
it keeps compared byte for byte; every specific number on the pages is traced to the files it is read from; every
link, character and the vocabulary is checked.

**State, 20 October 2026: every run from 001 to 063 played again, every number on the front page and in `docs/` traced
or read by hand.** Runs 001 to 051 are played again whole by Study 7, on Newton 1.6.1 (the record's own engine and
patches) and on 1.7.0; runs 053 to 063 by this audit, on the host with the engines they were played with; run 052 is
Study 7 itself. Every reading of every run is also made again from its kept files with the measuring program the record
publishes ([`measure/`](../measure/README.md)). Every relative and external link resolves. Runs from 064 on are checked
as they land: each run's readings and rules made again on the laptop from its kept files (its README says so), and the
number trace and the link check run again over every page; the counts below are of the pages as they stood after run 138, Study 35 landed.

Back to the [documentation index](README.md).

## The whole record played again

### Runs 001 to 051 (Study 7, 19 October 2026)

[Study 7](studies/07-newton-1.7.0.md) plays every run 001 to 051 again by its own script, in a clean copy of the
repository on the Newton host, on Newton 1.7.0 and, as its control, on 1.6.1 with the record's own environment and
patches, and compares every file the record keeps, byte for byte ([run 052](../validation/run_052_study_07/README.md)).

- **On 1.6.1 every play file of every solver is the record's: 1,334 of 1,334.** What differs there differs on 1.7.0
  too, so it is the record's own files, not either engine: 89 files the record keeps that no script writes (run 014's
  first play, kept beside its second, and six `rc.txt` files written by the commands that launched runs 014 to 020),
  10 combined stats files whose lines a run's parallel plays append in any order, and 9 readings.
- **Those 9 readings are the measure.** The distance `sx_contact stop` reads is longer than the record's where every
  file it reads is the same (Study 1's slide by 10 um, run 030's MuJoCo spins by 94 to 97 um): the record's early runs
  are read by the measuring program as it was before its correction of 17 October 2026, published as
  [`measure/registered/sx_contact_before_correction.sx`](../measure/registered/sx_contact_before_correction.sx), whose
  `stop` reader differs from the current one's: run 008's and run 030's readings re-made with it byte for byte (21
  October 2026). Every other number of those lines is the record's. The replayed readings the study quotes are kept beside it
  ([`readings/`](../validation/run_052_study_07/readings/)).
- The control's runs 038 to 043 are played twice, the first while the host's disk was full; every judgement is kept.

### Runs 053 to 063 (this audit, 20 October 2026)

[`validation/audit/remake_053_063.sh`](../validation/audit/remake_053_063.sh) plays every run from 053 to 063 again by
its own script, in a clean copy of the repository on the Newton host, with the engines each was played with: Newton
1.7.0 as released, each pull request's tree first on the path (Study 8's engines), and the joint-angle patch's fourth
form for run 061; run 053 from its registration's own archive. Then every file the record keeps for those runs is
compared byte for byte with a second clean copy, the record (`remake_053_063_compare2.txt`, `_log.txt`).

**Result: every play, every reading and every check of runs 053 to 063 re-makes byte for byte.** Of the 1,625 files,
1,514 are the same, 109 differ and 2 are missing; none is new. Each difference has a cause outside the plays:

| Files | Why they differ |
|---|---|
| 38 `started.txt` and `finished.txt`, in each run and in each of Study 8's replayed folders | Clock readings |
| 3 of Study 8's `replay_status.txt` | Each line's start and finish times; every exit status the same |
| 60 files under `stats/` of runs 062 and 063 | Warp's module load times (`took 1.73 ms`); every statistics line the same |
| 8 logs and error streams (runs 054, 056, 057, 058, 063) | Python's warnings name the temporary folder a play ran in and a line of the rig, which has gained lines since those runs; every other line the same |
| Missing: Study 8's `rules.txt` and its dry run's `imports.txt` | Written by the study's judge and its dry run, not by its play script; the measured lines and rules are made again from the kept files on the laptop, byte for byte but for BSD `wc`'s padding of one count line ([run 053](../validation/run_053_study_08/README.md)) |

A first comparison ran two seconds after the last play's script returned; the second, kept, ran once every play had
finished, with the same counts.

### Runs from 064 on, played again on another host and on arm64 (20 October 2026)

Each study since run 064, and the probes behind them, is played again from the record at its play commit (or, for a
probe, from the record with its outputs removed) on the other x86-64 host (a different instance size, the same package
list) and on an arm64 host, every play file and statistics file compared byte for byte with the record's (logs aside).
The arm64 host has no build of the measure: where its play files differ, its readings and rules are made again from
them by the record's measure on an x86-64 host and compared with the record's.

| Run | On the other x86-64 host | On arm64 |
|---|---|---|
| 064, Study 9 | 86 of 86, measured lines and rules included | 82 of 84: two SemiImplicit chain files differ by 1 urad in one printed angle on one and two lines, every reading the same |
| 065 | | 169 of 174: five XPBD joint plays differ |
| 071, Study 10 | 258 of 258 (on the Newton host; it was played on the second) | 252 of 255: two XPBD drives at 0.04 ms and the thrown arm differ |
| 072, Study 11 | 72 of 72 | 71 of 72: one CPU-path drop differs |
| 077 | every play file, 60 of 60; the statistics differ by Warp's module load times only | the same |
| 078, Study 12 | play files 72 of 72; the statistics but for Warp's module load times; readings and rules the same | play files 68 of 72 (four D6 second-axis files); readings and rules the same |
| 080, Study 13 | play files 48 of 48; the statistics but for module load times; readings and rules the same | play files 34 of 48 (the D6 plays); readings and rules the same |
| 082 | play files 135 of 135, statistics 12 of 12 | the same |
| 083 | play files 64 of 64, statistics 64 of 64 | the same |
| 084 | | play files 16 of 24 (eight SemiImplicit strikes); readings the same |
| 085 | | play files 40 of 40, statistics 40 of 40 |
| 086 | | play files 8 of 16 (the strikes at the two smaller steps); readings the same |
| 087, Study 14 | | play files 8 of 16 (SemiImplicit's strikes; Featherstone's the same); readings and rules the same |
| 088, Study 15 | | play files 94 of 94, statistics 12 of 12 |
| 089 | play files 12 of 12, statistics 12 of 12, readings the same (it was played on the Newton host) | play files 12 of 12, statistics 12 of 12 |
| 090 | play files 100 of 100, statistics 18 of 18, readings and checks the same (on the Newton host; it was played on the second) | play files 100 of 100, statistics 18 of 18 |
| 091 | play files 14 of 14, statistics 14 of 14, readings the same | play files 14 of 14, statistics 14 of 14 |
| 092 | play files 153 of 153, statistics 30 of 30, readings and checks the same (on the Newton host) | play files 153 of 153, statistics 30 of 30 |
| 093 | play files 153 of 153, statistics 30 of 30, readings and checks the same (on the Newton host) | play files 153 of 153, statistics 30 of 30 |
| 094 | | play files 200 of 200, statistics 36 of 36 |
| 096 | play files 109 of 109, statistics 27 of 27, readings and checks the same | play files 109 of 109, statistics 27 of 27 |
| 097 | | play files 106 of 106, statistics 24 of 24 |
| 098 | play files 27 of 27, statistics 27 of 27, readings and checks the same | play files 27 of 27, statistics 27 of 27 |
| 099 | | play files 106 of 106, statistics 24 of 24 |
| 100, Study 16 | play files 103 of 103, statistics 21 of 21, readings and rules the same | play files 103 of 103, statistics 21 of 21 |
| 101, Study 17 | play files 24 of 24, statistics 24 of 24, readings and rules the same | play files 24 of 24, statistics 24 of 24 |
| 102, Study 18 | play files 212 of 212, statistics 48 of 48, readings and rules the same (on the Newton host) | play files 212 of 212, statistics 48 of 48 |
| 103, Study 19 | play files 12 of 12, statistics 12 of 12, readings and rules the same | play files 12 of 12, statistics 12 of 12 |
| 104 | play files 36 of 36, statistics 36 of 36, readings the same (it was played on the Newton host) | play files 36 of 36, statistics 36 of 36 |
| 105 | play files 9 of 9, statistics 9 of 9, readings and checks the same (on the Newton host) | play files 5 of 9 (the four XPBD chains), statistics 9 of 9; checks the same, the XPBD chains' readings differ in their low digits |
| 106 | play files 30 of 30, statistics 30 of 30, readings the same (on the Newton host) | play files 17 of 30 (thirteen XPBD chains), statistics 30 of 30; their readings differ in their low digits |
| 107 | play files 14 of 14, statistics 14 of 14, readings and checks the same (on the Newton host) | play files 6 of 14 (eight XPBD chains), statistics 14 of 14; checks the same, the chains' readings differ in their low digits |
| 108 | play files 39 of 39, statistics 39 of 39, readings the same | play files 39 of 39, statistics 39 of 39 |
| 109, Study 20 | play files 30 of 30, statistics 30 of 30, readings and rules the same (on the Newton host; it was played on the second) | play files 12 of 30 (XPBD's arms and chains), statistics 30 of 30; every rule's outcome the same, three of its numbers in their low digits |
| 110, Study 21 | play files 25 of 25, statistics but for module load times, readings and rules the same (on the Newton host) | play files 12 of 25, statistics but for module load times; readings and rules the same |
| 111 | | play files 45 of 51 (six VBD chains), statistics 51 of 51; readings and checks the same |
| 112 | play files 6 of 6, statistics 6 of 6, readings and checks the same (on the Newton host; it was played on the second) | play files 1 of 6, statistics 6 of 6; every check the same, the harvested wrench in its low digits |
| 113 | play files 27 of 27, statistics 27 of 27, readings and checks the same (on the Newton host) | play files 16 of 27 (eleven VBD chains), statistics 27 of 27; readings and checks the same |
| 114, Study 22 | play files 66 of 66, statistics 66 of 66, readings and rules the same (on the Newton host) | play files 47 of 66 (nineteen VBD chains), statistics 66 of 66; readings and rules the same |
| 115 | play files 24 of 24, statistics 24 of 24 (on the Newton host) | play files 24 of 24, statistics 24 of 24; readings and checks the same |
| 116 | play files 96 of 144, statistics 48 of 48 (on the Newton host): the replay ran today's rig, whose box masses were corrected after this probe (its README records the fault) | play files 59 of 144, statistics 48 of 48; readings differ, as on x86-64, the rig's box masses |
| 117, Study 23 | play files 48 of 48, statistics 48 of 48 (on the Newton host) | play files 48 of 48, statistics 48 of 48; readings and rules the same |
| 118 | play files 144 of 144, statistics 48 of 48 (on both other x86-64 hosts) | play files 88 of 144, statistics 48 of 48; 15 readings differ in their low digits (the throw's momentum), every check keeps its outcome |
| 119, Study 24 | play files 120 of 120, statistics 40 of 40 (on the Newton host) | play files 94 of 120, statistics 40 of 40; 7 of 40 readings differ in their last digit, every rule keeps its outcome |
| 120 | play files 11 of 11 (on the Newton host); its statistics files carry Warp's module-load timings, which differ run to run | play files 11 of 11; readings and checks the same |
| 121 | play files 20 of 20, statistics 20 of 20 (on both other x86-64 hosts) | play files 2 of 20, statistics 20 of 20; readings the same; its C0 check compares the plays byte for byte with Study 22's x86-64 files, so it cannot hold on arm64 |
| 122 | not played again: the record keeps its instrument fault (its options read as numbers only), run 124 plays them | played with today's rig, which reads the options; its readings differ from the record's faulty ones, as expected |
| 123 | not played again on x86-64 | play files 34 of 36, statistics 36 of 36; readings and checks the same |
| 124 | play files 13 of 13, statistics 13 of 13 (on the Newton host) | play files 13 of 13; readings and checks the same |
| 125 | play files 12 of 12, statistics 12 of 12 (on the Newton host) | play files 5 of 12 (seven chains), statistics 12 of 12; readings and checks the same |
| 126, Study 25 | play files 30 of 30, statistics 30 of 30 (on the Newton host) | play files 28 of 30, statistics 30 of 30; readings and rules the same |
| 127 | play files 70 of 70, statistics 70 of 70 (on the Newton host) | play files 70 of 70, statistics 70 of 70; readings and checks the same |
| 128, Study 26 | play files 140 of 140, statistics 140 of 140 (on the Newton host) | play files 140 of 140, statistics 140 of 140; readings and rules the same |
| 129 | play files 60 of 60, statistics 60 of 60 (on the Newton host) | play files 60 of 60, statistics 60 of 60; readings and checks the same |
| 130, Study 27 | play files 204 of 204, statistics 204 of 204 (on the Newton host) | not played: Newton's USD importer takes `usd-exchange` on arm64 Linux, not the pinned `usd-core` wheel |
| 131, Study 28 | play files 78 of 78, statistics 78 of 78 (on the second x86-64 host; it was played on the Newton host) | play files 78 of 78, statistics 78 of 78; readings and rules the same |
| 132, Study 29 | play files 78 of 78, statistics 78 of 78 (on the second; played on the Newton host) | play files 78 of 78, statistics 78 of 78; readings and rules the same |
| 133, Study 30 | play files 204 of 204, statistics 204 of 204 (on the Newton host) | not played, as run 130 |
| 134, Study 31 | play files 12 of 12 (on the second; played on the Newton host); statistics carry Warp's timings | play files 12 of 12; readings and rules the same |
| 135, Study 32 | play files 12 of 12 (on the second; played on the Newton host); statistics carry Warp's timings | play files 12 of 12; readings and rules the same |
| 136, Study 33 | play files 60 of 60, statistics 60 of 60 (on the Newton host) | play files 60 of 60, statistics 60 of 60; readings and rules the same |
| 137, Study 34 | play files 60 of 60, statistics 60 of 60 (on the Newton host) | play files 60 of 60, statistics 60 of 60; readings and rules the same |
| 138, Study 35 | play files 60 of 60, statistics 60 of 60 (on the Newton host) | play files 60 of 60, statistics 60 of 60; readings and rules the same |
| 139, Study 36 | play files 117 of 117, statistics 117 of 117 (on the Newton host; it was played on the second) | statistics 117 of 117, the spin, slide and hold plays 27 of 27; 88 of the 90 chain plays differ in their low digits, their re-read on x86-64 to come |

On one architecture Newton's CPU plays are the same bytes from host to host; across architectures most are, and those
that are not differ in their low digits where a long play or a thrown joint amplifies a rounding (issue 23). Every
rule and check made from an arm64 replay of run 078 or later keeps the record's outcome, and every reading is the
record's but those of the XPBD chains struck against a limit in runs 105 to 107 and 109, run 112's cloth harvest, run
118's throw and run 119's box, which differ in their low digits (re-read on the x86-64 host from the arm64 files, 21
October 2026). Three replays differ for a reason the record states: runs 116 and 122 were played again with today's
rig, which corrects their recorded faults, and run 121's C0 check compares with x86-64 files by design.

### Every reading made again from its files

Every run's readings, verdicts and rules are made again from its kept files, byte for byte, by the measuring program:
runs 001 to 016 together on 15 October 2026, in a scratch copy (where a run's script would remove kept files, its
measuring lines alone); every run since as it lands, on the laptop, by the run's own reading lines with its plays left
out (each run's README says so); runs 053 to 063 again by a laptop build of the source the record publishes
([`measure/sx_contact.sx`](../measure/sx_contact.sx)). That source reads every line of the early runs the same but the 9
`stop` lines above. Where a reading needs arithmetic the measure has no reading for, it is listed below.

## Every number traced

[`validation/audit/trace_numbers.sh`](../validation/audit/trace_numbers.sh) looks for every specific number on the
front page, in `docs/` and in every run's README (at least three significant digits; dates and the audit page set
aside) as written in the files of the runs its line cites, commas and the sign dropped
([`trace_numbers.txt`](../validation/audit/trace_numbers.txt)): **5,672 numbers, 4,209 found in a run the line
cites, 669 elsewhere in the record, 794 in no file but the pages** (21 October 2026, through run 138).

- **The front page and `docs/`: every one of the 239 not found in a cited run is read by hand.** They are pieces of
  sha256 and commit names, issue and pull request numbers, versions (Warp 1.18, MuJoCo Warp 3.12), step labels (0.156
  ms is 10 ms over 64), unit changes of kept readings (92.5 mm for 92,519 um; 3.97 rad/s for 3,973,875 urad/s),
  ratios and closed forms worked from kept readings (a slide's 127.6 mm is v^2 / (2 mu g); XPBD's drive's 0.69 to
  11.1 times its stiffness from its angles at 0.1 s), a suite's verdicts under `suites/`, and figures from Study 7's
  replayed readings, kept in [`readings/`](../validation/run_052_study_07/readings/); since run 118, Study 24's
  feedback and momentum ratios (82,196 and 11,392 mN over 590: 139 and 19 times), Study 28's MuJoCo C speeds (1,895,544
  um/s as 1.8955 m/s), the static-friction studies' closed forms (2.26, 2.36 and 4.41 m/s, their registrations'), and
  one host check's figure stated on its run's page (run 133: 115 um/s at 0.0625 ms, its files not kept). Each is
  right as written; one citation was corrected on 21 October 2026 (the patches page's "19 to 168 times" draws on
  runs 112 and 119, not 112 alone).
- **The run pages' own numbers:** [`trace_conversions.sh`](../validation/audit/trace_conversions.sh) matches 1,100 of
  the 1,463 numbers not found in a cited run to a whole number of that run's files as a unit change, within half a unit
  of the number's last decimal ([`trace_conversions.txt`](../validation/audit/trace_conversions.txt); a match, not a
  proof: a large run holds many numbers). Of the other 363, 126 are on the front page and in `docs/`, among the 239
  read by hand; 237 are on the run pages, each a run's own analysis of the readings beside it (ratios, differences,
  predictions worked before the plays). Those 237 are not each read again here.

## Claims checked by hand

| Page | Claim | Source |
|---|---|---|
| Front page | A slide stops at 44% of Coulomb's distance; an impact takes 75% too much friction; a plate at the narrower smoothing stops at 3.5% | Study 1, `measured.txt`: 84,061 of 191,610 um; 4,381 for 2,500 per 10,000 |
| Front page | With the patch the slide within 0.2%, the impact exact | Study 1: 191,783 um (+0.09%), the plate 83,230 um (-0.12%), 2,500 |
| Front page | VBD: a body 10 m up does not fall; 1 m up, not at 0.031 ms | Run 006: 0 mm/s2 at both steps at 10 m, 0 at 0.031 ms at 1 m |
| Front page | The MuJoCo solver's state stops being a number at friction 0.001 or less, on a cube | Runs 011, 012 |
| Front page | The chain: +9.7% under Featherstone and the MuJoCo solver, -30% XPBD, -46% VBD, SemiImplicit blows up; RK4 to 5 ppm | Run 014 |
| Front page | Nothing holds at rest, VBD-ALM excepted at large steps | Run 001: 1 and 0 um/s at 2 and 0.5 ms |
| Front page | 4 of 10 as released, 6 of 10 with the patch: three friction tests gained, the refinement chain (T08) lost | Run 007 |
| Front page | Deterministic to the byte on the six solvers played | Run 001: the hold on six solvers; run 016: XPBD's suite |
| Front page | XPBD answers a joint torque 1.75 times too strongly (8,670 urad against the closed form's 4,967 at 0.1 ms) | Run 054, `reading.txt` and `checks.txt` |
| Findings F1 | An impact takes 14% to 75% too much friction across the scenes | Run 001: 4,320 to 4,355 for 3,000; run 007: 4,571 to 4,675 for 4,000; Study 1: 4,381 for 2,500 |
| Findings F2 | Free fall 2.7% slow at 0.125 ms, 56% fast at 0.031 ms | Run 001's files: 9,536 and 15,258 mm/s2 |
| Findings F4 | XPBD 10.9 to 0.17 mm/s; 735 um/s; 1,293 um/s | Run 001's reading |
| Findings F5 | XPBD's bounce, 4% to 12% of the drop, rising with refinement except at run 007's two finest steps | Run 001: 1,009 to 1,182; run 007: 382 to 1,125, then 1,097 and 1,092 |
| Findings F8 to F10 | The chain | Run 014 |
| Findings, what Newton gets right | Deterministic on the six solvers played; free fall at gravity's rate on the solvers and heights played | Runs 001, 006, 016 |
| How it works | 2.2 times Coulomb's at the default smoothing, 13 times at 0.1, a 1 m/s slide stopped in 0.69 mm at 0.01 | Run 004: 8,266 to 8,869 and 46,333 to 56,293 mm/s2 against 3,920; 690 um |
| How it works | Newton from PyPI with Warp 1.18.0 and MuJoCo Warp 3.12.0 | Run 001, `environment.txt` |
| Known issues N1 | The patch gives Coulomb's slide and impact; the refinement chain is lost on the suite | Run 007, T08 |
| Known issues N11, N12 | About 2% rebound under SemiImplicit and Featherstone; resting depths 70 um falling with the square of the step | Run 001's reading (175 to 192 per 10,000) and files |
| Patches | A slide at 44%, a plate at 23%, an impact 75% over; on, within 0.09% and 0.12%, the impact exact; 28 of 28 and 24 of 24 safe when off | Study 1 (19,374 of 83,333 um for the plate), run 005 |
| Reproduce | Warp runs on Linux x86_64 and aarch64, Windows, and macOS on Apple silicon only | PyPI's file list for warp-lang 1.18.0 |
| Study 1 | R6: at most 7,994 urad, against 327,354 (SemiImplicit) and 330,993 (Featherstone) released | `measured.txt` |
| Fixes in the wild | Each pull request's state (open; #4316 changes requested; #4318, #4010 and #4721 drafts) | GitHub, 20 October 2026 |
| Runs | The one-line result of each run | Each run's README and reading |

## Readings made outside the measure

Some numbers are read from a rig's files without one of the measure's readings:

- **Free fall** (runs 001 and 006): the mean acceleration over the first 50 ms, with shell arithmetic over the rig's
  files, made again the same way. The measure has no reading for a vertical acceleration (`accel` reads along the
  slide).
- **The resting depth** (run 001): the height on the rig's last line, read as written.
- **The largest turn of the cube** (`most_tilt_urad`) and **where a state stops being a number** (`nan_at_step`,
  `out_of_range_at_step`): the rig's own statistics line.
- **Run 001's decelerations** (8,315 to 36,912 mm/s2 under SemiImplicit) are made with the measure's `accel`; under
  Featherstone it reads 12,068 and 36,923, where run 001's README gives SemiImplicit's 12,067 and 36,912 for both, as
  its note says.

## Mechanical checks

- **Links.** Every relative link on the pages resolves: 1,300 ([`check_links.sh`](../validation/audit/check_links.sh));
  two that named run 104's folder wrongly were corrected on 21 October 2026.
  Every one of the 49 external links answers (21 October 2026, again on the second pass).
- **GitHub's issues and pull requests (second pass, 21 October 2026).** Every cited issue, pull request and discussion
  read from GitHub again: each the kind and the state the pages give it, with three corrections: pull request #3554 was
  merged on 21 October 2026, after 1.7.0 (it read "open"); issue #4720 was closed by its author as being discussed with
  the maintainers (it read "closed in favour of" draft PR #4721, which the same author opened); and the winding fix in
  1.7.0 is pull request #4479, which Newton's changelog cites by its issue, #4470, as the pages do (the pull request is
  now named beside it).
- **References.** Every published work the pages cite checked against its source: Schwager and Poeschel, Granular
  Matter 9, 465-469 (2007); Baraff and Witkin, Large steps in cloth simulation (SIGGRAPH 1998); Catto, Iterative
  dynamics with temporal coherence (GDC 2005) and Continuous collision (GDC 2013); Fratarcangeli, Tibaldo and Pellacini,
  Vivace (ACM Transactions on Graphics 35(6), 2016); and Belytschko, Liu and Moran, Nonlinear Finite Elements for
  Continua and Structures (Wiley, 2000), whose explicit step's stability is in sections 6.2 (explicit methods) and 6.6
  (numerical stability), not 6.3 (implicit time integration) as Study 3's page and run 021's and 024's notes had it:
  corrected; Study 3's registration keeps its text as registered.
- **Characters.** Plain ASCII on every page: no em dash, no en dash.
- **Vocabulary.** "Model" is used as a denial ("We do not use models"), for Newton's own `model` object in code, and
  for its friction model. Nothing calls Senua a model.
- **The machine's home folder** is written `~` in every file the record keeps.

## What this check does not cover

Issue 20's force calibration, point clouds and grasps need SDF volumes, which Warp 1.18 builds on CUDA only; they are
not played on these CPU hosts. The run READMEs' prose beyond their numbers is read where the front page or `docs/`
quotes it.
