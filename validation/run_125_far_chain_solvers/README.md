# Run 125: the free chain far from the origin on the solvers whose state is the bodies' poses (issue 12)

Not registered: a design probe, its predictions pushed with [`play.sh`](play.sh) before any play. Newton 1.7.0 from PyPI
as released.

## Why

With Senua AI's VBD displacement patch, VBD's free chain 10 m from the origin at 0.09375 ms departs from its energy
2.2 to 4.6 times as far as at the origin, at every one of VBD's joint options (runs 114, 121), where Featherstone, whose
state is the joints' angles, plays alike at both places. If the floor is what 32-bit world positions cost any solver
that keeps the bodies' poses, XPBD and SemiImplicit show it too; if they do not, it is VBD's.

## What is played

Study 22's chain (links of 1.0 and 0.8 kg, the joints 0.45 m apart, turning at 1.9 and -0.9 rad/s, no gravity, 2 s) at
the origin and 10 m out, at 0.375 and 0.09375 ms, on XPBD, on SemiImplicit with Newton's own `joint_attach_kd=0` (its
chain's fix, Study 9), and on Featherstone, as released.

## Predictions (pushed before the plays)

| Check | Prediction |
|---|---|
| C0 | Every play a number; Featherstone's four plays Study 22's files byte for byte |
| P1 | Reported per solver: whether 10 m out at 0.09375 ms XPBD and SemiImplicit depart within 1 in 3 of the origin's (a check each, not a prediction either way) |

Reported: every reading.

## What it found

Played 20 October 2026 on the second x86-64 host (`started.txt`, `finished.txt`); the measured lines in `measured.txt`,
the checks in [`checks.txt`](checks.txt). **4 of 4 checks held.**

| The chain's largest departure from its energy, ppm | origin, 0.375 ms | 10 m, 0.375 ms | origin, 0.09375 ms | 10 m, 0.09375 ms |
|---|---|---|---|---|
| XPBD | 12,466 | 10,820 | 7,409 | 8,506 |
| SemiImplicit (`joint_attach_kd=0`) | 4,599 | 4,679 | 4,557 | 4,173 |
| Featherstone | 906 | 892 | 215 | 219 |
| VBD with the displacement patch (run 114) | 6,410 | 5,243 | 952 | 3,281 |

- C0 held (every play a number; Featherstone Study 22's four files byte for byte); P1 held for XPBD (10 m out within
  1 in 6 of the origin) and SemiImplicit (within 1 in 11).
- **VBD's floor 10 m out is VBD's own**: XPBD and SemiImplicit, whose state is the bodies' 32-bit poses as VBD's is,
  play the chain 10 m out as at the origin at the smallest step. XPBD corrects a joint in full within the step but takes
  its velocity from the poses, so a correction of their rounding does not stay in it; SemiImplicit carries its velocity,
  but its joints are springs, whose force on a few 1e-7 m of rounding is small. Read in the source, not yet tested: with
  the displacement patch VBD does both, its joints correcting the rounding in full within the step and its velocity, the
  forward step's plus the step's displacement over the step, keeping each correction as a kick, kick after kick. A fix
  would keep the joints from reading the rounding: the joint's error taken from the bodies' inertial targets and
  displacements relative to one another, not from their rounded poses.
- XPBD's loss falls from 12,466 to 7,409 ppm as the step falls fourfold, not in proportion; SemiImplicit's stays near
  4,600: neither is the first-order fall run 028 found for XPBD at larger steps, reported here and not read further.
