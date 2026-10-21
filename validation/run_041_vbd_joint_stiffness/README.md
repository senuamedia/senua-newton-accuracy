# Run 041: VBD's jointed-chain error at small steps, against its structural joint stiffness

15 October 2026, 10:36 to 10:42 UTC, on the Newton host, by [`play.sh`](play.sh), whose hypothesis and predictions
were pushed before the plays. Not registered: a trace. Run 026's patched source. Reading `reading.txt`, made with Senua
AI's `sx_contact chain`, re-made byte for byte on the laptop from the same files. In the logs the home folder is
written `~/`.

The hypothesis: VBD's joints are springs of the structural stiffness (`rigid_joint_linear_ke`, `rigid_joint_angular_ke`,
1e5), which a step of 0.05 ms resolves rather than damps, so the chain's joints ring; a stiffer joint would ring less.

| Run 014's free chain at 0.05 ms, energy after 2 s per million of the start (1,000,000) | VBD, carried velocity | VBD, without | VBD-ALM, carried velocity |
|---|---|---|---|
| Structural stiffness 1e5 (the default; Study 4) | 1,451,104 | 915,739 | 1,089,095 |
| 1e7 | 1,183,631 | 1,150,308 | 1,142,342 |
| 1e4 | 1,154,106 | | |

| Prediction | Result |
|---|---|
| P1: at 1e7 the chain keeps its energy within 5 in 100 | **Failed**: 18 in 100 over |
| P2: at 1e4 the energy departs further than with the default | **Failed**: it departs less (15 in 100 over against 45) |

No play stopped being a number.

**What it shows.** The hypothesis is refuted: the error is not monotone in the joint's stiffness (the default is the
worst of the three), and without the carried velocity a stiffer joint turns an 8% loss into a 15% gain. VBD's error on
a jointed chain at small steps is not its read-back (runs 025, 026), its warm-start decay (029), its penalty's start
(038) or simply its joint stiffness (this run). It needs a reading of VBD's joint solve itself; not traced.
