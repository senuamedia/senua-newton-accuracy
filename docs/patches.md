# The patches: Coulomb's friction for SemiImplicit and Featherstone, in XPBD's restitution pass, a normal contact that does not rebound, VBD's carried velocity, the MuJoCo solver's joint limit, XPBD's speed floor, Newton's own options and the fixes proposed upstream

## Validated: Coulomb's friction for SemiImplicit and Featherstone

**Validated** by the first registered study ([Study 1](studies/01-coulomb-friction.md), 11 of 11 rules). The file:
[`patches/unit_friction_direction.diff`](../patches/unit_friction_direction.diff) (sha256 dd4042afa2894458...), against
Newton v1.6.1 at the commit in [`UPSTREAM_COMMIT`](../UPSTREAM_COMMIT). Switch: `NEWTON_UNIT_FRICTION_DIRECTION=1`.

### What it corrects

SemiImplicit and Featherstone share one body contact kernel. It gives friction the direction `vt / H(vt)`, where H is
Warp's Huber norm, which is not divided by its width. That vector is |v| / H(v) long, not 1: 2 / |v| below the width
(1 m/s by default) and about 1 / width above it. The cap the kernel writes, mu N, is applied before that factor, so
it does not bound the result, and friction is that many times Coulomb's ([findings](findings.md), F1).

### What it changes

A new module, `semi_implicit/kernels_contact_unit.py`, holds a copy of the stock kernel in which only the friction
changes, to `vt / |vt| * min(kf * |vt|, mu * N)`: a unit direction, the size Coulomb's limit at most, and the stock
kernel's own viscous branch below it. At the kernel's two call sites (SemiImplicit's contact forces and Featherstone's
step) the copy is imported and launched instead only when the switch is set. The stock kernel is not changed; with the
switch unset the new module is never imported.

### What it was held to

| Check | Result |
|---|---|
| Required | Newton as released stops a slide at 44% of Coulomb's distance, a plate at 23%, and takes 75% too much friction over an impact (Study 1, R2) |
| Correct | On: the slide within 0.09% of Coulomb's distance, the plate within 0.12% at both smoothing widths, the impact's friction exact (R3, R4); the plate's file identical at both widths (R5); the cube no longer tips (R6) |
| Nothing else gets worse | On: the set-down and the drop on both solvers, and XPBD and the MuJoCo solver, byte-identical to the release (R7). Not covered by the study: on the ten-test suite (run 007) both solvers fail the refinement chain (T08) with the patch and pass it without. Traced (run 017): the failing step is the normal contact's rebound after the landing, which the frictionless drop shows the same way with or without the patch; the excess friction hid it as released ([findings](findings.md), F11). No revision of the patch follows |
| Safe when off | The patched Newton with the switch unset plays byte for byte as Newton from PyPI: 28 of 28 files in Study 1, 24 of 24 in run 005 |
| The solver keeps converging | No play's state stopped being a number (R8) |

### What it does not do

It does not touch the creep at rest (F4), the bounce, or the instability of these two solvers at 2 ms on a small cube
(F6). On the first deep dive's ten tests it takes SemiImplicit and Featherstone from 4 to 6: they pass the three friction tests (T02, T05, T10) and fail the refinement chain (T08), which they pass without it ([run 007](../validation/run_007_contact_suite/README.md)). The T08 failure is Newton's normal contact rebounding more as the step shrinks, not the patch: [run 017](../validation/run_017_refinement_chain_trace/README.md).

### Using it

```
git clone --branch v1.6.1 https://github.com/newton-physics/newton.git && cd newton
git apply <this repository>/patches/unit_friction_direction.diff
pip install -e ".[sim]"
NEWTON_UNIT_FRICTION_DIRECTION=1 python <your program>
```

## Validated: Coulomb's friction in XPBD's restitution pass

**Validated** by the second registered study ([Study 2](studies/02-xpbd-restitution-friction.md), 9 of 9 rules). The
file: [`patches/xpbd_restitution_friction_v2.diff`](../patches/xpbd_restitution_friction_v2.diff) (sha256
a572b966c46067e1...), against Newton v1.6.1 at the commit in [`UPSTREAM_COMMIT`](../UPSTREAM_COMMIT). Switch:
`NEWTON_XPBD_RESTITUTION_FRICTION=2`, read once when the solver is made, with XPBD's own `enable_restitution=True`.

### What it corrects

XPBD with a restitution of 0 bounces 4% to 12% of a drop: the push that undoes the penetration leaves as an upward
speed (runs 001, 007, 015). Its own option, `enable_restitution`, removes the bounce with a velocity pass, but that
pass applies normal impulses only, while XPBD bounds friction by the position pass's own normal correction: at an
impact the friction falls to 4% to 43% of Coulomb's ([run 015](../validation/run_015_xpbd_restitution/README.md)).

### What it changes

A new module, `xpbd/restitution_friction_kernels.py`, holds a copy of the restitution pass with a friction row after
each contact's normal row: a tangential impulse opposing the contact's slip, no larger than mu times the normal
impulse the pass has applied there, and no larger than what stops the slip (the velocity-level friction of Mueller et
al. 2020, section 3.6). Where the pass pulls a contact's separation back and the contact still slips, the position
pass gave friction at its bound, mu times a normal impulse the pass has made smaller: that much friction is taken
back, along the slip. The solver launches the copy in place of the stock pass only when the switch is set; one line
of Newton's code changes, so that the stock launch names a kernel variable.

### How it got here

| Form | Run | Result |
|---|---|---|
| First (`=1`, [`in_design/xpbd_restitution_friction.diff`](../patches/in_design/xpbd_restitution_friction.diff)): friction on the positive normal impulse only | [016](../validation/run_016_restitution_friction/README.md) | Four of the five checks; failed the second: friction over an impact up to 24% above Coulomb's |
| Second (`=2`, the validated file; the first form stays in it, selected by `=1`): friction also taken back | [018](../validation/run_018_restitution_friction_take_back/README.md) | All five checks; the suite 8 of 10, XPBD as released 6 |
| Second, on fresh numbers | [019, Study 2](../validation/run_019_study_02/README.md) | 9 of 9 rules |

