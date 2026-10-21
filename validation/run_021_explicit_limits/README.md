# Run 021: why the normal-contact patch failed run 020's second and third checks

15 October 2026, 07:58 to 08:01 UTC. Not registered: a trace. Played on the Newton host by [`play.sh`](play.sh), whose
hypothesis and predictions were pushed before the plays, on the same patched source as run 020
(`patched_source.txt`, byte-identical); reading `reading.txt`, made with Senua AI's `sx_contact` (`bounce`, `creep`)
and re-made byte for byte on the laptop from the same files.

## The question

In [run 020](../run_020_contact_damping_no_pull/README.md) the normal-contact patch in design
([`contact_damping_no_pull.diff`](../../patches/in_design/contact_damping_no_pull.diff)) failed two of the five checks.
Check 2: at 10 ms the suite's drop is launched in its first contact step, byte-identical to the release. Check 3: with
Study 1's patch the hold at 0.625 ms creeps 2% faster (2,704 against 2,645 um/s); alone, with the stock friction, the
held cube slides back faster. Are these the contact law's, which a new version of the patch could correct, or Newton's
explicit integration of it?

## The hypothesis

SemiImplicit and Featherstone integrate the contact force explicitly over the step h. With Newton's defaults (per
contact ke 2,500 N/m, kd 100 N s/m, kf 1,000 N s/m; a cube flat on the ground touches it at four corners):

- **The normal.** A body's speed into the ground decays at c_n = 4 kd / m. An explicit damper gives v' = v (1 - h c_n):
  it never turns the speed round while h c_n <= 1, and is stable while h c_n < 2 (with the spring, the critical step of
  Belytschko, Liu and Moran, Nonlinear Finite Elements for Continua and Structures, Wiley 2000, sections 6.2 and 6.6). For the
  suite's 2 kg cube at 10 ms, h c_n = 2: the damper alone turns the speed round in one step, before the contact opens,
  where the patch acts.
