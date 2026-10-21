# Run 075: runs 056, 062 and 063 on pull request #4318 with the speed-floor patch (issues 19 and 27)

Not registered: a design probe that decides nothing and states no prediction. Runs 056 (a joint's velocity and effort
limits), 062 (a driven joint at rest in issue 27's reports' scenes) and 063 (a loop-closing joint) played again
unchanged, each by its own script in a scratch copy of the record, with #4318 and the speed-floor patch first on the path
for every solver (run 065's engine). Their readings and checks are kept in `readings/`, beside each run's own.

## What was found

Played 20 October 2026 on the second x86-64 host, from the record at 01d1116. Each run's checks against the record's
(the readings in `readings/`):

| Run | As recorded | With #4318 and the speed-floor patch | What moved |
|---|---|---|---|
| 056, velocity and effort limits | 7 of 25 | 8 of 25 | XPBD's free arm under 1 N m now reaches the other solvers' 3.97 rad/s (6.91 as released, issue 25's 1.75); XPBD still applies neither limit with its default drive (`pd` is opt-in) |
| 062, a drive held at rest | 30 of 50 | 34 of 50 | XPBD now holds its drive past pi and past a full turn (3.5 and 7.0 rad), still in 1 and 1,000 steps; SemiImplicit as before (not changed by #4318) |
| 063, a loop-closing joint | 9 of 20 | 8 of 20 | **XPBD loses the loop-closing joint's drive** (to 0.3 rad as released, -1.28 rad with #4318) and its limit misses further (-0.38 rad as released, -2.30 rad, against a limit at 0.5 rad) |

#4318 fixes XPBD's drive past a turn (F22's XPBD part) and its torque answer, and breaks XPBD's limit and drive on a
loop-closing joint, which the release applied: a regression to report with the pull request.
