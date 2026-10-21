# Run 098: VBD's hold with its contacts carried from step to step (issue 6)

Not registered: a design probe, its predictions pushed with [`play.sh`](play.sh) before any play. Newton 1.7.0 from PyPI
as released; the contact rig gains an option at this run, `matching=` (the collision pipeline's contact matching,
`CollisionPipeline(contact_matching=...)`), unset leaving every play as before (C0 checks one).

## Why

[Run 095](../run_095_vbd_friction_epsilon/README.md) found VBD's rigid contact friction is AVBD's Coulomb projection
of a penalty times the slip plus a multiplier, its creep falling with the iterations. Newton's VBD starts every
contact cold each step unless `rigid_contact_history=True` (default `False`), which with the collision pipeline's
contact matching restores a contact's state from the step before: with `latest` matching its multipliers as a warm
start, with `sticky` matching "persistent friction anchors" (Newton's documentation, `SolverVBD`). A contact started
cold must rebuild the friction that holds the load within each step's iterations, from a slip; one carried over need
not. Here VBD-ALM (Newton's announced default) cold, with latest and with sticky matching; VBD on its legacy path with
sticky matching; and VBD's legacy penalty ramp (`rigid_avbd_beta=1e5`, its documentation's example), on run 044's hold
at 2, 0.5, 0.125 and 0.0625 ms, and VBD-ALM's slide cold and sticky at 2, 0.5 and 0.125 ms.

## Predictions (pushed before the plays)

| Check | Prediction |
|---|---|
| C0 | With `matching` unset the rig plays run 091's VBD-ALM hold at 0.5 ms byte for byte |
| C1 | VBD-ALM with sticky matching holds within 10 um/s of still at every step |
| C2 | VBD-ALM with sticky matching slides within 1 in 100 of Coulomb's 102,041 um at every step |

Reported: VBD-ALM cold and with latest matching, VBD with sticky matching, the legacy ramp.

## What it found

Played 20 October 2026 on the Newton host (`started.txt`, `finished.txt`); the measured lines in `measured.txt`, the
checks in [`checks.txt`](checks.txt). **2 of 3 checks held.**

| Check | Result |
|---|---|
| C0 | Held: with `matching` unset the rig plays run 091's VBD-ALM hold at 0.5 ms byte for byte |
| C1 | Held: VBD-ALM with sticky matching 0, 0, 0 and 0 um/s at 2, 0.5, 0.125 and 0.0625 ms |
| C2 | **Failed**: VBD-ALM's slide with sticky matching 138,121, 139,047 and 139,426 um, 36% past Coulomb's 102,041 |

| Hold, mean speed | 2 ms | 0.5 ms | 0.125 ms | 0.0625 ms |
|---|---|---|---|---|
| VBD-ALM, cold (as released) | 1 | 0 | 74 | 225 um/s |
| VBD-ALM, latest matching | -5 | 15 | 24 | 98 um/s |
| VBD-ALM, sticky matching | 0 | 0 | 0 | 0 |
| VBD, sticky matching | 0 | 0 | 0 | 0 |
| VBD, legacy penalty ramp 1e5 | 23,127 | 100,078 | 384,858 | 663,352 um/s |

- **Carrying the contacts from step to step holds the load on both VBD paths, at every step**: with
  `rigid_contact_history=True` and the collision pipeline's sticky matching, Newton's own options, VBD-ALM and VBD hold
  the cube still at every step, down to 0.0625 ms, where cold VBD-ALM creeps 225 um/s and cold VBD (run 095) 223 mm/s
  at 0.125 ms. Latest matching, which restores the multipliers as a warm start without the material anchor, cuts
  VBD-ALM's creep at small steps but does not stop it. The legacy penalty ramp makes VBD's creep worse.
- **The slide is the same cold and sticky** (138,121 um at 2 ms both; 139,051 and 139,047 at 0.5 ms), so the history
  costs the slide nothing, but VBD-ALM's slide is 36% past Coulomb's distance at every step: early in the slide its
  friction is about 0.31 of the normal force where Coulomb's is 0.5 (the contact force columns at 40 ms: friction 3,136
  mN against 10,051 mN), the cube sinking into the ground at about 9 mm/s there. That is VBD-ALM's sliding friction,
  not its hold; Study 4 measured it right at 0.2 ms on a pushed slide (3,039 per 10,000 for 3,000). Recorded as a
  finding; not this probe's to fix.
