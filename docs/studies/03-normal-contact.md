# Study 3: SemiImplicit's and Featherstone's normal contact, damped in both phases and kept from pulling

**Outcome: 9 of 9 rule lines held; the patch validated within the range Newton's explicit integration can carry.**
Registered 15 October 2026 ([`PREREGISTRATION_03.md`](../../preregistrations/PREREGISTRATION_03.md)); played once as
[run 033](../../validation/run_033_study_03/README.md).

## The question

SemiImplicit's and Featherstone's body contact damps the normal only while the contact closes, so a body dropped with
no restitution rebounds, more as the step shrinks (F11). A patch makes the normal force the linear spring-dashpot in
both phases kept from pulling, min(ke d + kd vn, 0), with Newton's own constants (Schwager and Poeschel 2007), on top of
Study 1's friction patch. Does the rebound go, and does nothing else get worse?

## How it got here

| Run | What | Result |
|---|---|---|
| [017](../../validation/run_017_refinement_chain_trace/README.md) | Why Study 1's patch fails the refinement chain | Traced to the normal contact's rebound |
| [020](../../validation/run_020_contact_damping_no_pull/README.md) | The patch held to the five checks on the ten-test suite | No rebound from 5 ms down and the refinement chain passing (7 of 10), but the 10 ms drop as released and the 0.625 ms hold 2% faster |
| [021](../../validation/run_021_explicit_limits/README.md) | Why those two checks failed | Newton's explicit integration: the damper's monotone limit (4 kd h / m at most 1) and friction's (10 kf h / m), outside the contact law |

## The rules and the result

The rules apply where both limits, derived in run 021 (Belytschko, Liu and Moran 2000, sections 6.2 and 6.6), are met; the
steps outside them were played and reported. A 3 kg cube, half-size 0.06 m, at steps no probe used.

| Rule | Result |
|---|---|
| R1 safe when off: 32 of 32 files | held |
| R2 the rebound is there with Study 1's patch alone: 184 and 285 per 10,000 at 0.75 and 0.375 ms | held |
| R3 no rebound with both patches: 0 at all five ruled steps, 6 ms to 0.375 ms | held |
| R4 Coulomb's slide: 3,499 and 3,500 per 10,000 (3,500) | held |
| R5 the weight at rest: 29,400 mN | held |
| R6 the ground never pulls on a lift | held |
| R7 the steady hold at the viscous law's 1,985 um/s: 1,985 and 1,984 | held |
| R8 XPBD untouched | held |
| R9 no play stops being a number | held |

Reported: at 12 and 15 ms (past the damper's limit) every arm rebounds as released, byte for byte; at 0.75 ms (past
friction's) the hold creeps at a chatter's speed in every arm.

## The patch

[`patches/contact_damping_no_pull.diff`](../../patches/contact_damping_no_pull.diff) (sha256 15d7489e80b018ab...),
against Newton v1.6.1 with `unit_friction_direction.diff` applied. Switches: `NEWTON_UNIT_FRICTION_DIRECTION=1` and
`NEWTON_CONTACT_DAMPING_NO_PULL=1`. See [the patches](../patches.md).