### What it was held to

| Check | Result |
|---|---|
| Required | As released, XPBD rebounds 850 and 1,067 per 10,000 of a drop; with `enable_restitution`, friction at an impact is 300 and 1,980 per 10,000 for Coulomb's 3,500 (Study 2, R2) |
| Correct | On: no rebound; friction at the impact and over the 0.1 s after it 3,499 per 10,000 at both steps (R3 to R5); on the suite, Coulomb's to 2 parts in 10,000 at every step from 10 ms to 0.156 ms (run 018) |
| Nothing else gets worse | On: the slide, the rest and the push byte-identical to `enable_restitution` alone (R6); on the suite every other test reads as without the patch (run 018) |
| Safe when off | 20 of 20 files in Study 2, 117 of 117 in run 018; with the switch on and the restitution pass not run, 10 of 10 (R7) |
| The solver keeps converging | No play's state stopped being a number (R8) |

### What it does not do

It does not touch XPBD's creep at rest (F4): on the suite XPBD with the patch fails the hold and the slip, as it does
as released. The cube's largest turn in an oblique impact is reported, not judged: 0 to 10 mrad with the patch from
2.5 ms down, against 0.35 to 0.64 rad as released.

### Using it

```
git clone --branch v1.6.1 https://github.com/newton-physics/newton.git && cd newton
git apply <this repository>/patches/xpbd_restitution_friction_v2.diff
pip install -e ".[sim]"
NEWTON_XPBD_RESTITUTION_FRICTION=2 python <your program>   # with SolverXPBD(model, enable_restitution=True)
```

## Validated within its range: SemiImplicit's and Featherstone's normal contact

**Validated** by the third registered study ([Study 3](studies/03-normal-contact.md), 9 of 9 rules), within the range
where Newton's explicit integration can carry it: 4 kd h / m at most 1 for the normal (h at most 7.5 ms on a 3 kg cube on
four corners), 10 kf h / m at most 1 for a held load. The file: [`patches/contact_damping_no_pull.diff`](../patches/contact_damping_no_pull.diff)
(sha256 15d7489e80b018ab..., the copy under `in_design/` the registration names), against Newton v1.6.1 with
`unit_friction_direction.diff` applied. Switches: `NEWTON_UNIT_FRICTION_DIRECTION=1` and `NEWTON_CONTACT_DAMPING_NO_PULL=1`.
On fresh scenes it removes the rebound at every ruled step (184 and 285 per 10,000 at 0.75 and 0.375 ms with Study 1's
patch alone; 0 with both), leaves Coulomb's slide, the weight at rest, the lift and the steady hold as they are, and
is safe when off on 32 of 32 files. Above the damper's limit the cube is thrown in its first contact step, before the
patch acts, as released ([run 033](../validation/run_033_study_03/README.md)). How it got here:

SemiImplicit's and Featherstone's normal contact damps only while it closes, so a body dropped with a restitution of 0
rebounds, more as the step shrinks (F11, [run 017](../validation/run_017_refinement_chain_trace/README.md)).
[`patches/in_design/contact_damping_no_pull.diff`](../patches/in_design/contact_damping_no_pull.diff), applied on top of
the unit friction direction (switch `NEWTON_CONTACT_DAMPING_NO_PULL=1`, read once), makes the normal force the
spring-dashpot in both phases kept from pulling, `min(ke d + kd vn, 0)`, with Newton's own `ke` and `kd` (Schwager and
Poeschel 2007). In [run 020](../validation/run_020_contact_damping_no_pull/README.md) it removed the rebound at every
step from 5 ms down, and with the unit friction direction the refinement chain (T08) passes and both solvers pass 7 of
the 10 tests. It failed the second check at 10 ms, where the drop is the release's byte for byte (the instability of
F6, which the patch does not reach), and the third: alone, with the stock friction, it makes Featherstone's refinement
chain and the hold worse; with the unit friction direction, the hold at 0.625 ms creeps 2% faster.
[Run 021](../validation/run_021_explicit_limits/README.md) traced both failures to Newton's explicit integration, not
the contact law: with the patch no dropped cube rebounds wherever 4 kd h / m <= 1, a 4 kg cube at 10 ms included (as
released it rebounds 218 per 10,000 there), while at 4 kd h / m = 2 the damper itself turns the cube round in its
first contact step, before the patch acts; and at a step where explicit friction settles (0.15625 ms) every hold creeps
at the viscous answer, the patch changing nothing. No new version of the patch follows; Study 3 was registered with its
rules inside those limits and the steps outside them played and reported.

## Validated: VBD's velocity carried, not read back from 32-bit positions

**Validated** by the fourth registered study ([Study 4](studies/04-vbd-carried-velocity.md), 5 of 5 rules), its second form:
[`patches/vbd_carried_velocity_v2.diff`](../patches/vbd_carried_velocity_v2.diff) (sha256 4e33692e4797541f...), switch
`NEWTON_VBD_CARRIED_VELOCITY=2`. On fresh scenes VBD and VBD-ALM fall exactly as SemiImplicit does (as released, 21%
fast or not at all), every test passing as released still passes and the lift's phantom ground pull goes, and it is
safe when off on 24 of 24 files. Ruled against the right answer: readings VBD gets wrong for another cause, not
traced, may move and were reported; on the jointed chain at 0.05 ms they move furthest, VBD gaining 45% of the energy in
2 s with the patch ([run 034](../validation/run_034_study_04/README.md)). That chain error is traced since to the 32-bit
poses inside VBD's solve, not this patch: at its largest the chain departs by about half its energy with or without it
(runs [045](../validation/run_045_vbd_chain_float32/README.md) and
[047](../validation/run_047_vbd_chain_spacing/README.md)). How it got here:

