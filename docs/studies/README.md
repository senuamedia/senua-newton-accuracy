# The studies

A study is one pre-registration, played once. Its question, scenes and rules are written and pushed before any of
its plays exist; its rules are judged by the Senua AI Robotics Core's measuring programs; a rule that fails is reported
as failed.

The record is published as one snapshot. Senua AI keeps its full history, in which every registration, play script and
runner was committed and pushed before its play; where a page or script names a commit of this repository, it is a
commit of that history.

| | Study | Outcome |
|---|---|---|
| 1 | [Coulomb's friction for SemiImplicit and Featherstone](01-coulomb-friction.md) | 11 of 11 rule lines held; the patch validated |
| 2 | [XPBD with its restitution option: no bounce and Coulomb's friction at an impact](02-xpbd-restitution-friction.md) | 9 of 9 rule lines held; the patch validated |
| 3 | [SemiImplicit's and Featherstone's normal contact, damped in both phases and kept from pulling](03-normal-contact.md) | 9 of 9 rule lines held; the patch validated within the range Newton's explicit integration can carry |
| 4 | [VBD's velocity carried, not read back from 32-bit poses](04-vbd-carried-velocity.md) | 5 of 5 rules held; the patch validated as registered (some readings VBD gets wrong for another cause moved further, reported) |
| 5 | [XPBD's joint angle tracked continuously past pi](05-xpbd-joint-angle.md) | 6 of 8 rule lines held; R4 failed (XPBD's own limit returns the arm, F14); the patch stays in design |
| 6 | [The MuJoCo solver's joint limit with the stiffness and damping Newton gives it](06-mujoco-limit.md) | 9 of 9 rule lines held; the patch validated where the step is inside the limit spring's range |
| 7 | [The record on Newton 1.7.0](07-newton-1.7.0.md) | 2 of 4 rules held; every SemiImplicit, Featherstone and XPBD finding stands on 1.7.0 byte for byte; R1 and R2 failed on the runner's and the judge's own files and VBD's joint past pi, traced |
| 8 | [The fixes proposed upstream, measured](08-upstream-fixes.md) | 0 of 2 rule lines held, as predicted: #4010 fixes the cone and makes the slide depend on its width; #4316 stops the throw past pi, not the limit's throw-back |
| 9 | [Five issues answered by Newton's own options](09-newtons-own-options.md) | 14 of 14 rule lines held; issues 10 and 14 fixed by configuration, 11 and 13 on the MuJoCo solver; 9's normal part fixed, its friction part not played |
| 10 | [XPBD's joints and its speed floor](10-xpbd-joints-floor.md) | 24 of 24 rule lines held; issues 7, 17, 25 and 26 fixed and validated (Senua AI's speed-floor patch; pull requests #4317 and #4318) |
| 11 | [MuJoCo's recommended configuration through Newton, the CPU path, and Featherstone's limit kept from pulling](11-mujoco-noslip-cpu-featherstone-limit.md) | 21 of 21 rule lines held; issue 15 fixed on the MuJoCo solver's CPU path, 6 on the MuJoCo solver, 16 on Featherstone; 24 no departure on 1.7.0 |
| 12 | [SemiImplicit's joint angle, and Featherstone's limit integrated implicitly](12-semi-angle-featherstone-implicit-limit.md) | 20 of 21 rule lines held; issue 28 fixed and validated; issue 27's fix held every rule, its D6 fault rule failed at 0.5 ms, so 27 stays open (Study 13 registered) |
| 13 | [SemiImplicit's joint angle, its D6 fault sized from Study 12](13-semi-joint-angle.md) | 16 of 16 rule lines held; issue 27 fixed and validated |
| 14 | [SemiImplicit's joint limit, its joint stiff enough to be one](14-semi-limit-stiff-joint.md) | 3 of 3 rule lines held; issue 16 resolved (fixed on Featherstone, no departure on SemiImplicit) |
| 15 | [XPBD holds a load at rest](15-xpbd-holds.md) | 6 of 6 rule lines held; issue 6 fixed and validated on XPBD (Senua AI's friction patch, the speed-floor patch, 64 iterations) |
| 16 | [Featherstone's step as the classic Runge-Kutta scheme](16-featherstone-rk4.md) | 9 of 9 rule lines held; issue 11 fixed and validated on Featherstone (Senua AI's RK4 patch) |
| 17 | [VBD holds a load at rest with its contacts carried](17-vbd-contact-history.md) | 8 of 11 rule lines held; issue 6 fixed and validated on VBD-ALM (Newton's own contact history with sticky matching); on VBD's legacy path the hold held but its slide changed (toward Coulomb's), R3 failed |
| 18 | [SemiImplicit's and Featherstone's friction as Coulomb's law at the step's end](18-semi-featherstone-coulomb-friction.md) | 19 of 19 rule lines held; issue 6 fixed and validated on SemiImplicit and Featherstone, issue 9 on both (Senua AI's Coulomb friction patches) |
| 19 | [VBD's legacy path holds a load at rest with its contacts carried](19-vbd-legacy-contact-history.md) | 4 of 4 rule lines held; issue 6 fixed and validated on VBD's legacy path (Newton's own contact history with sticky matching) |
| 20 | [XPBD's joint limit holds an arm and stops a chain as a hard limit does](20-xpbd-limit-arm-chain.md) | 13 of 13 rule lines held; issue 8 fixed and validated on XPBD (Senua AI's joint-angle patch, fourth form, 64 iterations) |
| 21 | [Nothing a solver ignores goes unsaid, and SemiImplicit plays a loop](21-joint-features-said.md) | 7 of 7 rule lines held; issue 19 fixed and validated (Senua AI's joint-feature warnings patch with pull request #3552; SemiImplicit with joint_attach_kd=0) |
| 22 | [VBD's rigid solve in displacement form](22-vbd-displacement.md) | 12 of 14 rule lines held; not validated: the spinning body still and the chain's loss falling with the step, but a 32-bit cost 10 m out and the slide changed by 1.4%; issues 13 and 12 stay open |
| 23 | [VBD's spinning body still, its contacts settling, in displacement form](23-vbd-displacement-spin-contacts.md) | 7 of 7 rule lines held; issue 13 fixed and validated on VBD-ALM and VBD (Senua AI's VBD displacement patch); with Study 9, issue 13 resolved |
| 24 | [A light cloth and a box coupled two-way, the feedback the force the cloth exerts](24-cloth-box-coupling.md) | 14 of 14 rule lines held; issue 21's #4698 part fixed and validated (Senua AI's VBD proxy coupling patch) |
| 25 | [MuJoCo's recommended configuration on the MuJoCo solver's Warp path](25-mujoco-warp-noslip.md) | 14 of 14 rule lines held; issue 15 fixed and validated on the Warp path (Senua AI's MuJoCo Warp noslip patch); with Study 11, issue 15 resolved |
| 26 | [Two shapes' frictions combined by one rule on every solver](26-friction-combination.md) | 44 of 44 rule lines held; issue 18's combination part fixed and validated (Senua AI's friction combination patch) |
| 27 | [A static friction coefficient imported from USD and applied](27-static-friction.md) | 13 of 16 rule lines held; the import fixed, the coefficient held by SemiImplicit and Featherstone; XPBD's own floor at 0.25 ms above the bar: issue 18's static part open |
| 28 | [One model across engines, MuJoCo C as the reference](28-transfer-mujoco-c.md) | 14 of 18 rule lines held; Newton's three transfer and are right; MuJoCo C's own push 4.5% slow at 1 ms: issue 22 open |
| 29 | [One model across engines, each held to the right answer](29-transfer-right-answer.md) | 6 of 6 rule lines held; Newton's three right and transfer from MuJoCo C wherever it is right: issue 22 resolved as far as these hosts can play it |
| 30 | [A static friction coefficient imported and applied, XPBD's slip seen whole](30-static-friction-xpbd-slip.md) | 16 of 16 rule lines held; issue 18 resolved (Senua AI's static friction and XPBD friction slip patches, with pull request #4306) |
| 31 | [The implicit MPM solver's thin colliders kept whole by a margin](31-mpm-leak-quarter-voxel.md) | 3 of 4 rule lines held; a quarter voxel failed at 8 mm, half a voxel held: #4712's leak open |
| 32 | [The implicit MPM solver's thin colliders kept whole by a margin of half a voxel](32-mpm-leak-half-voxel.md) | 2 of 3 rule lines held; 9 particles out at a 14 mm voxel and 12 substeps: a margin is not the fix, #4712's leak open |
| 33 | [A fast body kept from passing through a thin slab](33-tunnelling.md) | 6 of 8 rule lines held; none through with the configuration, but SemiImplicit's and Featherstone's slide moved 1 in 204: issue 20's tunnelling open |
| 34 | [A fast body kept from passing through a thin slab, the patch on contacts strictly apart](34-tunnelling-strictly-apart.md) | 7 of 8 rule lines held; the slides byte for byte, but a cube landing touching at speed through on SemiImplicit and Featherstone: tunnelling open there |
| 35 | [A fast body kept from passing through a thin slab, every contact given its normal](35-tunnelling-every-contact.md) | 6 of 6 rule lines held; issue 20's tunnelling fixed on Newton's own solvers (XPBD by Newton's own configuration, SemiImplicit and Featherstone by Senua AI's speculative normal patch) |
| 36 | [VBD's chain far from the origin, its poses carried in two 32-bit numbers](36-vbd-pose-carry.md) | 15 of 15 rule lines held; issue 12's VBD part fixed and validated on VBD's compliant-ALM path (Senua AI's VBD displacement patch and pose carry); the legacy path and XPBD's part open |
| 37 | [XPBD's joints solved colour by colour, at full relaxation](37-xpbd-joint-colours.md) | 8 of 9 rule lines held; R4 failed (32 iterations not converged on its chain); stable at full relaxation, the free chain's loss falling with the step, seven times below the released solver's at 0.1 ms; issue 12's XPBD part open |
| 38 | [XPBD's joints solved colour by colour, at full relaxation, at two iteration counts](38-xpbd-joint-colours-two-counts.md) | 12 of 12 rule lines held; issue 12's XPBD part fixed and validated for a free chain (Senua AI's joint colours with XPBD's own full relaxation) |
| 39 | [VBD's legacy path far from the origin, its poses carried and its joint stabilisation off](39-vbd-legacy-pose-carry-alpha.md) | 10 of 15 rule lines held; R3 failed (the far chain not within 1 in 10 of the origin at four of five steps) and R5's slide line (VBD's legacy cold slide, the same unset); the far chain's loss falls with the step at every distance; issue 12's VBD legacy part stays open |

The design probes that led to each study are in [the runs](../runs.md).
