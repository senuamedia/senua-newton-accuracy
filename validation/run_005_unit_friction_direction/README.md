# Run 005: a patch in design, friction with a unit direction

15 October 2026. Not registered: a patch in design, checked against the five checks before any study registers its
rules. Played on run 001's machine by [`play.sh`](play.sh) (pushed before its plays); reading `reading.txt`.

## The patch

[`patches/in_design/unit_friction_direction.diff`](../../patches/in_design/unit_friction_direction.diff) (sha256
dd4042afa2894458...), against Newton v1.6.1 (commit 713fecdc..., `patched_source.txt`). Runs 002 to 004 found that
SemiImplicit and Featherstone give friction the direction `vt / H(vt)`, H Warp's Huber norm not divided by its width,
so friction is Coulomb's times |v| / H(v). The patch is additive. It adds a new module,
`semi_implicit/kernels_contact_unit.py`, holding a copy of the stock body contact kernel in which only the friction
changes, to `vt / |vt| * min(kf * |vt|, mu * N)`: a unit direction, the size Coulomb's limit at most, the stock
kernel's own viscous branch below it. At the stock kernel's two call sites (SemiImplicit's `eval_body_contact_forces`
and Featherstone's step), the copy is imported and launched instead only when `NEWTON_UNIT_FRICTION_DIRECTION=1`.
The stock kernel is not changed. Newton was installed from the patched source in its own environment, with every
dependency pinned to run 001's (`environment_patched.txt`).

## The five checks

Three arms, each in its own scratch folder: stock (Newton 1.6.1 from PyPI, run 001's environment), off (the patched
source, switch unset) and on (switch set). Each played at 0.125 ms run 001's five one-cube scenes and run 003's
settled slide on SemiImplicit and Featherstone, run 004's plate on both at friction_smoothing 1.0 and 0.01, and run
001's hold and slide on XPBD and the MuJoCo solver, which do not use the kernel.

**1. Required.** N1, measured in run 001; its cause read in the kernel and confirmed on the plate in run 004.

**2. Correct.** With the switch on, SemiImplicit and Featherstone give the same numbers as each other, and:

| | Stock | On | Right answer |
|---|---|---|---|
| Cube set sliding at 1 m/s, friction 0.4: distance | 43,330 um | 127,860 um | 127,551 um |
| The same, kicked from rest | 43,756 um, back by 26,646 | 127,467 um, back by 412 | 127,551 um |
| Plate kicked from rest, smoothing 1.0 | 42,315 um | 127,467 um | 127,551 um |
| Plate, smoothing 0.01 | 690 um | 127,467 um | 127,551 um |
| Plate's deceleration, 302 to 350 ms | 8,504 to 13,124 mm/s2 (smoothing 1.0) | 3,886 to 4,019 mm/s2 | 3,920 mm/s2 |
| Friction over the oblique impact, per 10,000 | 4,336 | 2,999 | 3,000 |
| Largest turn of the cube: slide, settled slide, impact | 0.22, 0.45, 0.12 rad | 0.008, 0.010, 0.017 rad | 0 |

The plate's distance and deceleration no longer depend on the smoothing width, which the patched kernel does not use.

**3. Nothing else gets worse.** The set-down and the drop are byte-identical to stock; XPBD and the MuJoCo solver
are byte-identical to stock with the switch on. The hold's creep reading is unchanged (735 um/s, the viscous branch,
known issue N2, which this patch does not address); its file differs on 1,113 of 16,000 steps, in the moments after
the push starts where the cube briefly moves fast enough to leave the viscous branch (the largest difference in speed
478 um/s).

**4. Safe when off.** The patched source with the switch unset plays all 24 files byte for byte as Newton 1.6.1 from
PyPI does (`identity_off.txt`).

**5. The solver keeps converging.** SemiImplicit and Featherstone do not iterate; with the switch on no play stopped
being a number and none blew up.

## What it shows

A copy of one kernel with its friction lines changed gives Newton's SemiImplicit and Featherstone Coulomb's friction: the
slide that ends goes Coulomb's distance to within 0.3%, an impact takes Coulomb's friction, the cube no longer tips,
and the smoothing width no longer matters. Off, Newton is byte for byte as released. The creep at rest (N2) is a
separate correction. The patch stays in design until a registered study states its rules and plays it once.