VBD reads a body's velocity back from its 32-bit positions after its solve, `(x - x_prev) / dt`, a whole number of
their spacing per step, so bodies stop falling or fall at the wrong rate (F2;
[run 022](../validation/run_022_vbd_carried_velocity/README.md)).
[`patches/in_design/vbd_carried_velocity.diff`](../patches/in_design/vbd_carried_velocity.diff) (switch
`NEWTON_VBD_CARRIED_VELOCITY=1`, read once) launches a copy of that kernel whose linear velocity is the forward step's
plus the solve's correction, `v_forward + (x - x_inertia) / dt`: the same quantity without the cancellation. In run 022
it makes VBD fall as SemiImplicit and XPBD do, byte for byte, is safe when off on the suite, run 006's falls and run
014's chains, and makes VBD-ALM's ten-test suite readable for the first time (5 of 10, the ground no longer pulling).
It is not correct by the checks: on VBD two suite lines read slightly worse, and on the two-link chain
([run 025](../validation/run_025_vbd_chain_carried_velocity/README.md)) it leaves VBD's excess loss at small steps and
makes some readings worse. Its second form,
[`patches/in_design/vbd_carried_velocity_v2.diff`](../patches/in_design/vbd_carried_velocity_v2.diff) (switch value
`2`), carries the angular velocity too. In [run 026](../validation/run_026_vbd_carried_velocity_v2/README.md) it falls as the first form does and is safe when off, but it leaves the chain's excess loss in place and moves chain readings both ways, several against their answers: the angular read-back was not the reason. Ruled against the released readings both forms failed; Study 4 ruled the second against the right answer.

## In design, not validated: XPBD's joint angle tracked continuously past pi

XPBD throws a joint that turns past pi inside limits it never reaches: its joint solve compares the limits with an angle
in [-pi, pi] (F13, [run 032](../validation/run_032_joint_limit_past_pi/README.md)).
[`patches/in_design/xpbd_joint_angle_unwrap.diff`](../patches/in_design/xpbd_joint_angle_unwrap.diff) (switch
`NEWTON_XPBD_JOINT_ANGLE_UNWRAP=1`, read once) launches a copy of the joint kernel that keeps each revolute joint's
last angle, unwrapped, and adds to the measured angle the whole turns that bring it nearest the last. In
[run 035](../validation/run_035_xpbd_joint_angle_unwrap/README.md) a joint inside its limits played past pi as with no
limits, byte for byte; one reaching a limit beyond pi was held at it; every play with no joint past pi, the chains and
the ten-test suite, was the release's byte for byte; with the switch unset, the release. In [Study 5](studies/05-xpbd-joint-angle.md) (run 037) 6 of its 8 rule lines held: R4, a limit reached past pi holding the arm, failed, as XPBD's limit returns an arm before pi too, unpatched (F14). It stays in design.

Its second form, [`patches/in_design/xpbd_joint_angle_v2.diff`](../patches/in_design/xpbd_joint_angle_v2.diff)
(sha256 b969131ba1f65879...; switch value `2`, the first form at `1`), adds the swing's exact gradient: XPBD's swing
part gives the angle exactly but scales its gradient by theta / sin(theta / 2) alone, so along the axis the gradient is
(theta / 2) cot(theta / 2) of the true one and the limit's gain has no bound toward pi (run 048); the second form takes
de/dv = f I + (2 / w - f) a a^T. In [run 050](../validation/run_050_xpbd_swing_gradient/README.md) every limit from
2.7 to 4.5 rad, at relaxations 0.4 and 0.2, turned the arm back once, where as released they chatter from 2.9 rad and
throw at 3.05; with the switch unset or at 1 it plays as before, byte for byte, and inside the limits switches 1 and 2
are the same. It does not end F14's return, which run 050 traced to the limit's coupling to the joint's anchor; the
depth past a limit still varies with the angle (up to 14%), read in the source as the anchor constraint sized along the
world's axes. It stays in design.

Its third form, [`patches/in_design/xpbd_joint_angle_v3.diff`](../patches/in_design/xpbd_joint_angle_v3.diff)
(sha256 c89335b616f1b628...; switch value `3`), also sizes a revolute joint's limit with the joint's anchor held. XPBD
sizes each of a joint's constraints alone and sums the corrections, so the limit's correction rotates a body about its
own centre and the anchor's correction turns most of it back (run 050). The third form takes the limit's effective
inverse mass with the anchor's three rows eliminated, the Schur complement w = J M^-1 J^T - b^T K^-1 b, and applies its
correction along M^-1 (J^T - G^T K^-1 b), which leaves the anchor in place to first order: for one body on a fixed
joint, a rotation about the joint by the body's inertia there (the parallel-axis theorem). Only a revolute joint's own
axis while it is past a limit changes. In [run 051](../validation/run_051_xpbd_limit_anchor_held/README.md) the arm on
a 0.3 m lever turned back at about 0.5 rad/s instead of 2.5 and went as deep as an arm with no lever; with
`joint_angular_relaxation` 1 the limit held the arm at every lever and every limit from 2.5 to 4.5 rad, past pi too, in
21 of 22 plays (the arm on its lever is thrown at relaxation 1 with the second form); with the switch unset, at 1 or at 2 it
plays as before, byte for byte. At the default relaxation, 0.4, the limit's own projection still lets the arm go at a
sixth of its speed, and the held arms drift back slowly at the coarse step. It stays in design.

Its fourth form, [`patches/in_design/xpbd_joint_angle_v4_on_1.7.0.diff`](../patches/in_design/xpbd_joint_angle_v4_on_1.7.0.diff)
(sha256 348c5ac677f9a64f..., on Newton 1.7.0; switch value `4`), is the third form with the coupled limit's correction
applied in full, every other row's relaxation left as it is. In [run 061](../validation/run_061_xpbd_limit_full/README.md)
it held one arm at XPBD's default relaxation at every lever and every limit, past pi too, in 28 of 28 plays, and was the
third form byte for byte at a relaxation of 1; a chain of two links is not held (its first joint turned back at 3.63
rad/s): holding a chain needs the limit sized with the inertia of everything it turns, the subtree past the joint,
which XPBD's per-joint projection does not have. It stays in design; that form is a study of its own.

## Validated: the MuJoCo solver's joint limit with the stiffness and damping it is given

