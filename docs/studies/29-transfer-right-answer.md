# Study 29: one model across engines, each held to the right answer

**Outcome: 6 of 6 rule lines held; issue 22 resolved as far as these hosts can play it.** Registered 21 October 2026
([`PREREGISTRATION_29.md`](../../preregistrations/PREREGISTRATION_29.md)); played once as
[run 132](../../validation/run_132_study_29/README.md). With the record's friction chains, XPBD, SemiImplicit and
Featherstone play one model right on every scene at 1 and 0.5 ms, and as MuJoCo C does wherever MuJoCo C is right; where
MuJoCo C departs (its push 1.4% slow at 0.5 ms here, 4.5% at 1 ms in Study 28), they do not.

## How it got here

| Run | What | Result |
|---|---|---|
| [131](../../validation/run_131_study_28/README.md) (Study 28) | MuJoCo C as the reference | Newton's three transfer on the slide and hold; at 1 ms MuJoCo C's own push 4.5% slow, the precondition failed |
| (after run 131) | MuJoCo C's push | The same with noslip or without; its elliptic soft friction rises with speed |

## The rules and the result

| Rule | Result |
|---|---|
| R1 Newton right | held: the slide within 1 in 200, the hold 0 to 6 um/s, the push within 1 in 2,600, at both steps |
| R2 the transfer | held: 15 of 15 lines within 1 in 100 of MuJoCo C where MuJoCo C is right |
| R3 the fault is there as released | held at both steps |
| R4 a number | held |

## What it decides

**Issue 22 resolved as far as these hosts can play it.** The report's PhysX replay is not played: these hosts have no
PhysX. The engines' remaining disagreement on these scenes is MuJoCo's soft friction on a push.
