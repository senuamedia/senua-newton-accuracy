# Run 085: XPBD's hold with the speed floor removed, the friction patch on, against its iterations (issue 6)

Not registered: a design probe that decides nothing and states no prediction. Run 083 read the patched hold as 0 from
32 iterations, but XPBD's speed floor reads any creep under 0.1 mm/s as 0. Here run 044's hold with the floor removed
(Study 10's patch) on both arms: the floor patch alone, and the floor patch with the friction patch
([`xpbd_friction_total_on_nofloor.diff`](../../patches/in_design/xpbd_friction_total_on_nofloor.diff)), at 8 to 128
iterations, both contact relaxations, at 2 and 0.5 ms: the creep itself.

## What was found

Played 20 October 2026 on the second x86-64 host, from the record at 9c157b1 (`measured.txt`).

| The hold's creep with the floor removed, um/s | 8 | 16 | 32 | 64 | 128 iterations |
|---|---|---|---|---|---|
| 2 ms, the floor patch alone (relaxation 0.8; 1) | 2,507; 2,063 | 1,581; 1,598 | 1,531; 1,592 | 1,531; 1,592 | 1,531; 1,592 |
| 2 ms, with the friction patch | 1,980; 1,410 | 774; 284 | 21; 2 | **1; 2** | **1; 2** |
| 0.5 ms, the floor patch alone | 626; 515 | 393; 400 | 380; 400 | 380; 400 | 380; 400 |
| 0.5 ms, with the friction patch | 492; 351 | 193; 64 | 6; 8 | **6; 7** | **6; 8** |

- **The release never passes its friction floor**, however many iterations: 1,531 and 380 um/s from 32 on.
- **With the friction bounded on the step's totals the hold converges to within 8 um/s** (the suite's T06 allows 10):
  from 64 iterations at both steps and relaxations, already at 32 but for the 2 ms default relaxation (21 um/s). What
  is left, 1 to 8 um/s, does not fall with more iterations.
- Issue 6 on XPBD is then a configuration and a patch: the friction bounded on the totals, the speed floor removed, and
  enough iterations for the solve to converge; its study registers 64.
