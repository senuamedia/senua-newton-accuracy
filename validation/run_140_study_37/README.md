# Run 140: Study 37, XPBD's joints solved colour by colour, at full relaxation (issue 12)

The thirty-seventh registered study ([`PREREGISTRATION_37.md`](../../preregistrations/PREREGISTRATION_37.md)), played once
with [`play.sh`](play.sh) on the engines made by [`setup_engine.sh`](setup_engine.sh): Newton 1.7.0 as released
(`stock`), and with Senua AI's XPBD joint colours ([`xpbd_joint_colours_on_1.7.0.diff`](../../patches/in_design/xpbd_joint_colours_on_1.7.0.diff)),
its switch unset (`off`) and set (`on`).

## What it found

Played 21 October 2026 (UTC) on the Newton host (`started.txt`, `finished.txt`); the measured lines in `measured.txt`,
the rules in [`rules.txt`](rules.txt). **8 of 9 rule lines held; R4 failed.**

The free chain's largest energy departure, ppm:

| | 1.6 ms | 0.8 ms | 0.4 ms | 0.2 ms | 0.1 ms |
|---|---|---|---|---|---|
| Stock at its defaults (2 iterations, relaxations 0.7 and 0.4) | 26,609 | 15,481 | 9,897 | 7,139 | 5,065 |
| On, full relaxation, 32 iterations | 24,779 | 11,852 | 4,178 | 1,408 | 717 |

- R1 held: with the switch unset all 9 chain plays byte for byte stock's.
- R2 held: stock at full relaxation diverges at 2, 8, 32 and 128 iterations, its largest kinetic energy 0.79 J at the
  start against 70,348, 69, 585 and 1,108 J.
- R3 held: on, the departure falls at every halving of the step, 24,779 to 717 ppm.
- **R4 failed**: at 0.4 ms the departure is 4,178 ppm at 32 iterations and 3,615 at 128, 13.5% apart against the
  registered 1 in 10: on this chain 32 iterations do not converge the joint solve (on run 125's chain they did, 3,937
  and 3,941).
- R5 held: at 0.4, 0.2 and 0.1 ms on's departure is at most half of stock's at its defaults (4,178 against 9,897; 1,408
  against 7,139; 717 against 5,065).
- R6 held: one arm with the switch set byte for byte stock's at both steps (one joint, one colour).
- R7 held: every play a number throughout.

Reported: on at 2 and 8 iterations, 6,430 and 6,246 ppm at 0.4 ms; the chain swinging under gravity departs by 658,038,
288,303 and 112,988 ppm (stock) and 591,321, 232,820 and 57,009 ppm (on) at 1.6, 0.4 and 0.1 ms, the colours about
halving it at the finest step but not keeping it.

## What it decides

R4 failed, so as registered issue 12's XPBD part stays open. What the plays show: XPBD with its joints coloured is
stable at full relaxation and its free chain's loss falls with the step, seven times below the released solver's at
0.1 ms; 32 iterations are not enough to converge it on every chain. A registration at an iteration count shown to
converge is next.
