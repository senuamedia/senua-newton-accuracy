# Run 016: a patch in design, Coulomb's friction in XPBD's restitution pass

15 October 2026, 04:29 to 04:38 UTC. Not registered: a patch in design, held to the five checks before any study
registers its rules. Played on the Newton host by [`play.sh`](play.sh), whose predictions were pushed with the patch
before the plays; reading `reading.txt`, re-made byte for byte on the laptop from the same files, every suite's
verdicts included.

## The finding it answers

Run 015: XPBD's own `enable_restitution` removes its bounce with a restitution of 0 but cuts friction at an impact to
4% to 43% of Coulomb's. Newton's source shows why. XPBD's position pass bounds each contact's friction by mu times the
normal correction it makes in the same pass (`kernels.solve_body_contact_positions`: "limit friction based on
incremental normal force"). At an impact the position pass makes only part of the normal change within the step. The
restitution pass (`restitution_kernels.solve_manifold_restitution`) then makes the rest at once, with impulses along
the contact normal only, and no friction goes with them. At 10 ms the position pass gave the cube 0.33 m/s of its
1.33 m/s vertical change, and friction took 0.4 of that; the finer the step, the smaller the position pass's share
(the friction ratio 991, 554 and 147 per 10,000 at 1, 1/4 and 1/16 of 10 ms).

## The patch

[`patches/in_design/xpbd_restitution_friction.diff`](../../patches/in_design/xpbd_restitution_friction.diff) (sha256
745d296a6b57b1f9...), against Newton v1.6.1 (commit 713fecd, `patched_source.txt`). A new module,
`xpbd/restitution_friction_kernels.py`, holds a copy of the restitution pass with a friction row after each contact's
normal row: a tangential impulse opposing the contact's slip, no larger than mu times the normal impulse the pass has
applied at that contact, and no larger than what stops the slip. This is the velocity-level friction of Mueller et
al. (2020), section 3.6, bounded by the normal impulse of the same pass. Where the pass pulls a separation back (a
negative normal impulse), it adds no friction. The solver reads `NEWTON_XPBD_RESTITUTION_FRICTION` once, when it is
made, and launches the copy in place of the stock pass only when it is `1`. One line of `solver_xpbd.py` changes: the
stock launch names a kernel variable, which is the stock kernel unless the switch is set. Newton from source with the
patch applied was installed in its own environment, a copy of run 005's with the same dependencies.

## The five checks

Six arms on the first deep dive's ten-test suite, every scene unchanged: Newton 1.6.1 from PyPI with XPBD as released
and with `enable_restitution`; the patched source with the switch unset, both ways; the switch set, both ways.

| Check | Measured | |
|---|---|---|
| **1. Required** | Run 015: friction at an impact 4% to 43% of Coulomb's with `enable_restitution`; the cause read in the source (above) | Held |
| **2. Correct** | The bounce stays 0 at every step (T04 passes). Friction at the impact itself, per 10,000 (right answer 4,000): 3,998, **4,669**, **4,248**, 4,000, 3,999, 3,999, 4,000 at steps 1 to 1/64 of 10 ms; T05 fails at 5 ms and 2.5 ms. Over the impact and the 0.1 s after it: 4,167, **4,926**, 4,338, 4,295, 4,027, **4,795**, **4,941**, above Coulomb's at every step; T10 fails | **Failed** |
| **3. Nothing else gets worse** | T01, T02, T03, T08 and T09 pass, as with `enable_restitution` alone; T06 and T07 read exactly as without the patch (54,333 and 3,395 um/s; 1,079,700 and 985,900 um/s) | Held |
| **4. Safe when off** | The patched source with the switch unset: 39 of 39 files byte-identical to Newton from PyPI as released, and 39 of 39 with `enable_restitution`; the switch set without `enable_restitution`, 39 of 39 | Held |
| **5. Nothing blows up** | No play's state stopped being a number | Held |

| Friction per 10,000 of the normal impulse (Coulomb's 4,000) | 10 ms | 5 ms | 2.5 ms | 1.25 ms | 0.625 ms | 0.3125 ms | 0.156 ms |
|---|---|---|---|---|---|---|---|
| At the impact: XPBD as released | 3,999 | 4,000 | 3,999 | 3,999 | 3,999 | 3,999 | 3,999 |
| The same, `enable_restitution` | 991 | 1,326 | 554 | 401 | 147 | 1,457 | 1,733 |
| The same, `enable_restitution` with the patch | 3,998 | **4,669** | **4,248** | 4,000 | 3,999 | 3,999 | 4,000 |
| Over the impact and 0.1 s after: as released | 3,999 | 3,999 | 4,000 | 3,999 | 4,000 | 3,999 | 3,999 |
| The same, `enable_restitution` | 2,401 | 3,359 | 2,370 | 2,266 | 1,828 | 2,998 | 3,262 |
| The same, with the patch | 4,167 | **4,926** | 4,338 | 4,295 | 4,027 | **4,795** | **4,941** |

Newton from PyPI played every suite file of run 007 and run 015 again byte for byte (39 of 39 each).

## What it shows

- **The result is consistent with the cause read in the source.** Friction on the restitution pass's normal impulse
  brings the impact itself back to Coulomb's at five of seven steps, to within 2 parts in 10,000.
- **The patch is not correct as designed: it gives too much friction.** At two steps the impact takes up to 17% more
  than Coulomb's, and over the impact and the 0.1 s after it friction runs 0.7% to 24% above it at every step. The
  design gives friction on each contact's positive normal impulse and takes none back where the pass pulls a
  contact's separation back, so the friction can exceed mu times the net normal impulse. That is the likely cause; it
  is not tested.
- **Check 2 failed, so the patch stays in design and no study is registered.** XPBD has no setting of its own that
  passes both the bounce and Coulomb's friction at an impact.