- **Friction.** A horizontal force at the bottom corners also turns the cube, so the corners' slip decays at
  c_t = 10 kf / m for a cube. Predicted: explicit friction settles only while h c_t < 2 (0.4 ms for the suite's cube,
  0.2 ms for run 001's 1 kg cube); there the hold creeps at the push over four corners' kf, the viscous branch both
  friction laws share at so small a slip, and elsewhere at whatever a chatter gives.

## What was played

- **A.** The drop (80 mm, friction 0, half-size 0.04 m) at 1, 2 and 4 kg and at 2.5, 5 and 10 ms, on SemiImplicit and
  Featherstone, as released and with both switches (Study 1's and the patch's).
- **B.** The suite's hold (2 kg, friction 0.5, pushed with 5.88 N from 0.5 s, 2 s) on SemiImplicit at 0.625, 0.44, 0.36
  and 0.15625 ms, with no switch, Study 1's only, both, and the patch's only.
- **C.** Run 001's hold (1 kg, half-size 0.05 m, friction 0.5, 2.94 N from 0.5 s, 2 s) on SemiImplicit at 0.22 and
  0.18 ms, with no switch, Study 1's only, and both.

58 plays; none stopped being a number.

## A. The drop: the damper's limit, as predicted in every cell

| The 80 mm drop, rebound per 10,000 of the height | 4 kd h / m | As released | With both switches | The two files |
|---|---|---|---|---|
| 1 kg, 2.5 ms | 1 | 0 | 0 | differ |
| 1 kg, 5 ms | 2 | 14,555 | 14,555 | identical |
| 1 kg, 10 ms | 4 | 131,959 | 131,959 | identical |
| 2 kg, 2.5 ms | 0.5 | 11 | **0** | differ |
| 2 kg, 5 ms | 1 | 407 | **0** | differ |
| 2 kg, 10 ms (run 020's failure) | 2 | 16,936 | 16,936 | identical |
| 4 kg, 2.5 ms | 0.25 | 180 | **0** | differ |
| 4 kg, 5 ms | 0.5 | 440 | **0** | differ |
| 4 kg, 10 ms | 1 | 218 | **0** | differ |

SemiImplicit; Featherstone reads the same in every cell (131,960 for the 1 kg cube at 10 ms). Every launched cell
turns in its first contact step (`steps_to_turn` 1).

Predictions A1 (no rebound wherever 4 kd h / m <= 1) and A2 (where it is 2 or more, launched in the first contact step
and byte-identical to the release) held in all nine cells on both solvers.

## B and C. The hold: the patch changes nothing where friction settles; the predicted limit was too high

| The hold's creep, um/s | h c_t | As released | Study 1's patch | Both | The patch alone |
|---|---|---|---|---|---|
| Suite's cube (right answer for viscous friction: 1,470), 0.625 ms (the suite's) | 3.1 | -5,538 | 2,644 | 2,704 | -14,709 |
| 0.44 ms | 2.2 | -1,502 | 1,902 | 1,874 | -9,748 |
| 0.36 ms | 1.8 | -658 | 1,509 | 1,510 | -2,183 |
| 0.15625 ms | 0.78 | **1,470** | **1,470** | **1,470** | **1,470** |
| Run 001's cube (735), 0.22 ms | 2.2 | -3,105 | 953 | 936 | |
| 0.18 ms | 1.8 | -952 | 757 | 757 | |
| Run 001, 0.5 ms and 0.125 ms (as released, SemiImplicit) | 5 and 1.25 | -6,601 and **735** | | | |

| Prediction | Result |
|---|---|
| B1: below 0.4 ms every arm creeps at 1,470 within 1 in 100, and with the patch within 1 in 100 of the same arm without it | **Failed** at 0.36 ms: 1,509 and 1,510 with Study 1's friction (2.7% over), and backwards with the stock friction (-658, and -2,183 with the patch). Held at 0.15625 ms |
| B2: at 0.44 and 0.625 ms no arm creeps at 1,470 | Held |
| B3: the 0.625 ms plays byte-identical to run 020's | Held, all four |
| C1: at 0.18 ms every arm creeps at 735 within 1 in 100 | **Failed**: 757 and 757 (3% over), -952 as released |
| C2: at 0.22 ms no arm does | Held |

## What it shows

- **Run 020's 10 ms failure is the explicit damper's limit, not the contact law.** With the patch a dropped cube does
  not rebound wherever 4 kd h / m <= 1, on both solvers, the 4 kg cube at 10 ms included, where the release rebounds
  218 per 10,000: the patch works at 10 ms on a body heavy enough for the step. Where 4 kd h / m >= 2 the damper turns
  the closing speed round in the first contact step and the cube leaves the ground before the contact opens, so the
  play is the release's byte for byte. The failure moves with the mass exactly as the limit says: the 1 kg cube fails
  at 5 ms, the 4 kg cube passes at 10 ms. No version of the contact law reaches it, because the law is not evaluated
  again before the cube has left; the integration is Newton's, which the patch does not change.
- **Run 020's 2% at 0.625 ms is a change in a chatter, not in friction's creep.** At 0.15625 ms every arm creeps at
  1,470 um/s, the push over four corners' kf, and the patch changes nothing in the reading, with either friction. At
  0.44 and 0.625 ms no arm creeps at that speed, and the stock friction's creeps backwards: explicit friction coupled
  with the cube's turn does not settle there, and the patch, by damping the corners' lift, changes what the chatter
  gives.
- **The friction limit was predicted too high.** At h c_t = 1.8 (0.36 ms on the suite's cube, 0.18 ms on run 001's)
  the creep still departs, by 2.7% and 3% with Study 1's friction and backwards with the stock friction, where a
  linear account of sliding and turning gives an alternation that dies away. Run 001 has this cube exact at
  h c_t = 1.25 (735 um/s at 0.125 ms). The limit lies between 1.25 and 1.8; why it is below the linear account's 2 is
  not traced here.
- **Run 001's hold at 0.5 ms (-6,601 and -6,138 um/s) and the 2 ms instability of a 10 cm cube (F6) lie past the same
  limit**, at h c_t 5 and 20 on that cube.

**For the patch:** both failed checks are Newton's explicit integration, outside the contact law the patch changes, so
no new version of the patch follows from this run. It stays in design, no study registered. Its checks could only be
met at steps inside these limits; whether they may be stated there, after run 020 failed them as set, is left open.