Newton pre-scales a joint limit's `limit_ke` and `limit_kd` for MuJoCo by `dof_invweight0 * (1 - dmax)`, but MuJoCo's
soft limit already holds with d^2 k / invweight, so the limit keeps only (1 - dmax) of each: 0.05 by default (F15,
[runs 036](../validation/run_036_limit_damping_inertia/README.md) and
[039](../validation/run_039_mujoco_limit_force_space/README.md)).
[`patches/mujoco_limit_force_space.diff`](../patches/mujoco_limit_force_space.diff) (switch
`NEWTON_MUJOCO_LIMIT_FORCE_SPACE=1`, read once) pre-scales by `dof_invweight0` alone. In run 039 the limit's stiffness
became Newton's at every mass, the suite and the chains were unchanged and it was safe when off; but the light arms turned back higher than on
Featherstone. Run 042 showed why: MuJoCo's limit cannot pull and Featherstone's does (F16); the patched limit is the no-tension
spring-dashpot's to 0.011 rad. Validated by the sixth registered study ([Study 6](studies/06-mujoco-limit.md), 9 of 9 rules; [run 043](../validation/run_043_study_06/README.md)): on a fresh arm the patched limit sends it back within 0.022 rad of the spring and damper kept from pulling, where as released it turns three to four times higher; a joint with no limit unchanged; safe when off. The file: [`patches/mujoco_limit_force_space.diff`](../patches/mujoco_limit_force_space.diff).

## On Newton 1.7.0

