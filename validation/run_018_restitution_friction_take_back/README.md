# Run 018: the XPBD restitution-friction patch, second form: friction taken back

15 October 2026, 05:04 to 05:12 UTC. Not registered: a patch in design, held to the five checks. Played on the
Newton host by [`play.sh`](play.sh), whose hypothesis and predictions were pushed with the patch before the plays;
reading `reading.txt`, re-made byte for byte on the laptop from the same files, every suite's verdicts included.

## The hypothesis

Run 016's first form gave friction above Coulomb's over an impact. It adds friction where XPBD's restitution pass
pushes a contact apart, but where the pass pulls a contact's separation back (a negative normal impulse) it adds
nothing. Friction that does not stop a slip is at its bound, so where the contact still slips after the position
pass, the position pass gave friction of mu times its normal impulse. Once the restitution pass makes that impulse
smaller, the step's friction exceeds mu times its net normal impulse. The second form takes that friction back: an
impulse along the slip of mu times the normal impulse pulled back.

## The patch

[`patches/in_design/xpbd_restitution_friction_v2.diff`](../../patches/in_design/xpbd_restitution_friction_v2.diff)
(sha256 a572b966c46067e1...), against Newton v1.6.1 (commit 713fecd, `patched_source.txt`). It holds the first form
unchanged, selected by `NEWTON_XPBD_RESTITUTION_FRICTION=1`, and adds the second, selected by `=2`: a copy of the first
form's kernel whose friction row, where the accumulated normal impulse at a contact is negative and the contact
slips, sets the contact's friction impulse to mu times that impulse's size, along the slip. The variable is read
once, when the solver is made. The one changed line of Newton's code is the first form's: the stock launch names a
kernel variable.

## The five checks

Five arms on the first deep dive's ten-test suite, every scene unchanged, against run 016's kept suites of Newton
1.6.1 from PyPI and of the first form.

| Check | Measured | |
|---|---|---|
| **1. Required** | Run 015: friction at an impact 4% to 43% of Coulomb's with `enable_restitution`; run 016: the first form gives up to 24% above it | Held |
| **2. Correct** | The bounce is 0 at every step (T04 passes). Friction at the impact, per 10,000 (right answer 4,000): 3,998, 3,999, 3,999, 4,000, 3,999, 3,999, 4,000 at steps 1 to 1/64 of 10 ms (T05 passes). Over the impact and the 0.1 s after it: 3,999 at six steps and 4,000 at the seventh (T10 passes) | **Held** |
| **3. Nothing else gets worse** | T01, T02, T03, T08 and T09 pass; T06 and T07 read exactly as without the patch (54,333 and 3,395 um/s; 1,079,700 and 985,900 um/s). The suite's slide, rest, hold, slip, lift and free plays are byte-identical to `enable_restitution` alone | Held |
| **4. Safe when off** | The patched source with the switch unset: 39 of 39 files byte-identical to Newton from PyPI as released, and 39 of 39 with `enable_restitution`; the switch at 2 without `enable_restitution`, 39 of 39 | Held |
| **5. The solver keeps converging** (here: no play stops being a number) | No play's state stopped being a number | Held |

The first form, selected by `=1` in this build, plays as in run 016: 39 of 39 files byte-identical.

| Friction per 10,000 of the normal impulse (Coulomb's 4,000) | 10 ms | 5 ms | 2.5 ms | 1.25 ms | 0.625 ms | 0.3125 ms | 0.156 ms |
|---|---|---|---|---|---|---|---|
| At the impact: XPBD as released | 3,999 | 4,000 | 3,999 | 3,999 | 3,999 | 3,999 | 3,999 |
| `enable_restitution` alone | 991 | 1,326 | 554 | 401 | 147 | 1,457 | 1,733 |
| With the first form (run 016) | 3,998 | 4,669 | 4,248 | 4,000 | 3,999 | 3,999 | 4,000 |
| **With the second form** | **3,998** | **3,999** | **3,999** | **4,000** | **3,999** | **3,999** | **4,000** |
| Over the impact and 0.1 s after: as released | 3,999 | 3,999 | 4,000 | 3,999 | 4,000 | 3,999 | 3,999 |
| `enable_restitution` alone | 2,401 | 3,359 | 2,370 | 2,266 | 1,828 | 2,998 | 3,262 |
| With the first form (run 016) | 4,167 | 4,926 | 4,338 | 4,295 | 4,027 | 4,795 | 4,941 |
| **With the second form** | **3,999** | **3,999** | **3,999** | **3,999** | **3,999** | **3,999** | **4,000** |

**On the ten tests: XPBD as released passes 6, with `enable_restitution` 6, with the second form 8.** The two it fails
are the hold and the slip (T06, T07): XPBD's creep at rest (F4), which this patch does not address.

Reported, not deciding: the largest turn of the cube in the oblique impact. As released 0.20 to 0.64 rad; with
`enable_restitution` alone, and with the first form, at most 0.053 rad; with the second form 0.051 rad at 10 ms,
0.030 rad at 5 ms and 0 to 10 mrad from 2.5 ms down, larger than the first form's at the two finest steps (6.9 and
10.3 mrad against 2.4 and 4.4).

## What it shows

- **The hypothesis holds.** Taking friction back where the restitution pass pulls a contact down brings XPBD's
  friction at and after an impact to Coulomb's at every step, while the bounce with a restitution of 0 stays at 0.
- **The second form held all five checks**, so it goes to a registered study on fresh numbers, played once:
  [Study 2](../../preregistrations/PREREGISTRATION_02.md).
