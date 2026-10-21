# Study 14: SemiImplicit's joint limit, its joint stiff enough to be one

**Outcome: 3 of 3 rule lines held.** On SemiImplicit, with its joint attachment stiff enough to be a joint
(`joint_attach_ke=1e6`), a limit strike turns the arm back where the spring and damper kept from pulling do, to 2 mrad:
issue 16 shows no departure on SemiImplicit, and with Study 11 (Featherstone fixed) it is resolved. Registered 20
October 2026 ([`PREREGISTRATION_14.md`](../../preregistrations/PREREGISTRATION_14.md)); played once as
[run 087](../../validation/run_087_study_14/README.md).

## How it got here

| Run | What | Result |
|---|---|---|
| [077](../../validation/run_077_semi_joint/README.md), [079](../../validation/run_079_semi_limit_kd0/README.md) | SemiImplicit's strike on light arms | Its attachment past its explicit bounds: the arm leaves the range, or is thrown about |
| [084](../../validation/run_084_semi_limit_heavy/README.md) | Heavy arms, the default attachment | The strike is the soft joint's (the 5 kg arm barely rebounds) |
| [086](../../validation/run_086_semi_limit_stiff/README.md) | The attachment a hundred times stiffer | The strike within 0.008 rad of the no-tension form as released |

## The rules and the result

| Rule | Result |
|---|---|
| R1 every play a number | held |
| R2 the strike within 0.02 rad of the closed form, two fresh arms, two steps | held: within 0.0018 rad |

## What it decides

**Issue 16, resolved:** fixed and validated on Featherstone by Senua AI's limit patch, its first form (Study 11); no
departure on SemiImplicit, its joint attachment stiff enough to be a joint. The default attachment (1e4 N/m) makes
SemiImplicit's joints soft: a configuration for heavy, fast-striking links.
