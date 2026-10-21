# Run 087: Study 14, played once

20 October 2026, 12:23 to 12:25 UTC, on the Newton host, by [`play.sh`](play.sh), under
[`PREREGISTRATION_14.md`](../../preregistrations/PREREGISTRATION_14.md), registered and pushed with the runner before
any play. The runner's dry run (`dry/`, throwaway parameters) ran to the end first. Played from the record at its commit
c7eab01, on Newton 1.7.0 as released (and Study 12's Featherstone limit engine for the reported plays). Measured by
Senua AI's `sx_contact` (`swing`, each play's statistics line) and judged by its `rule` (`rules.txt`).

## The result: 3 of 3 rule lines held

| Where the arm turns back after its first strike, rad | 4 kg: 0.1 ms | 0.025 ms | 1.5 kg: 0.1 ms | 0.025 ms |
|---|---|---|---|---|
| **SemiImplicit, `joint_attach_ke=1e6`** (R2) | **-0.2347** | **-0.2350** | **-0.3883** | **-0.3874** |
| The no-tension closed form | -0.2332 | | -0.3879 | |
| SemiImplicit, the default attachment (reported) | -1.0163 | -1.0163 | -0.7485 | -0.7488 |
| Featherstone as released (reported) | -0.2463 | -0.2452 | -0.4121 | -0.4144 |
| Featherstone, Study 11's `=1` (reported) | -0.2389 | -0.2381 | -0.3923 | -0.3932 |

R1 (every stiff play a number throughout) and R2 (both arms, both steps, within 0.02 rad: within 0.0018) held.

## What it shows

**Issue 16 shows no departure on SemiImplicit with its joint stiff enough to be one**: the strike is the spring and
damper kept from pulling to 2 mrad, where Featherstone as released pulls the arm 0.012 to 0.026 rad lower. With
Newton's default attachment (1e4 N/m) SemiImplicit's joint is soft enough that the strike is the joint's (the 4 kg arm
does not rebound), a property of SemiImplicit's penalty joints and their configuration, not of the limit's law. With
Study 11 (Featherstone fixed by the limit patch), issue 16 is resolved.
