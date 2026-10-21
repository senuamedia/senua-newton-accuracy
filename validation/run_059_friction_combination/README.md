# Run 059: two frictions in one contact, and MuJoCo's geom priority (issue 18)

Not registered: a trace. Its play script [`play.sh`](play.sh) and the predictions below were pushed before its plays.
Newton 1.7.0 as released. The rig [`tools/nwt_contact.py`](../../tools/nwt_contact.py) gains `groundmu=` (the plane's
friction apart from the cube's), `register=1` (the MuJoCo solver's custom attributes registered on the builder, so
shapes carry `mujoco:geom_priority`) and `prio=`, `groundprio=` (the two shapes' priorities, set on the model before
the solver is built); a play setting none of them is unchanged (check C0).

## Read in the source (Newton 1.7.0)

- **One coefficient.** A shape has one `mu` (with torsional and rolling); there is no static and dynamic pair.
- **Static friction dropped on import.** The USD importer reads a material's `staticFriction` and `dynamicFriction`
  and maps only `dynamicFriction` to the shape's `mu` (`usd/_resolution_policy.py`, line 459); MJCF has one
  coefficient, read as `mu` (`utils/import_mjcf.py`). Not played: this host has no USD runtime (`pxr`).
- **Two frictions combined.** Newton's own contact (XPBD, SemiImplicit, Featherstone) takes the mean of the two
  shapes' `mu` (`xpbd/kernels.py` lines 2554 to 2572: "use average contact material properties"); the MuJoCo solver
  hands both to MuJoCo, whose rule is the larger, or the higher-priority geom's when priorities differ. The priority is
  one of the MuJoCo solver's custom attributes (`geom_priority`, read from MJCF `priority` and USD `mjc:priority`), on
  a shape only when they are registered on the builder.

## What is played

One cube (1 kg, 0.05 m) sliding from 1 m/s on the plane, 0.5 ms, 0.6 s, on XPBD and on the MuJoCo solver: the cube's
friction 0.2 and the plane's 0.9, with the priority unregistered, registered and equal, the cube's higher, and the
plane's higher; beside each solver's own slide with one friction for both, 0.2, 0.55 (the mean) and 0.9. Each mixed
slide's distance checked within 1 in 100 of each one-friction slide's on the same solver.

**Disclosed before the plays:** the rig's change was checked on the host by three slides on the MuJoCo solver (at 2
ms, 0.6 s): the cube's priority higher slid 254,264 um (0.2's closed form 255,102); equal priorities and unregistered
53,202 um each (0.9's 56,689). The MuJoCo predictions below follow from the source and from that check; XPBD's from the
source alone.

## Predictions, before the plays

- XPBD slides every mixed play as its one-friction slide at 0.55, the mean, whatever the priority (it does not read
  it): within 1 in 100, and byte for byte the same across the four mixed plays.
- The MuJoCo solver slides the mixed play as its slide at 0.9 when the priority is unregistered, registered and equal,
  or the plane's higher; as its slide at 0.2 when the cube's is higher.
- So the same scene slides on different frictions on Newton's own solvers and on the MuJoCo solver: 0.55 against 0.9.
- C0 holds.

## What was found

Played on the Newton host, 2026-10-19T13:49:03Z to 2026-10-19T13:51:56Z. Reading [`reading.txt`](reading.txt), checks
[`checks.txt`](checks.txt): each mixed slide is checked against all three one-friction slides, so by design only
one of its three checks can hold; 9 of 25 held, exactly the predicted ones, and C0.

| Slide (the cube 0.2, the plane 0.9) | XPBD, um | The MuJoCo solver, um |
|---|---|---|
| one friction, 0.2 / 0.55 / 0.9 | 254,848 / 92,519 / 56,454 | 254,964 / 92,756 / 56,866 |
| priority unregistered | **92,519** (the mean's) | **56,866** (the larger's) |
| registered, equal | 92,519 | 56,866 |
| the cube's higher | 92,519 | **254,964** (the cube's) |
| the plane's higher | 92,519 | 56,866 |

- **Every prediction held, byte for byte:** XPBD's four mixed slides are its slide at 0.55, the mean, whatever the
  priority; the MuJoCo solver's are its slide at 0.9, the larger, but when the cube's priority is higher, its slide at
  0.2. So on 1.7.0 the MuJoCo solver honours MuJoCo's geom priority once its custom attributes are registered on the
  builder, and **the same scene slides on different frictions by solver**: the mean (0.55) on Newton's own contact,
  the larger (0.9) or the priority's on the MuJoCo solver, a slide of 92.5 mm against 56.9 mm here. C0 held.
- Issue 18 on 1.7.0: one coefficient (by design), static friction dropped on USD import (read in the source), and the
  combination differs between Newton's solvers, the priority reaching the MuJoCo solver only.

Every reading and check of this run was made again on the laptop, byte for byte, from its kept files, with a build of
[the measure](../../measure/README.md) (20 October 2026).
