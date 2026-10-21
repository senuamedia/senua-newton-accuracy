# Run 081: XPBD's joint limit on a chain, against its iterations (issue 8)

Not registered: a design probe that decides nothing and states no prediction. Run 061 found the joint-angle patch's
fourth form holds one arm at its limit but not a chain of two links, the limit sized with its own joint's anchor held
while the outboard link carries momentum. Here run 061's chain under that form at 2 to 128 iterations, at XPBD's default
relaxations and at 1, at 2.5 and 0.625 ms: does the chain hold once the solve between the limit and the outboard link
converges? Each play's last line (both joints' angles and speeds) and where it stopped being a number.

Its first launch played nothing: each play line without extra options ended in a space, which xargs reads as the line
continuing, so two plays were handed to the rig as one; the runner was corrected (no trailing space) before any play
existed.

## What it measured

Played 20 October 2026 (`started.txt`, `finished.txt`); each play's last line in `measured.txt`, its record in `runs/`
and statistics in `stats/`. The first joint starts at 0 turning at 2 rad/s toward its upper limit at 3.3 rad, reached
at about 1.65 s.

| Step | Iterations | At XPBD's relaxations: joint 1 at 2.5 s | At relaxations of 1: joint 1 at 2.5 s |
|---|---|---|---|
| 2.5 ms | 2 | 2.513 rad, -3.63 rad/s | 3.816 rad, 1.6e6 rad/s (runs away) |
| 2.5 ms | 8 | 2.963 rad, -1.98 rad/s | -0.169 rad, -0.75 rad/s |
| 2.5 ms | 32 | 2.959 rad, -2.00 rad/s | -0.054 rad, 12.2 rad/s |
| 2.5 ms | 128 | 2.958 rad, -2.01 rad/s | -0.018 rad, 3.44 rad/s |
| 0.625 ms | 2 | 2.384 rad, -3.63 rad/s | 0.874 rad, 1.3e7 rad/s (runs away) |
| 0.625 ms | 8 | 2.862 rad, -2.67 rad/s | -0.503 rad, 1.3e7 rad/s (runs away) |
| 0.625 ms | 32 | 2.855 rad, -2.72 rad/s | -0.019 rad, -7.21 rad/s |
| 0.625 ms | 128 | 2.840 rad, -2.83 rad/s | -0.015 rad, 0.22 rad/s |

No play stopped being a number by the rig's test (`stops -1`), though four at relaxations of 1 reach speeds no chain
has. More iterations do not hold the chain: at XPBD's relaxations its first joint is thrown back off the limit at 2.0 to
2.8 rad/s from 8 iterations up, at both steps, the throw changing by under 2 in 100 from 8 to 128 iterations at 2.5 ms;
at relaxations of 1 it is thrown far back past its start or runs away. The coupling run 061 named is not a solve left
unconverged: the fourth form's limit, converged, still throws the chain. Issue 8 stays open.
