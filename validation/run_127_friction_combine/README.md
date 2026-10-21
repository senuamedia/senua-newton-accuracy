# Run 127: one friction combination for every solver (issue 18)

Not registered: a design probe, its predictions pushed with [`play.sh`](play.sh) before any play. Newton 1.7.0 from PyPI,
and the same with Senua AI's friction combination patch in design first on the path
([`friction_combine_on_1.7.0.diff`](../../patches/in_design/friction_combine_on_1.7.0.diff), sha256 35c754f7077b0103...,
made by this run's [`setup_engine.sh`](setup_engine.sh)).

## The patch

Run 059 found two shapes' frictions combined by the mean on Newton's own contact and by MuJoCo's rule on the MuJoCo
solver, so one scene slides 92.5 mm on XPBD and 56.9 mm on the MuJoCo solver (issue 18, N3, discussion #2377); in
1.7.0's source VBD takes a third rule, the geometric mean. The MuJoCo solver can follow no other rule than MuJoCo's:
MuJoCo combines a contact's friction itself, with its own contacts and with Newton's (`contact_params` on the geoms'
friction, priority and solmix). The patch's switch `NEWTON_FRICTION_COMBINE=1` (read once) makes Newton's own solvers
follow MuJoCo's rule for body contacts: SemiImplicit's and Featherstone's contact (their shared kernel), XPBD's, and
VBD's two body-body material kernels take the larger of the two shapes' coefficients (sliding, and for XPBD torsional
and rolling, each), or the higher-priority shape's when the model carries MuJoCo's geom priority (the MuJoCo solver's
custom attributes registered) and the two differ. One shared rule (`solvers/friction_combine.py`), the priority array
passed to each kernel. Unset, nothing changes. On the host, before this probe: the four solvers' mixed slide equal to
their own slide at 0.9 with no priority, and at 0.2 with the cube's priority higher.

## What is played

Run 059's slide: the cube's friction 0.2 and the plane's 0.9, the priority unregistered, registered and equal, the
cube's higher and the plane's higher; on XPBD, SemiImplicit, Featherstone, VBD and the MuJoCo solver, as released,
with the patch and the switch unset (`off`), and set (`on`); beside each solver's own slide with one friction for both,
0.2 and 0.9, as released. Read by Senua AI's `sx_contact` (`stop`).

## Predictions (pushed before the plays)

| Check | Prediction |
|---|---|
| C0 | Every play a number |
| P1 | Off, every mixed play byte for byte the release's |
| P2 | As released, XPBD's mixed slide departs from its slide at 0.9 by more than 1 in 10 (it takes the mean) |
| P3 | On, every solver's mixed slide within 1 in 100 of its own slide at 0.9 when no priority decides (unregistered, equal, the plane's higher), and of its slide at 0.2 when the cube's is higher |

Reported: every distance.

## What it found

Played 20 October 2026 on the second x86-64 host (`started.txt`, `finished.txt`); the measured lines in `measured.txt`,
the checks in [`checks.txt`](checks.txt). **13 of 13 checks held.**

| Slide, um (the cube 0.2, the plane 0.9) | one friction 0.2 | one friction 0.9 | mixed, as released | the cube's priority higher, as released | mixed, on (no priority, equal, the plane's higher) | the cube's priority higher, on |
|---|---|---|---|---|---|---|
| XPBD | 254,848 | 56,454 | 92,519 | 92,519 | 56,454 | 254,848 |
| SemiImplicit | 84,199 | 40,429 | 38,509 | 38,509 | 40,429 | 84,199 |
| Featherstone | 84,232 | 40,335 | 40,046 | 40,046 | 40,335 | 84,232 |
| VBD | 328,089 | 112,599 | 185,127 | 185,127 | 112,599 | 328,089 |
| The MuJoCo solver | 254,964 | 56,866 | 56,866 | 254,964 | 56,866 | 254,964 |

- C0 held; P1 held (20 of 20 mixed plays off byte for byte the release's); P2 held (as released XPBD's mixed slide
  92,519 um against its 56,454 at 0.9: the mean's); P3 held on all five solvers, 10 lines.
- **With the switch, one model slides on one friction on every solver**: Newton's own solvers take MuJoCo's rule, the
  larger coefficient or the higher-priority shape's, and each slides the mixed scene byte for byte as its own slide
  at the coefficient that rule picks, as the MuJoCo solver does as released. As released each takes its own: the
  mean on XPBD, SemiImplicit and Featherstone, the geometric mean on VBD, and MuJoCo's rule on the MuJoCo solver, and
  only the MuJoCo solver honours the priority.
- The solvers' slides at one friction still differ from one another (at 0.9, from 40 mm on SemiImplicit to 113 mm on
  VBD): each solver's own friction law, issues 1 and 6, not this patch's question.
