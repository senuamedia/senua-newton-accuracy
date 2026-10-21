# The fixes already out there

Every fix to one of this record's issues that is already in a Newton release or proposed upstream, gathered on 19
October 2026 from Newton 1.7.0's changelog and the open pull requests of
[newton-physics/newton](https://github.com/newton-physics/newton). Each is to be measured as it stands, on Newton
1.7.0, against the same rules Senua AI's own patches were held to, beside Senua AI's fix for the same issue.

Back to the [documentation index](README.md). The issues are counted in [the issue list](issues.md).

## In Newton 1.7.0, released 14 October 2026

| Fix | Our issue | What it changes | Status |
|---|---|---|---|
| Preserve winding in VBD drive and limit evaluation for revolute and one-axis D6 joints ([#4470](https://github.com/newton-physics/newton/issues/4470), as the changelog cites it; pull request [#4479](https://github.com/newton-physics/newton/pull/4479)) | 7 (VBD's part) | VBD's joint angle kept past half a turn | **Measured**: Study 7 (run 032's VBD plays change where the joint passes pi) and run 058 (VBD's drive holds past a full turn, its bodies placed before it is built) |

No other entry of 1.7.0's changelog touches the code this record's findings were traced to: every one of those lines is
unchanged in 1.7.0 ([the seventh registration](../preregistrations/PREREGISTRATION_07.md)).

## Proposed upstream, open

| Pull request | Our issue | What it changes | Applies to 1.7.0 | Status |
|---|---|---|---|---|
| [#4316](https://github.com/newton-physics/newton/pull/4316), fix XPBD hinge angles that cross plus or minus pi (open, changes requested) | 7 | A single-axis joint's angle measured within pi of a reference inside its range (the range's middle, or the target), stateless; small swings rescaled | Yes, without offset | **Measured** ([Study 8](studies/08-upstream-fixes.md), B1 failed as predicted): no throw past pi inside the limits (in #4318's form, **fixed and validated** for issue 7, [Study 10](studies/10-xpbd-joints-floor.md)); the limit's throw-back left (2.37 rad/s); a limit short of pi changed; a drive held past pi and past a full turn (runs 054, 058) |
| [#4317](https://github.com/newton-physics/newton/pull/4317), make XPBD joint relaxation consistent (open) | 25, and 8's coupling | A positional row's moment scaled by the linear relaxation, as its linear part; the default linear relaxation lowered to 0.5 | Yes, without offset | **Fixed and validated** for issue 25, with Senua AI's speed-floor patch where a step's gain is under the floor ([Study 10](studies/10-xpbd-joints-floor.md)); measured in runs 054 and 065; Study 5 and runs 048 to 051 reported in Study 8 |
| [#4318](https://github.com/newton-physics/newton/pull/4318), opt-in PD joint drives for XPBD (draft) | 26 | A drive as an implicit PD law; builds on #4316 and #4317 | One hunk misses 1.7.0, a class variable 1.7.0 has a block before; rebased ([`pr_4318_on_1.7.0.diff`](../patches/upstream/pr_4318_on_1.7.0.diff)), every other hunk as it is | **Fixed and validated** for issue 26 (its `pd` drive) and issue 7 (its form of #4316) ([Study 10](studies/10-xpbd-joints-floor.md)); measured in [run 065](../validation/run_065_xpbd_floor_relaxation_drive/README.md); it also holds XPBD's drive past a full turn ([run 075](../validation/run_075_joint_runs_on_4318/README.md)); its limit's throw-back (issue 8) left; **a regression**: on a loop-closing joint it loses the drive and the limit the release applies (run 075) |
| [#4010](https://github.com/newton-physics/newton/pull/4010), fix rigid contact friction exceeding the Coulomb cone (draft) | 1 | The friction direction by a pseudo-Huber norm, sqrt(delta^2 + v^2), and the smoothing width lowered from 1 to 1e-3 m/s; friction is then Coulomb's times v / sqrt(delta^2 + v^2), below Coulomb's under the width | One hunk misses 1.7.0's refactored contact kernel; to rebase as Senua AI's patch was | **Measured** ([Study 8](studies/08-upstream-fixes.md), A1 failed as predicted): at its 1 mm/s default the slides are Senua AI's patch's to the micrometre; the slide depends on the width (R5), 1.8% long at 0.05 m/s |
| [#4721](https://github.com/newton-physics/newton/pull/4721), sparse VBD momentum drift, limit and external-force fixes, experimental BDF2 (draft) | 12, 13, 29 | Large: VBD's rigid sparse articulation path | Two hunks miss; it targets a later main | To measure when it rebases |
| [#4306](https://github.com/newton-physics/newton/pull/4306), a static friction coefficient on shape materials (open) | 18 | A material property, consumed by Kamino's conversions | Yes | To read which solvers consume it before a test is written |
| [#3552](https://github.com/newton-physics/newton/pull/3552), warn for ignored MuJoCo loop-joint properties (open) | 19 | A warning naming the properties MuJoCo's equality constraints drop from a loop-closing joint, and the docstring's word on it | Its docstring hunk misses 1.7.0, placed by hand ([`pr_3552_on_1.7.0.diff`](../patches/upstream/pr_3552_on_1.7.0.diff)) | **Measured** with Senua AI's warnings patch by [Study 21](studies/21-joint-features-said.md): its warning names the loop joint's limits and drive; nothing else changes |
| [#3554](https://github.com/newton-physics/newton/pull/3554), XPBD elastic multiplier persistence (merged 21 October 2026, after 1.7.0) | none of ours | XPBD's springs, bending and tetrahedra (deformables) | Yes | Outside this record's rigid scenes |
