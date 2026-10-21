# Run 020: a patch in design, SemiImplicit's and Featherstone's normal contact damped in both phases

15 October 2026, 05:34 to 05:51 UTC. Not registered: a patch in design, held to the five checks. Played on the
Newton host by [`play.sh`](play.sh), whose predictions were pushed with the patch before the plays; reading
`reading.txt`, re-made byte for byte on the laptop from the same files, every suite's verdicts included.

## The finding it answers

F11, traced in run 017: SemiImplicit's and Featherstone's body contact kernel damps the normal contact only while it
closes, `fd = min(vn, 0) * kd`, so with a restitution of 0 a drop rebounds, more as the step shrinks, and with Study
1's friction patch the refinement chain (T08) fails.

## The patch

[`patches/in_design/contact_damping_no_pull.diff`](../../patches/in_design/contact_damping_no_pull.diff) (sha256
15d7489e80b018ab...), against Newton v1.6.1 (commit 713fecd) with Study 1's `unit_friction_direction.diff` applied
(`patched_source.txt`). A new module, `semi_implicit/kernels_contact_normal.py`, holds two copies, of the stock kernel
and of Study 1's, whose only change is the normal force: the linear spring-dashpot in both phases kept from pulling,
`min(ke d + kd vn, 0)` while the contact overlaps (the no-tension linear dashpot of Schwager and Poeschel, Granular
Matter 9, 465-469, 2007), with the shapes' own `ke` and `kd`. Friction is bounded by that normal force, as in the stock
kernel. `NEWTON_CONTACT_DAMPING_NO_PULL=1`, read once when `kernels_contact` is imported, launches the matching copy at
the two call sites; nothing else changes.

## The five checks

Eleven suites of the first deep dive's ten tests, against the kept suites of runs 007 and 013.

| Check | Measured | |
|---|---|---|
| **1. Required** | F11: the drop rebounds 0.1% to 2.7% of its height from 2.5 ms down as released, rising as the step shrinks (runs 007, 017) | Held |
| **2. Correct** | With the switch, the drop rebounds **0 at every step from 5 ms down** on both solvers, with or without Study 1's patch, and at 0.625 ms the cube rests at the same depth as released. With both switches the refinement chain's hop after the landing is gone (0 at every step) and **T08 passes on both solvers**. But **at 10 ms the drop rebounds 16,936 per 10,000, as released**: its file is byte-identical to the release's, and **T04 fails** on that one step | **Failed** |
| **3. Nothing else gets worse** | With Study 1's patch, against Study 1's patch alone: T02, T05 and T10 still pass; T08 now passes; the slip at 0.625 ms reads closer to its right answer (T07: 993,100 against 1,019,200 um/s, right answer 980,000); the hold at 0.625 ms creeps 2% faster (T06: 2,704 against 2,645 um/s), and Featherstone's slip at 10 ms, an unstable step, reads further from its answer (T07: 2,799,600 against 1,679,900 um/s). Alone, with the stock friction, against the release: Featherstone's refinement chain fails T08 (gaps 189,945 then 197,355), which it passes as released, and the held cube slides back faster at 0.625 ms (T06: -14,709 against -5,538 um/s) | Not met |
| **4. Safe when off** | The patched source with no switch: 39 of 39 files byte-identical to Newton from PyPI on each solver; with Study 1's switch only, 39 of 39 to run 007's patched suites on each. With the switch on, XPBD, VBD and the MuJoCo solver (elliptic cone) play 39 of 39 byte-identical: they do not use the kernel | Held |
| **5. The solver keeps converging** (here: no play stops being a number) | No play's state stopped being a number | Held |

| On the ten tests | As released | Study 1's patch | This patch alone | Both |
|---|---|---|---|---|
| SemiImplicit | 4 | 6 | 4 | **7** |
| Featherstone | 4 | 6 | 3 | **7** |

## What it shows

- **The patch removes F11's rebound.** From 5 ms down, a body dropped with a restitution of 0 does not rebound at any
  step on either solver, and with Study 1's friction patch the refinement chain passes. On the suite's 2 kg cube,
  Newton's own `ke` and `kd` on four corners damp the contact 1.41 times critically, so the no-tension spring-dashpot
  gives no rebound at all. For a body heavier than 4 kg on four corners, the same constants damp it less than
  critically, and the dashpot itself would rebound: the patch makes the rebound the contact law's, not zero, there.
  That case was not played.
- **The 10 ms step is a separate defect.** At 10 ms the cube penetrates about 13 mm in one step, the explicit contact force
  of that one step launches it, and it leaves the contact before the separation phase where the patch acts. The play
  is byte-identical with and without the patch. That is the 10 ms instability already recorded (F6), which the
  predictions named before the plays.
- **The patch is not correct by the checks as set, and it does not stand alone.** Check 2 fails at 10 ms. With the
  stock friction it makes Featherstone's refinement chain and the hold worse. With Study 1's patch every reading but
  two improves or holds: the hold at 0.625 ms creeps 2% faster, and Featherstone's slip at 10 ms reads further from
  its answer. The patch stays in design; no study is registered.