Each patch family in its latest form, rebased onto Newton 1.7.0 as released, is in
[`patches/newton-1.7.0/`](../patches/newton-1.7.0/README.md), with what each rebase changed (1.7.0 moved the body contact
kernel's work into a function, `_eval_body_contact`; the rest apply as they are). Their switches and values are the
1.6.1 patches' own; [Study 7](studies/07-newton-1.7.0.md) played the record on 1.7.0 with them.

## Validated: Newton's own options

Some issues need no patch: one of Newton's own solver options removes them. Each below was held to rules registered
before its plays, on scenes and steps no probe used, on Newton 1.7.0 as released
([Study 9](studies/09-newtons-own-options.md), 14 of 14 rule lines; [run 064](../validation/run_064_study_09/README.md)).

| Issue | Solver | Set | What it gives |
|---|---|---|---|
| 14, no frictionless contact | The MuJoCo solver | `cone="elliptic"` | A contact of friction 0, 0.0001 or 0.001 plays, the ground carrying the weight to 0.2%; the default pyramidal cone stops being a number at the first contact |
| 10, a joint chain blows up | SemiImplicit | `joint_attach_kd=0` | The chain plays at 1, 0.5 and 0.25 ms, keeping 99.87% of its kinetic energy; its joint damper is past its explicit limit |
| 11, a joint chain gains energy | The MuJoCo solver | `integrator="rk4"` | The energy and angular momentum within 5 ppm at every step from 8 to 0.125 ms |
| 13, a spinning body's centre moves | The MuJoCo solver | `integrator="rk4"` | The centre held within 19 um/s, where as released it moves at 1.1 mm/s at 8 ms |
| 9, its normal part | SemiImplicit, Featherstone | a step at most m / (4 kd), with the normal contact above | A small frictionless cube does not rebound; at four times the bound it is thrown |

## Validated: XPBD's speed floor removed

After every correction XPBD sets a body's speed to zero when it is under 1e-4 m/s, and its turning speed when under
1e-4 rad/s (`apply_body_deltas`, "this improves gradient stability"): a body moving or turning slower is held still,
and a force too small to give that speed in one step never moves a body at all (F17).
[`patches/newton-1.7.0/xpbd_no_speed_floor.diff`](../patches/newton-1.7.0/xpbd_no_speed_floor.diff) (sha256
b15fcf20d1cd5e09..., against Newton 1.7.0; switch `NEWTON_XPBD_NO_SPEED_FLOOR=1`, read once when the solver is made)
adds a copy of `apply_body_deltas` without those lines, launched in its place; every other line is the stock kernel's.
In design in [run 065](../validation/run_065_xpbd_floor_relaxation_drive/README.md) (32 of 32 predictions); validated
by the tenth registered study ([Study 10](studies/10-xpbd-joints-floor.md), R1 to R5): slow bodies, slow turns and
small forces kept, safe when off, the contact suite's verdicts unchanged. A form for pull request #4318's tree, its
`import os` placed in #4318's import block:
[`in_design/xpbd_no_speed_floor_on_pr4318.diff`](../patches/in_design/xpbd_no_speed_floor_on_pr4318.diff).

## Validated: fixes proposed upstream

| Issue | Fix | Validated |
|---|---|---|
| 7, a joint past pi inside its limits thrown | Pull request #4318 (its form of #4316) on XPBD; Newton 1.7.0's #4470 on VBD | [Study 10](studies/10-xpbd-joints-floor.md), R11 to R13 |
| 25, a joint torque 1.75 times too strong | Pull request #4317, with the speed-floor patch where a step's speed gain is under the floor | Study 10, R6, R7 |
| 26, the drive by its iteration count | Pull request #4318's `joint_drive_mode="pd"` | Study 10, R8 to R10 |

The diffs, as played: [`patches/upstream/`](../patches/upstream/) (#4318 rebased onto 1.7.0, one hunk moved).

## Validated: MuJoCo's noslip through Newton, on the CPU path

MuJoCo recommends the elliptic cone with its noslip solver for contacts that must hold; Newton passes no noslip to the
MuJoCo solver (F7), and MuJoCo Warp 3.15 refuses it ("noslip solver not implemented"), so it can only reach MuJoCo's C
engine, the solver's CPU path (`use_mujoco_cpu=True`), which plays the record's scenes as the Warp path does (run 066).
[`patches/newton-1.7.0/mujoco_noslip.diff`](../patches/newton-1.7.0/mujoco_noslip.diff) gives `SolverMuJoCo` the
keyword arguments `noslip_iterations` and `noslip_tolerance`: on the CPU path they are set on the compiled MuJoCo model
the C engine steps, after MuJoCo Warp's model is made from it (Newton makes that model on both paths); on the Warp path
they are set on the spec, so MuJoCo Warp refuses them with its own message. Its first form set them on the spec on both
paths and never reached the C engine ([run 067](../validation/run_067_mujoco_noslip/README.md)). Validated by the
eleventh registered study ([Study 11](studies/11-mujoco-noslip-cpu-featherstone-limit.md), R1 to R5): with the elliptic
cone and 5 noslip iterations a cube pushed at 0.7 of what friction holds does not move, where without noslip it creeps
1,241 um/s; a slide and the weight kept; nothing set when unset. With the pyramidal cone noslip does not hold it
([run 069](../validation/run_069_mujoco_noslip_v2/README.md)).

## Validated: Featherstone's joint limit kept from pulling

Newton's joint limit applies its damper until the angle is back at the limit, so it pulls the joint back as it leaves
(F16). [`patches/newton-1.7.0/featherstone_limit.diff`](../patches/newton-1.7.0/featherstone_limit.diff), switch
`NEWTON_FEATHERSTONE_LIMIT=1` (read once when the solver is made): the stock joint forces are given the limit's
stiffness and damping as zero (their drive still off past a limit), and a new kernel adds the same spring and damper,
never pulling, to the joint forces. Validated by Study 11 (R10 to R12): a strike turns back within 0.007 rad of the
no-tension spring-dashpot's closed form, where as released the limit pulls it 0.02 to 0.06 rad lower; safe when off.
The same file holds two forms in design: `=2`, the limit integrated linearly implicitly (backward Euler, h kd + h^2 ke
on the joint's diagonal of the joint-space inertia), which never stops being a number at any step from 1/240 s to 2 us
on a light link that diverges as released (issue 28, [run 068](../validation/run_068_featherstone_limit/README.md)); and
`=3`, its limit kept only where the implicit force pushes, which also brings the link to rest on its limit, its first
strike still rebounding at large steps ([run 070](../validation/run_070_featherstone_limit_v3/README.md)). SemiImplicit's
limit is not changed.

## Validated: Featherstone's joint limit integrated implicitly

The same file, [`patches/newton-1.7.0/featherstone_limit.diff`](../patches/newton-1.7.0/featherstone_limit.diff), switch
`NEWTON_FEATHERSTONE_LIMIT=3` (with Featherstone's default `use_tile_gemm=False`): Newton's limit, explicit and stable
only under microseconds on light links (F20, run 055), integrated linearly implicitly, backward Euler for its spring
and damper, h kd + h^2 ke added to the joint's diagonal of the joint-space inertia before its Cholesky factorization
(Baraff and Witkin 1998), the limit kept only where the force the implicit step applies pushes, estimated from the
joint's own row of the inertia built for the step. Validated by the twelfth registered study
([Study 12](studies/12-semi-angle-featherstone-implicit-limit.md), R6 to R9): a light arm and a serial arm resting on a
limit, which as released stop being a number at every step from 1/240 s to 50 us, stay numbers and rest on the limit
within 2 urad at every step. At large steps the first strike rebounds before the arm settles (run 070): the limit acts
only from the step after the joint passes it.

## Validated: SemiImplicit's joint angle

[`patches/newton-1.7.0/semi_joint.diff`](../patches/newton-1.7.0/semi_joint.diff) (sha256 e18cc103222a1fec...), switch
`NEWTON_SEMI_JOINT_ANGLE=1` (read once, when the module is imported, which the solver does only when a switch is set): a
copy of `eval_body_joints` in which a single rotational DOF's angle, read by `wp.quat_twist_angle_signed` in [-2 pi, 2
pi] on the quaternion's branch, is measured within pi of a reference, the middle of its limit range or, for a range 2 pi
wide or wider, its drive's target (pull request #4316's rule, which Newton proposes for XPBD), and a D6's relative
rotation is read in the basis of its own axes before it is decomposed (`quat_decompose`'s angles are about the joint
frame's X, Y and Z, whatever the joint's axes). Validated by the thirteenth registered study
([Study 13](studies/13-semi-joint-angle.md), 16 of 16; and Study 12's R1, R3, R5): a drive held past a full turn either
way and the two-axis D6 of the reports held exactly, safe when off. Its other switch, `NEWTON_SEMI_JOINT_LIMIT=1` (the
limit kept from pulling), is in design: on SemiImplicit a strike is governed by its joint attachment (runs 077, 079).

## Validated: XPBD's friction bounded on the step's totals

Each iteration XPBD bounds a contact's friction correction by mu times that iteration's normal correction; at rest the
normal corrections of a step add up only to its sink and shrink from iteration to iteration, so a load inside the
friction limit is not held, at any iteration count (runs 044, 085). [`patches/newton-1.7.0/xpbd_friction_total.diff`](../patches/newton-1.7.0/xpbd_friction_total.diff)
(on 1.7.0 with the speed-floor patch; switch `NEWTON_XPBD_FRICTION_TOTAL=1`, read once when the solver is made) adds a
copy of the contact solve in which the step's friction at a contact, summed over its iterations, is kept within mu
times the normal correction summed over the same iterations (the accumulated-impulse clamp, Catto 2005), two sums a
contact zeroed each step. Validated by the fifteenth registered study ([Study 15](studies/15-xpbd-holds.md), 6 of 6),
with the speed floor removed and 64 iterations: a cube pushed at 0.7 of what friction holds within 4 um/s, where as
released it creeps 3,415 and 854 um/s; a slide unchanged; no suite verdict lost. At XPBD's default 2 iterations the
solve is left unconverged and the patch changes nothing (run 082): XPBD's hold needs both.

## Validated: Featherstone's step as the classic Runge-Kutta scheme

Featherstone integrates its joints by semi-implicit Euler; its joint-space inertia depends on the configuration, so
the scheme is not symplectic and a chain with nothing acting on it gains energy in proportion to the step (F8, issue
11). [`patches/newton-1.7.0/featherstone_rk4.diff`](../patches/newton-1.7.0/featherstone_rk4.diff) (on 1.7.0; switch
`NEWTON_FEATHERSTONE_RK4=1`, read once when the solver is made) makes the step in four stages as MuJoCo makes its RK4
(`mj_RungeKutta`): each stage's joint accelerations are the stock step's own, evaluated on a scratch state at the stage's
coordinates and speeds; a stage's coordinates are the step's start moved along a weighted sum of the stages' speeds
by Featherstone's own joint integration with no acceleration, its speeds the start's plus the weighted accelerations;
the step ends at the start moved along the stages' speeds weighted 1/6, 1/3, 1/3 and 1/6. It applies to steps with no
gradients, observables, particles, kinematic joints, joint mimics or free joints below another joint; any other step
is the stock one. Validated by the sixteenth registered study ([Study 16](studies/16-featherstone-rk4.md), 9 of 9): a
free chain's energy within 7 ppm and its angular momentum within 2 ppm at every step from 6 to 0.25 ms, where as
released it gains up to 1%; a chain swinging under gravity within 20 ppm at 5 ms and 7 ppm at 0.5 ms, where as
released it departs up to 5.9%; no suite verdict lost but the two that ask for a first-order scheme's convergence, each
of their gaps below the release's.

## Validated: SemiImplicit's and Featherstone's friction as Coulomb's law at the step's end

SemiImplicit's contact friction, which Featherstone's contact pass shares, is a force integrated explicitly: below mu N
/ kf it is viscous, so a load inside the friction limit creeps (F4, issue 6), and its kf settles only for steps under
about 1.25 m / (10 kf), so a small cube at a 2 ms step is past it (F6, issue 9).
[`patches/newton-1.7.0/semi_coulomb_friction.diff`](../patches/newton-1.7.0/semi_coulomb_friction.diff) (on 1.7.0 with
the unit friction direction and contact damping patches) takes the friction out of SemiImplicit's force pass (a copy of
the stock function with its friction line left out and each contact recorded, honouring the damping patch's switch)
and, after the step's integration, gives each contact the tangential impulse that stops its slip, shared among its
body's contacts, the pass made K times a step (`NEWTON_SEMI_COULOMB_FRICTION=1`,
`NEWTON_SEMI_COULOMB_FRICTION_ITERATIONS=K`, each sweep from the velocities the one before left), each contact's
friction over the step kept within mu times the normal impulse the force pass applied there, on its total
(accumulated impulses, Catto 2005); the pose follows the velocity's change over the step.
[`patches/newton-1.7.0/featherstone_coulomb_friction.diff`](../patches/newton-1.7.0/featherstone_coulomb_friction.diff)
(on the same, with the SemiImplicit patch) makes the same pass for Featherstone (`NEWTON_FEATHERSTONE_COULOMB_FRICTION=K`):
a body's impulses reach its joints as its forces do in `eval_rigid_tau`, and the joints' change of speed solves the
joint-space inertia built, with Featherstone's own kernels, where the step leaves the joints. Validated by the
eighteenth registered study ([Study 18](studies/18-semi-featherstone-coulomb-friction.md), 19 of 19) at 64 sweeps with
the damping patch on: a cube pushed at 0.7 of what friction holds still at every step, issue 9's small cube held at its
2 ms step where as released it is thrown, a slide within 0.45% of Coulomb's distance at every step, no suite verdict
lost. On Featherstone the friction at impact is within 1 in 100 of Coulomb's from 2.5 ms down and 5% short at 5 ms:
its own first-order integration of a spinning body (runs 097, 099).

## Validated: XPBD's joint limit, holding an arm and stopping a chain as a hard limit does

XPBD's joint limit throws an arm back off it (F14, issue 8): its correction is sized with the arm's inertia about its
own centre and the anchor constraint, sized apart from it, turns most of it back into the arm's turn, and its gain
grows without bound toward pi. [`patches/newton-1.7.0/xpbd_joint_angle_v4.diff`](../patches/newton-1.7.0/xpbd_joint_angle_v4.diff)
(on 1.7.0; switch `NEWTON_XPBD_JOINT_ANGLE_UNWRAP=4`, read once when the solver is made) launches a copy of XPBD's joint
solve that reads a revolute joint's angle continuously past pi (the first form), gives the swing its exact gradient
(the second), sizes the limit's correction with the joint's anchor held, the anchor's rows eliminated by a Schur
complement (the third), and applies that coupled correction in full (the fourth). Validated by the twentieth
registered study ([Study 20](studies/20-xpbd-limit-arm-chain.md), 13 of 13) at 64 iterations, XPBD's relaxations its
defaults: two arms struck against their limits held within 2 mrad, where as released they are thrown back at up to 77%
of their speed and at 64 iterations without the patch still at 0.7 rad/s; and a chain's first joint stopped dead on
its limit and let go as a hard limit lets it go, the second link having turned half a turn, nearer MuJoCo's own engine
with an ever stiffer limit as the step shrinks. The 64 iterations are a configuration XPBD's solve needs to converge on
the chain; at its default two the limit rattles (run 105).

## Validated: every solver names the joint features it does not apply

Newton 1.7.0's solvers document, each in its class docstring, joint features they do not support (effort and velocity
limits, joint friction, armature, `joint_enabled`), and Featherstone plays a tree, leaving a loop-closing joint out,
but nothing is said when a model that sets one is played (F21, F23, issue 19).
[`patches/newton-1.7.0/joint_feature_warnings.diff`](../patches/newton-1.7.0/joint_feature_warnings.diff) (on 1.7.0 with
pull request #3552 rebased onto it, [`upstream/pr_3552_on_1.7.0.diff`](../patches/upstream/pr_3552_on_1.7.0.diff);
switch `NEWTON_WARN_IGNORED_JOINT_FEATURES=1`, read once) adds a module every solver calls when made, with the features
its own documentation lists: it warns once, naming each one the model sets away from Newton's default and the joints
that set it, a loop-closing joint being one kept out of every articulation whose child is another joint's child.
Nothing a solver does changes. With #3552's warning for the MuJoCo solver's loop-closing joints, validated by the
twenty-first registered study ([Study 21](studies/21-joint-features-said.md), 7 of 7): every ignored feature named, on
all five solvers, nothing said where nothing is ignored, every play byte for byte the release's. SemiImplicit's loop,
which as released stops being a number, plays with Newton's own `joint_attach_kd=0` and applies the loop joint's drive.

## Validated: VBD's rigid solve in displacement form

VBD adds each iteration's increment onto a body's absolute 32-bit pose and reads the step's velocity back from the
poses, so the rounding of each write becomes a velocity error of the rounding over the step, growing as the step
shrinks: a spinning body's centre drifts (F12, issue 13), a slide loses its friction (F2), a free chain loses its
energy (F9, issue 12). Pull request #4721 proposes, for VBD's sparse path, keeping each body's displacement from its
inertial target apart from its pose. [`patches/newton-1.7.0/vbd_displacement.diff`](../patches/newton-1.7.0/vbd_displacement.diff)
(switch `NEWTON_VBD_DISPLACEMENT=1`, read once) makes that change in 1.7.0's rigid solve: a copy of the solve kernel
whose inertial term and pose update work on the displacement, a turn kept with it as a quaternion, zeroed each step;
the pose the inertial target where there is no displacement; and the velocity the forward step's plus the
displacement over the step. Off with joint mimics or DAT truncation, as the pull request's own limitation. Validated
for issue 13 by the twenty-third registered study ([Study 23](studies/23-vbd-displacement-spin-contacts.md), 7 of 7):
the spinning body's centre still at every step on VBD and VBD-ALM, slides settling as the step shrinks, the hold kept,
every play byte for byte the release's with the switch unset. For issue 12 the twenty-second
([Study 22](studies/22-vbd-displacement.md), 12 of 14) did not validate it: the chain's loss falls with the step at the
origin, but away from it the joints' 32-bit evaluation leaves a floor at the smallest steps.

## In design, not validated: VBD's proxy coupling for a light deformable (#4698)

[`patches/in_design/vbd_proxy_coupling_v2_on_1.7.0.diff`](../patches/in_design/vbd_proxy_coupling_v2_on_1.7.0.diff)
(switch `NEWTON_VBD_PROXY_COUPLING`): at 1, a proxy body rewound by its gravity only, as VBD's explicit harvest
overwrites the lagged feedback (#4698's B); at 2, also the harvest as the deformable received it, each deformable's
unbalanced force at the final iterate taken off its contacts, summed over the coupled step's substeps (#4698's A).
Probed in runs 116 and 118 (issue 21).

## Validated: a deformable's feedback to a coupled body as the deformable received it (#4698)

A light VBD cloth coupled to a rigid body through `SolverCoupledProxy` hands the body the contact penalty of VBD's
last iterate, 19 to 168 times the force the cloth exerts (runs 112 and 119), and the generic rewind takes off a feedback VBD's
explicit harvest does not add back (#4698). [`patches/newton-1.7.0/vbd_proxy_coupling.diff`](../patches/newton-1.7.0/vbd_proxy_coupling.diff)
(switch `NEWTON_VBD_PROXY_COUPLING`, read once): at 1, SolverVBD rewinds a proxy body by its gravity only when it
integrates it; at 2, also, after each step's iterations, one more pass of the particle iteration writes each particle's
unbalanced force at the final iterate, summed over its deformable (the particles its triangles, bending edges,
tetrahedra and springs join), and takes it off the deformable's contacts, each in the share its force along that
unbalance has of all of theirs, or alike among its contact candidates where none lies along it; every soft contact the
particles felt is walked, the wrench summed over the coupled step's substeps and harvested as their mean; a deformable
that pins hold keeps the explicit force. Validated by the twenty-fourth registered study
([Study 24](studies/24-cloth-box-coupling.md), 14 of 14): the feedback the cloth's force exactly, a box under a cloth
at rest, a throw's momentum kept to 1 in 430, a held cloth carrying a box at its weight, every play byte for byte the
release's with the switch unset.

## Validated: MuJoCo's noslip solver on MuJoCo Warp

MuJoCo Warp 3.15 refuses MuJoCo's `noslip_iterations` above 0 ("noslip solver not implemented"), so MuJoCo's
recommended configuration for a load held by friction cannot be set on the MuJoCo solver's Warp path (F7, issue 15).
[`patches/mujoco-warp-3.15.0/noslip.diff`](../patches/mujoco-warp-3.15.0/noslip.diff) ports MuJoCo's noslip solver
(`solNoSlip` and its helpers, `mju_QCQP2`, `mju_QCQP3`, `mju_QCQP`) into MuJoCo Warp as a module run after the main
solve, per world: a projected Gauss-Seidel over the forces in friction dimensions on J M^-1 J' without the
regularization, the residual J qacc - aref, M^-1 J' from MuJoCo Warp's own mass solve; then MuJoCo's finish and M qacc
for the implicit integrators. MuJoCo's option fields are carried into MuJoCo Warp's; with MuJoCo's default 0 nothing of
it runs. With the record's Newton noslip patch, validated by the twenty-fifth registered study
([Study 25](studies/25-mujoco-warp-noslip.md), 14 of 14): the Warp path holds a cube still, and its hold, slide and
weight are MuJoCo's C engine's.

## Validated: two shapes' frictions combined by one rule on every solver

Two shapes in contact each carry a friction coefficient; as released XPBD, SemiImplicit and Featherstone combine them by
their mean, VBD by their geometric mean, and the MuJoCo solver by MuJoCo's rule, the larger or the higher-priority
geom's (run 059, issue 18), which it cannot leave. [`patches/newton-1.7.0/friction_combine.diff`](../patches/newton-1.7.0/friction_combine.diff)
(switch `NEWTON_FRICTION_COMBINE=1`, read once) adds one rule (`solvers/friction_combine.py`) that SemiImplicit's and
Featherstone's contact, XPBD's and VBD's two body-body material kernels take for body contacts: the larger coefficient
(sliding, torsional and rolling each), or the higher-priority shape's when the model carries MuJoCo's geom priority
and the two differ, the priority array passed to each kernel. Validated by the twenty-sixth registered study
([Study 26](studies/26-friction-combination.md), 44 of 44): every solver's mixed slide byte for byte its own slide at
the rule's coefficient, in two pairings and four priorities, every play byte for byte the release's with the switch
unset.

## Validated: a static friction coefficient applied, and XPBD's slip seen whole

As released a shape carries one friction coefficient, so nothing sticks before it slides, and a USD material's
`staticFriction` is dropped on import (issue 18). Pull request #4306, open upstream
([`../patches/upstream/pr_4306_on_1.7.0.diff`](../patches/upstream/pr_4306_on_1.7.0.diff)), adds the coefficient to the
data model and the importer, which no solver reads.
[`patches/newton-1.7.0/static_friction.diff`](../patches/newton-1.7.0/static_friction.diff) (switch
`NEWTON_STATIC_FRICTION=1`, read once; on the record's friction chains and #4306) applies it by the needed-impulse rule:
the friction a contact needs to stop its slip within the step is applied whole when it is within the static limit (a
pair's static coefficient the mean of each shape's `max(mu_static, mu)`), otherwise the dynamic limit; XPBD on the
step's friction totals, SemiImplicit and Featherstone in the Coulomb pass. The MuJoCo solver (MuJoCo models one
coefficient) and VBD (its friction decides on the solve's iterate, which overestimates what a hold needs; on the host
neither of its paths held by this rule) warn once, naming the shapes. In run 129 (10 of 10) the three held and slid as
Coulomb's law asks; Study 27 (13 of 16) found the import and SemiImplicit and Featherstone right at 1 and 0.25 ms and
XPBD creeping 12 um/s at 0.25 ms, its own floor with or without the patch: its friction measured a step's slip as the
difference of two contact points' 32-bit world positions, blind to a slip under one spacing of those coordinates (3.7
nm at 0.04 m from the origin). [`patches/newton-1.7.0/xpbd_friction_slip.diff`](../patches/newton-1.7.0/xpbd_friction_slip.diff)
(switch `NEWTON_XPBD_FRICTION_SLIP=1`, with the friction on the totals) measures it as the points' separation at the
step's start plus each body's motion over the step, carried per body: the integrator's v dt and w dt and every
iteration's correction in `apply_body_deltas`' own arithmetic, a turn on a lever by Rodrigues' formula. Validated
together by the thirtieth registered study ([Study 30](studies/30-static-friction-xpbd-slip.md), 16 of 16): the
static coefficient imported (24 of 24 models, as released none) and held at 1 and 0.25 ms on the three, imported or
built (XPBD 1 and 7 um/s, the others 0), the dynamic coefficient once sliding or broken away, every play byte for byte
the chain's with both switches unset. Below 0.25 ms another floor of XPBD's remains, not traced (on the host a hold at
0.0625 ms creeps 115 um/s with the slip patch).

## Validated: a fast body kept from passing through a thin slab

As released a body goes through a thin slab wherever one step carries it past it whole (issue 20, run 060), and
Newton's speculative contacts change nothing: its pipeline already writes a falling body's contacts a step ahead within
its contact gap, so run 060's cubes were caught either way. What lets them through is the solve. **On XPBD, by Newton's
own configuration**: at 64 iterations, with speculative contacts for a body further away than the gap, its contact
correction finishes and the cube stops on the slab, where at the default two iterations the next collision finds it past
the slab's middle (Studies 33 to 35, every scene). **On SemiImplicit and Featherstone**, whose penalty contact acts on
no contact still apart, [`patches/newton-1.7.0/speculative_normal.diff`](../patches/newton-1.7.0/speculative_normal.diff)
(switch `NEWTON_SPECULATIVE_NORMAL=1`, read once; on the record's friction chains, with speculative contacts) gives every
contact the force pass finds a normal impulse in the Coulomb pass after the step: one still apart the impulse that keeps
it apart at the step's end (its closing speed cut to d / dt, Catto's speculative contacts), one closed the impulse that
stops its closing, never pulling; each contact's friction cone counts that impulse beside the penalty's; and
Featherstone's pass rebuilds its joint-space inertia where the joints are each sweep. Its forms: the first, on contacts
still apart only, kept the cube but carried a slide's touching start without friction for a step (Study 33, 6 of 8);
the third, on contacts strictly apart, kept the slides but let a cube that lands touching at speed through (Study 34, 7
of 8); the second's friction-counting cone, on Featherstone, sent the cube spinning (the inertia built where the step
left the joints while the impulse moved the cube back 40 cm within the pass). Validated by the thirty-fifth registered
study ([Study 35](studies/35-tunnelling-every-contact.md), 6 of 6): no cube through on the three in any scene, every play
byte for byte the chain's with the switch unset, the slides within 1 in 540 of Coulomb's distance. With the patch a
slide stops dead 0.17% short of Coulomb's distance; a cube a coarse step brings in at speed is still thrown back up by
the penalty's explicit damping, reported. The MuJoCo solver goes through regardless: MuJoCo's contact acts on no contact
still apart.

