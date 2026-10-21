# Run 083: XPBD's hold against its iterations, with the friction patch (issue 6)

Not registered: a design probe that decides nothing and states no prediction. Run 082 found the friction patch holds
run 044's cube at 32 iterations and changes nothing at XPBD's default 2. Here the same hold at 2 to 32 iterations, at
XPBD's default contact relaxation (0.8) and at 1, at 2 and 0.5 ms, as released and with the patch: where the patched
hold converges. The speed floor stays on (under 0.1 mm/s reads 0).

## What was found

Played 20 October 2026 on the Newton host, from the record at fbe89ef (`measured.txt`).

| The hold's creep, um/s | 2 | 4 | 8 | 16 | 32 iterations |
|---|---|---|---|---|---|
| 2 ms, as released (relaxation 0.8; 1) | 10,862; 8,174 | 4,951; 3,898 | 2,507; 2,063 | 1,581; 1,598 | 1,531; 1,592 |
| 2 ms, with the patch | 10,862; 8,174 | 4,824; 3,612 | 1,980; 1,409 | 774; 284 | **0; 0** |
| 0.5 ms, as released | 2,715; 2,043 | 1,237; 974 | 626; 515 | 393; 400 | 380; 400 |
| 0.5 ms, with the patch | 2,715; 2,043 | 1,206; 903 | 492; 351 | 193; **0** | **0; 0** |

- **XPBD's creep at rest has the two causes run 027 and run 044 named, one on top of the other.** The solve left
  unconverged gives a creep that falls with the iteration count (about as one over it); as released it stops falling
  at the friction floor (1,531 and 380 um/s), the friction bounded by each iteration's normal correction.
- **With the friction bounded on the step's totals the creep keeps falling** and reads 0 (under the speed floor's
  0.1 mm/s) from 32 iterations at both steps, from 16 with a contact relaxation of 1 at 0.5 ms.
- The speed floor hides any creep under 0.1 mm/s; with it removed (Study 10's patch) the next probe reads the creep
  itself. The friction patch's form for the floor patch's tree:
  [`xpbd_friction_total_on_nofloor.diff`](../../patches/in_design/xpbd_friction_total_on_nofloor.diff) (sha256
  94908182330faa16...: both add `import os`; this form adds only the rest).
