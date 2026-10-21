# Run 077: SemiImplicit's joint angle and joint limit (issues 27 and 16)

Not registered: a design probe, its predictions pushed with [`play.sh`](play.sh) before any play. Newton 1.7.0 from
PyPI, and the same with Senua AI's SemiImplicit joint patch in design first on the path
([`semi_joint_on_1.7.0.diff`](../../patches/in_design/semi_joint_on_1.7.0.diff), sha256 e18cc103222a1fec...).

## The patch

SemiImplicit plays a joint as forces between two free bodies, the joint's angle read from their relative rotation each
step (`eval_body_joints`). A revolute's angle is read by `wp.quat_twist_angle_signed`, in [-2 pi, 2 pi] on the
quaternion's branch, so a drive held at 7.0 rad reads the joint at 7 - 4 pi and pulls it a whole turn back (F22); a
D6's two or three angles are read by `quat_decompose`, whose angles are about the joint frame's own X, Y and Z, so a
D6 about Y and Z has its Y drive read the angle about X; the limit pulls the joint back as it leaves (F16). A copy of
`eval_body_joints`, launched in its place when a switch is set (read once):

- `NEWTON_SEMI_JOINT_ANGLE=1`: a single rotational degree of freedom measured within pi of a reference, the middle of
  its limit range or, where the range is 2 pi wide or wider, its drive's target (pull request #4316's rule for XPBD);
  a D6's relative rotation expressed in the basis of its own axes before it is decomposed.
- `NEWTON_SEMI_JOINT_LIMIT=1`: the limit's spring and damper never pulling.

## What is played

Run 062's scenes (#4547's revolute driven at 2 N m/rad and held at its target, 7.0 and 2.5 rad, and #4540's D6 about
y and z held at 0.2 and 0.4 rad; one body of unit inertia, no gravity, 1 ms, 1 and 1,000 steps), with Newton's defaults
(`semi`) and as the reports set SemiImplicit (`semirep`: no angular damping, no joint attachment); as released, the
patch's tree with its switches unset, and `ANGLE=1`. Run 042's strike (an arm of half-size 0.04 m, 0.4 m out, released
level onto -1 rad) at 0.1 and 1 kg, 0.25 and 0.0625 ms, as released, unset and `LIMIT=1`; the spring and damper kept
from pulling turn it at -0.815 and -0.450 rad. The rig reads SemiImplicit's joint through `newton.eval_ik`, which
wraps too: a joint held at 7.0 rad reads -5,566,345 urad; held is read from the speed and from the reading staying put.

## Predictions (pushed before the plays)

| Check | Prediction |
|---|---|
| J0 | With the switches unset every play byte for byte the release's |
| J1 | As released the revolute at 7.0 rad turns at 20,000 urad/s or more after one step (run 062: 25,131) |
| J2 | With `ANGLE=1` it is held: its speed within 100 urad/s of 0 after 1 and 1,000 steps, its reading within 1 mrad of where it started |
| J3 | With `ANGLE=1` the revolute at 2.5 rad still held at 2.5 rad, within 1 mrad |
| J4 | As released the D6's first angle drifts past 0.3 rad in 1,000 steps (run 062: 0.43) |
| J5 | With `ANGLE=1` the D6 held at 0.2 and 0.4 rad, each within 1 mrad, after 1,000 steps |
| J6 | With `LIMIT=1` the strike turns back within 0.02 rad of -0.815 (0.1 kg) and -0.450 rad (1 kg), at both steps |

## The result: 15 of 19 checks held

Played 20 October 2026, 11:07 to 11:08 UTC, on the Newton host, from the record at f1f256d (these predictions pushed);
`measured.txt` and `checks.txt` made there. Played again on the second x86-64 host and on arm64.

| Issue 27's scenes, 1,000 steps of 1 ms | As released | `NEWTON_SEMI_JOINT_ANGLE=1` |
|---|---|---|
| Revolute held at 7.0 rad: speed after one step, urad/s | 25,131 (thrown) | **0** |
| The same after 1,000 steps | | **-2**; its reading unchanged |
| Revolute held at 2.5 rad | held | held, 2,500,000 urad |
| D6 held at 0.2 and 0.4 rad, after 1,000 steps | drifted to 0.431 and 0.56 | **0.200000 and 0.400000** |

The same with the reports' settings (no angular damping, no joint attachment): 25,133 thrown as released; held with
the patch, the D6 at 0.200000 and 0.400000 rad. With the switches unset every play is the release's byte for byte (16
of 16).

- **Issue 27 on SemiImplicit: J0 to J5 held.** With the angle measured near its reference (#4316's rule) a drive holds
  its joint past a full turn, and with the D6's rotation read about its own axes the two-axis D6 holds at its targets
  exactly, in both reports' scenes and with Newton's defaults.
- **J6 (the limit kept from pulling) was not measured.** SemiImplicit cannot play run 042's arm at 0.25 ms (0.1 and 1
  kg) or at 0.0625 ms (0.1 kg) with its default joint attachment: the arm leaves the rig's range at steps 9 to 27,
  before it reaches the limit, the joint penalty's explicit limit (issue 10, F10). The runner then handed the word
  `none` (no turn back) to the measure's `rule`, which read it as the number 68,973; the four lines are void, not
  failed physics. The one play that ran, 1 kg at 0.0625 ms, turns back at -0.826 rad as released and -0.824 with the
  patch, against the no-tension form's -0.450: on SemiImplicit's penalty joint the limit's pull is not what sets the
  rebound. A scene SemiImplicit can play, with `joint_attach_kd=0` (Study 9), is the next probe of issue 16's
  SemiImplicit part.