## Validated: VBD's poses carried in two 32-bit numbers

With the displacement patch a free chain's loss falls with the step at the origin, but away from it VBD's 32-bit poses
are read again where the joints are evaluated and the forward step's target is made, so the loss grows as the step
shrinks once the chain is far out (issue 12; Study 22's R5; 33,900 ppm at 0.025 ms 60 m out against 440 at the origin,
Study 36). [`patches/newton-1.7.0/vbd_pose_carry.diff`](../patches/newton-1.7.0/vbd_pose_carry.diff) (switch
`NEWTON_VBD_POSE_CARRY=1`, read once; on the displacement patch, with `NEWTON_VBD_DISPLACEMENT=1`) carries each body's
centre from step to step as two 32-bit numbers (Fast2Sum), makes the forward step's target and the solve's pose from
them, sees each joint from the child's target centre with the pairs, and hands the joints' starting error shifted
copies of the poses made from them. Validated by the thirty-sixth registered study
([Study 36](studies/36-vbd-pose-carry.md), 15 of 15) on VBD's compliant-ALM path: the chain 15 and 60 m out as at the
origin within 2.2% at every step from 0.4 to 0.025 ms, its loss falling with the step everywhere, every play byte for
byte the displacement patch's with the switch unset, the spinning body, the slide and the hold kept. On VBD's legacy
path it holds 15 m out but not 60 m out at the two smallest steps (reported); with Newton's own
`rigid_avbd_joint_alpha=0` there ([Study 39](studies/39-vbd-legacy-pose-carry-alpha.md), 10 of 15) the far chain's loss
falls with the step at 20 and 50 m, 206 and 159 ppm at 0.025 ms against 9,301 and 7,837 without the carry, but stays
above the origin's 138 by more than the registered tenth at four of five steps.