- After the run (21 October 2026, host checks on the second x86-64 host, not registered): a VBD joint frame patch in
  design (each joint evaluated from the child's inertial target centre, every pose its target's centre less that centre
  plus its carried displacement, every previous pose less the forward step's v dt) on the displacement patch: safe when
  off (every play byte for byte the displacement patch's), the chain at the origin 6,340 and 914 ppm (6,410 and 952
  without), 10 m out 4,670 at 0.375 ms (5,243) and **3,957 at 0.09375 ms (3,281): worse**. The floor is not the joint
  evaluation's cancellation; it is as read above, the rounding of each step's stored 32-bit pose corrected within the
  next step by the joints and kept in the carried velocity. A fix carries what the stored pose rounds away (each
  position a pair of 32-bit numbers, high and low) wherever VBD reads a pose; not yet designed.
- Also after the run (21 October 2026, the second x86-64 host, not registered): VBD with the displacement patch, the
  same chain at 0, 1, 4, 10 and 40 m from the origin: at 0.09375 ms its largest energy departure is 952, 815, 1,485,
  3,281 and 3,062 ppm, at 0.375 ms 6,410, 6,301, 6,725, 5,243 and 4,466. The floor does not grow with the 32-bit
  spacing of the chain's coordinates (four times larger at 40 m than at 10 m, the floor the same): what 10 m out adds at
  the smallest step is not traced, and a fix that carries the stored pose's rounding is not justified by this.
- And (the same host): at 0.09375 ms with VBD's iterations at 1, 2, 5, 10 and 20, the chain at the origin departs by
  1,667, 1,018, 983, 952 and 921 ppm (converging), 10 m out by 3,413, 2,655, 3,122, 3,281 and 3,261: the far floor is
  not the solve's convergence either.
- And (the same host, the hinge to the world logged every 2,000 steps at 0.09375 ms, in 64 bits from the state): the
  first link's anchor stays 0.7 to 2.4 um from its hinge at the origin and 0.7 to 4.9 um 10 m out, the kinetic energy
  moving by about 1% either way as the joint's penalty takes and gives it back: 10 m out the joint carries a larger,
  noisier gap, the 32-bit world positions' scale (1 um there) entering the joint's error. Why the floor does not grow
  again at 40 m is not traced.
- And (the arm64 host, the same probe at 0, 4, 10 and 40 m): the hinge's gap grows with the distance (mean 1,954, 2,195,
  2,867 and 4,645 nm; largest 3.8, 5.5, 5.7 and 11.8 um) while the chain's lowest kinetic energy stays within 0.2% across
  the four (510.2 to 511.2 mJ): the 32-bit world positions widen the joint's error with the distance, but the energy
  floor read by the measure does not follow it.
- XPBD's part of issue 12 (the second x86-64 host, 21 October 2026, not registered): the chain at 0.375 ms on XPBD as
  released, its largest energy departure at its default joint relaxations (0.7 linear, 0.4 angular) 12,466, 11,809,
  8,447 and 8,706 ppm at 2, 8, 32 and 128 iterations; with both relaxations 1.0 the chain diverges at every iteration
  count (the same plays made again on the Newton host, every reading the note quoted the same): its kinetic energy grows from 0.52 J to 61 J at
  8 iterations, 608 J at 32 and 1,139 J at 128, and past the
  measure's range at 2 (corrected 21 October 2026: this note first read the 2-iteration play's departure as 274 ppm
  and quoted 73,613 and 10,888 ppm at 32 and 128; those three are readings of energies beyond the measure's
  whole-number range, where its products wrap; the 991,526 ppm at 8 iterations is right, of the largest kinetic
  energy, 61 J). XPBD's chain loses its energy to the under-relaxation
  that keeps its joint solve stable; at full relaxation the solve diverges. A fix is a joint solve stable at full
  relaxation, not a setting.
