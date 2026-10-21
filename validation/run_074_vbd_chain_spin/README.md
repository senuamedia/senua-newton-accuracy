# Run 074: VBD's chain and VBD-ALM's spinning body (issues 12 and 13)

Not registered: a design probe that decides nothing and states no prediction. Study 9's free chain and spinning
body on VBD and VBD-ALM, as released and with Study 4's carried-velocity patch rebased onto 1.7.0
(`NEWTON_VBD_CARRIED_VELOCITY=2`, Study 7's `vbd` environment), at 2, 0.5 and 0.125 ms, on Newton 1.7.0. Read by
`sx_contact` (`chain`; `creep` and `stop` for the spinning body's centre). The question is only how far the
loss and the drift move with the step and with the carried velocity.

## What was found

Played 20 October 2026 on the second x86-64 host, from the record at cdd628d (`measured.txt`).

| | 2 ms | 0.5 ms | 0.125 ms |
|---|---|---|---|
| VBD's chain, kinetic energy after 2 s per million of its start, as released | 960,395 | 992,079 | **684,498** |
| With the carried velocity | 960,366 | 990,517 | **643,880** |
| The spinning body's centre, mean speed, um/s, as released (VBD and VBD-ALM alike) | 19 | 133 | **-3,751** |
| With the carried velocity | -1 | 51 | 162 |

- **VBD's chain loses more energy as the step shrinks** (4.0% at 2 ms, 31.6% at 0.125 ms), with or without the carried
  velocity: run 049's 32-bit poses, each step's small change lost in the pose it is added to.
- **The spinning body's centre drifts faster as the step shrinks** on VBD and VBD-ALM alike (the body touches nothing,
  so the ALM contact path plays no part); the carried velocity cuts the drift twentyfold but does not remove it.
- The VBD-ALM chain plays are not in the file list: the chain rig takes `solver=vbd` only.
