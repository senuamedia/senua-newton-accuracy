# Run 053: Study 8, the fixes proposed upstream

The eighth registered study ([PREREGISTRATION_08.md](../../preregistrations/PREREGISTRATION_08.md)): pull requests
#4010, #4316 and #4317, as they stand, on Newton 1.7.0, held to Study 1's and Study 5's rules and read on runs 048,
050 and 051. Registered with its runner (`setup_engine.sh`, `play.sh`, `judge.sh`) before any play.

## Played

On the Newton host, 2026-10-19T13:16:14Z to 2026-10-19T13:46:52Z, from the registration's own archive (1e300f6). **Played
twice:** the first play (12:44 to 13:11 UTC) ran its part C while the host's disk was full (33 of its files empty), so
the study was played again whole; the second is this record. Its parts A and B are byte for byte the first play's (118
and 337 files), so A1 and B1 read the same on both. Rules [`rules.txt`](rules.txt): **0 of 2 held**, as predicted;
read in [Study 8](../../docs/studies/08-upstream-fixes.md).

- **A1 (#4010 on Study 1) failed, 3 lines:** R3's plate at 0.05 m/s (84,863 um against 83,333) and R5 on both solvers;
  at the new default width the slide (191,801 um), the plate (83,245) and the impact (2,500) are Senua AI's patch's to
  within a micrometre.
- **B1 (#4316 on Study 5) failed, 4 lines:** R3 on its bytes only (inside reads as none to the microradian), R4 (reach
  thrown back at 2.37 and 2.43 rad/s) and R5 (below 46 mrad lower than the release).
- **Reported, C (#4317 on Study 5):** R2 and R6 held; inside and reach thrown as on the release (reach's last speeds
  1.3e6 and 1.9e7 rad/s), R5 failed: #4317 is not a fix for issue 7 and does not act as one.
- **Reported, runs 048, 050 and 051 under each pull request:** their readings are in `B/` and `C/`. Under #4316 the
  limit still throws the arm back (run 051's arm at a 2.7 rad limit, relaxation 0.4, 0.32 ms: turning back at 2.54
  rad/s, where the record's third form of the joint-angle patch leaves 0.45).

Every part's measured lines and rules were made again on the laptop from the kept files, with a build of
[the measure](../../measure/README.md) (20 October 2026): the three parts' `measured.txt` and the rules of B and C byte
for byte, and Study 8's own rules; A's rules line for line, but for its last line, whose count BSD `wc` pads with
spaces on the laptop where GNU's does not ("rules:       11" against "rules: 11"; run 008's script does not strip them).