- And a joint solve in design (the Newton host, 21 October 2026, not registered): XPBD's contact pass divides each
  body's summed corrections by the number of its contacts before applying them, its joint pass does not, so two joints
  sharing a link each move it by its whole correction from the same state. Senua AI's joint averaging
  ([`xpbd_joint_averaging_on_1.7.0.diff`](../../patches/in_design/xpbd_joint_averaging_on_1.7.0.diff), switch
  `NEWTON_XPBD_JOINT_AVERAGING=1`) divides the joint pass's corrections by each body's count of joints. Safe when off
  (every play with the switch unset byte for byte the release's). Set, the chain no longer diverges at full
  relaxation, but it gains energy: its largest departure 110,084, 110,185, 111,509 and 111,808 ppm at 2, 8, 32 and
  128 iterations at 0.375 ms, 102,253 and 112,586 at 1.5 and 0.09375 ms (32 iterations), its kinetic energy peaking
  about 12% above the start; at the default relaxations 106,134 to 108,043 ppm. Stable, but neither falling with the
  iterations nor with the step: averaging alone is not the fix. Not registered.
- And (the Newton host): on VBD's compliant-ALM path (`rigid_compliant_alm=True`, the path Newton 1.6 says will become
  VBD's default), with the displacement patch, the chain at 0.09375 ms departs by 1,053, 832, 2,296 and 12,645 ppm at 0,
  4, 10 and 40 m: there the floor grows with the coordinates' 32-bit spacing (5.5 times from 10 to 40 m, the spacing 4
  times), as the stored pose's rounding predicts; the legacy path's ramping penalty, which stiffens a joint whose error
  persists, holds its floor level instead. A fix carries what each stored pose rounds away.
- And a fix in design (the second x86-64 host, 21 October 2026, not registered): Senua AI's VBD pose carry
  ([`vbd_pose_carry_on_displacement.diff`](../../patches/in_design/vbd_pose_carry_on_displacement.diff), switch
  `NEWTON_VBD_POSE_CARRY=1` with the displacement patch) carries each body's centre from step to step as two 32-bit
  numbers (Fast2Sum), makes the forward step's target and the solve's pose from them, sees each joint from the child's
  target centre with the pairs, and hands the joints' starting error (C0) shifted copies of the poses made from them.
  Safe when off (every play byte for byte the displacement patch's). The chain at 0.09375 ms on the legacy path departs
  by 1,458, 1,512 and 1,510 ppm at 0, 10 and 40 m (952, 3,281 and 3,062 without), on the compliant-ALM path by 1,618,
  1,689 and 1,645 (1,053, 2,296 and 12,645): **the distance from the origin no longer matters, but the origin's own
  departure rises by about 500 ppm** (tight under nudges of 1e-6 rad: 896 to 1,025 without, 1,481 to 1,537 with, so not
  the chain's sensitivity). Either half alone (the step-to-step carry, or the solve's reads of the pairs) raises it the
  same way; with neither, the target's overwrite and the C0 copies alone leave it at 952 to 958. Some read of a rounded
  stored pose beside the exact pairs is left; not found. Not registered.
- And the pose carry against the step (the two x86-64 hosts, 21 October 2026, not registered; one environment, the
  switch unset and set): the chain at 0.375, 0.1875, 0.09375, 0.046875 and 0.0234375 ms, its largest energy departure
  in ppm. **Compliant-ALM path:** at the origin 6,337, 3,139, 1,053, 342 and 353 unset, 6,493, 3,188, 1,618, 786 and 348
  set; 10 m out 3,574, 3,328, 2,296, 4,787 and 7,774 unset, 6,419, 3,198, 1,689, 798 and 357 set; 40 m out 5,532,
  11,194, 12,645, 17,709 and 24,002 unset, 6,455, 3,175, 1,645, 784 and 347 set. **Legacy path:** at the origin 6,410,
  3,122, 952, 121 and 159 unset, 6,342, 3,018, 1,458, 651 and 92 set; 10 m out 5,243, 1,123, 3,281, 5,009 and 7,922
  unset, 6,125, 3,017, 1,512, 610 and 239 set; 40 m out 4,466, 10,299, 3,062, 8,876 and 10,770 unset, 3,418, 3,163,
  1,510, 2,585 and 6,396 set. With the carry the compliant-ALM chain plays at 10 and 40 m as at the origin, within 1 in
  20 of its departure at every step, and its departure falls with the step everywhere; unset, the far chain's
  departure grows as the step shrinks. The origin's rise noted above is at two steps only: at the smallest the carry's
  departure is the unset one's or lower (348 and 353; 92 and 159), and its series falls steadily with the step where the
  unset one dips at 0.047 to 0.094 ms. On the legacy path the carry holds 10 m out but not 40 m out at the two smallest
  steps (2,585 and 6,396): a second 32-bit read on that path, not traced. The compliant-ALM path is the one Newton 1.6
  says becomes VBD's default.
