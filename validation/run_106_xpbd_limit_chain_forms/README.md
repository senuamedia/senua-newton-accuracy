# Run 106: XPBD's joint limit on a chain against the converged right answer (issue 8)

Not registered: a design probe that decides nothing and states no prediction. [Run 105](../run_105_xpbd_limit_chain_reference/README.md)
found the right answer for run 061's chain struck against a hard limit (the first joint dead on the limit until half
a turn of the second link, then leaving it) and XPBD's fourth form rattling on the limit and leaving it early, the same
at every step. Here run 105's chain on XPBD as released (form 0) and under each form of the joint-angle patch (1, the
angle unwrapped past pi; 2, the swing's exact gradient; 3, the limit sized with the joint's anchor held; 4, that limit
applied in full), at XPBD's default relaxations and at 1, at 2, 16 and 128 iterations, at 0.625 ms, read beside run
105's reference: which, if any, converges on it as the iterations grow?

## What it measured

Played 20 October 2026 on the second x86-64 host (`started.txt`, `finished.txt`); the readings in `measured.txt`.

| First joint at 2.0 s and 2.5 s, rad | 2 iterations | 16 | 128 |
|---|---|---|---|
| Reference (run 105) | 3.300, 2.793 | | |
| Form 0, as released, default relaxations | thrown | thrown | thrown |
| Form 1, default relaxations | 3.298, 2.796 | 3.300, 2.901 | 3.300, 2.846 |
| Form 2, default relaxations | 3.231, 2.652 | 3.293, 2.877 | 3.300, 2.865 |
| Form 3, default relaxations | 3.130, 2.221 | 3.300, 2.866 | 3.300, 2.840 |
| Form 4, default relaxations | 3.213, 2.384 | 3.300, 2.882 | 3.300, 2.840 |
| Every form, relaxations of 1 | thrown (forms 0 to 4) | -0.002, 0.104 | 0.024, -0.015 |

- **At XPBD's default relaxations and 16 iterations or more, every form that reads the angle past pi (1 to 4) holds
  the first joint dead on the limit after the strike**, 3.300 rad and 0 rad/s at 2.0 s as the reference does, then
  lets it go; at 2.5 s the first joint is 0.05 to 0.11 rad short of the reference, turning back at 2.35 to 2.83 rad/s
  against 3.22. At XPBD's default two iterations the limit rattles (run 105).
- **As released the chain is thrown at every count**: its angle read wrapped past pi (F13, which form 1 fixes),
  and the limit's gain toward pi (F14).
- **At relaxations of 1 every form plays the same wrong chain** from 16 iterations on, byte for byte (10 of 10 plays
  form 1's): the first joint never reaches its limit and ends near its start. A full relaxation is not a setting that
  plays this chain.
- What is left at the default relaxations, 0.05 rad at 0.625 ms, may be XPBD's first-order error in the step; run 107
  plays the step.
