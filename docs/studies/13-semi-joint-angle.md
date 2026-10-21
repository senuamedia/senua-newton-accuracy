# Study 13: SemiImplicit's joint angle, its D6 fault sized from Study 12

**Outcome: 16 of 16 rule lines held; issue 27 fixed and validated** on SemiImplicit by Senua AI's joint patch, its angle
half. Registered 20 October 2026 ([`PREREGISTRATION_13.md`](../../preregistrations/PREREGISTRATION_13.md)) after Study
12's fault rule for the D6 failed at 0.5 ms; played once as [run 080](../../validation/run_080_study_13/README.md).

## The rules and the result

| Rule | Result |
|---|---|
| R1 safe when off | held: 12 of 12 |
| R2 the fault is there: the drive held at -7.6 rad turns at 10,000 urad/s or more after one step | held: 12,566 to 100,531 |
| R3 held past a full turn: within 100 urad/s, the reading unchanged | held: 0 to 5 urad/s |
| R4 the fault is there: the D6's first angle at 0.22 rad or more after 1 s or more | held: 0.558 to 1.044 rad |
| R5 the D6 held within 1 mrad of 0.2 and 0.4 rad | held: exactly |

## What it decides

**Issue 27, fixed and validated:** [`semi_joint.diff`](../../patches/newton-1.7.0/semi_joint.diff),
`NEWTON_SEMI_JOINT_ANGLE=1`: a single rotational DOF's angle measured within pi of the middle of its limit range or, for
a range 2 pi wide or wider, its drive's target (pull request #4316's rule, which Newton proposes for XPBD), and a D6's
relative rotation read in the basis of its own axes. The same file's `NEWTON_SEMI_JOINT_LIMIT=1` (the limit kept from
pulling) stays in design: on SemiImplicit a strike is governed by its joint attachment (runs 077, 079).
