# Study 7: the record on Newton 1.7.0

**Outcome: 2 of 4 rules held (R3, R4); R1 and R2 failed as registered.** No finding on SemiImplicit, Featherstone or
XPBD changed: every difference behind R1 and R2 but two is the runner's or the judge's, traced below; the two are
VBD's plays past pi, which Newton 1.7.0's winding fix (#4470) changes. Registered 19 October 2026
([`PREREGISTRATION_07.md`](../../preregistrations/PREREGISTRATION_07.md)); played once as
[run 052](../../validation/run_052_study_07/), with a 1.6.1 control.

## The question

The record was made on Newton 1.6.1; 1.7.0 was released on 14 October 2026 (MuJoCo and MuJoCo Warp 3.15 in place of
3.12). Every run, 001 to 051, played again by its own script on 1.7.0 with the record's patches rebased
(`patches/newton-1.7.0/`), and compared with the record file for file.

## The rules and the result

| Rule | Result | What is behind it |
|---|---|---|
| R1 the record plays on 1.7.0 (every kept file written) | **failed**: 89 files missing | 83 are run 014's `first_play/`, the record's first play of that run, kept beside the second and written by no script; 6 are `rc.txt` files of runs 014 to 020, written by the command that launched those scripts, not by the scripts. Every script ran to its end (51 of 51, exit 0) |
| R2 unchanged kernels play the same (SemiImplicit, Featherstone, XPBD and VBD files byte-identical) | **failed**: 23 files | 11 are run 023's MuJoCo solver plays and 1 is a MuJoCo line in run 004's reference stats, counted by the judge under other solvers (MuJoCo Warp 3.12 to 3.15: reported below); 9 are combined stats files whose lines differ only in their order (the plays append in parallel) and in the engine's version, which the judge set aside only in one-line stats; **2 are VBD's plays of run 032 (the joint turning past pi), which depart at the step the joint passes pi: 1.7.0's VBD winding fix** |
| R3 the validated studies hold (Studies 1, 2, 3, 4, 6) | held: 0 rule lines failing | |
| R4 Study 5 as it was | held: its rule lines read on 1.7.0 as on 1.6.1 | |

With those two VBD plays set aside, every SemiImplicit, Featherstone, XPBD and VBD play file of the record is byte for
byte the same on 1.7.0, as predicted from the source.

## Reported

- **The MuJoCo solver on 1.7.0** (MuJoCo Warp 3.15): 89 of its 191 play files differ from the record's (runs 001,
  003 to 005, 008, 011, 012, 014, 031, 032, 036, 039, 042, 043). Its findings read again on them: F3 stands (the
  pyramidal cone without friction stops being a number at step 818, where the record's did at 822), and run 023's
  elliptic cone at an impedance ratio of 1e6 at 2.5 ms now stops being a number too (step 53; it played on 1.6.1);
  F7's elliptic suite passes as it did (T07 984,000 against 984,500 um/s); F8 stands (the free chain at 10 ms gains
  88,302 ppm against 88,300); F12's creep reads the same; F15 and Study 6 hold (R3).
- **The control on 1.6.1: the whole record plays again byte for byte on its own release.** Every play file of every
  solver is the record's (1,334 of 1,334: Featherstone 122, the MuJoCo solver 191, SemiImplicit 145, XPBD 322, VBD 211,
  VBD-ALM 30, other 313). What differs there differs on 1.7.0 too, so it is not 1.7.0's doing: the same 89 files
  missing (R1's), 10 combined stats files whose lines differ in order alone, and 9 readings (the measure, below).
- **Readings that differ while their files are the same: the measure, not the engine.** The distance `sx_contact
  stop` reads (`slid_um`) is longer on the replay where every play file it reads is byte for byte the record's: Study
  1's stock slide by 10 um (84,071 and 83,869 against 84,061 and 83,859), run 030's MuJoCo spins by 94 to 97 um
  (13,216 against 13,122 at 10 ms), the same in run 031; every other number of those lines is the same. The record's
  early runs were read by an earlier build of the measuring program; its `stop` reader has changed since.

## Infrastructure

The 1.6.1 control's runs 038 to 043 were played while the host's disk was full (19 October, about 13:00 to 13:13 UTC):
they lost files, and the MuJoCo-limit patch's tree was left with truncated bytecode, which broke its imports. They were
played again, the bytecode cleared and runs 039, 042 and 043 played once more, before the control was judged; its three
judgements are kept. See [run 052](../../validation/run_052_study_07/README.md).
