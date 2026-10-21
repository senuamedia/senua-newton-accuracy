# Run 137: Study 34, a fast body kept from passing through a thin slab, the patch on contacts strictly apart (issue 20's tunnelling)

The thirty-fourth registered study ([`PREREGISTRATION_34.md`](../../preregistrations/PREREGISTRATION_34.md)), played
once with [`play.sh`](play.sh) on the engines made by [`setup_engine.sh`](setup_engine.sh): Newton 1.7.0 as released;
with the record's validated friction chains (`chain`); and the chain with Senua AI's speculative normal patch, its third
form ([`semi_speculative_normal_v3_on_chain.diff`](../../patches/in_design/semi_speculative_normal_v3_on_chain.diff),
sha256 e9678069462fb759...), its switch unset (`off`) and set (`on`).

After Study 33 (6 of 8): its slide moved 1 in 204 because the cube started exactly touching the plane and the first form
took separation 0 as apart, its impulse carrying the weight for one step without friction (host check: the impulse at
step 0 only, nothing after). The third form acts on contacts strictly apart; on the host it played Study 33's slide and
hold byte for byte as the chain and kept every drop as the first form did.

## What it found

Played 20 October 2026 (UTC) on the second x86-64 host (`started.txt`, `finished.txt`); the measured lines in
`measured.txt`, the rules in [`rules.txt`](rules.txt). **7 of 8 rule lines held; R3 failed.**

| The cube's lowest face at the end, mm (the slab 5 mm, its top at 0) | in the gap, 4 ms | in, 1.5 ms | beyond, 4 ms | beyond, 1.5 ms |
|---|---|---|---|---|
| As released, XPBD, SemiImplicit, Featherstone | -3,033 to -8,081 | -4,821 to -9,923 | -9,801 | -9,800 to -9,923 |
| XPBD, the configuration | 0.000 | 0.000 | 0.000 | 0.000 |
| SemiImplicit and Featherstone, the configuration | **-1,247 (through)** | **-2.85 (past the middle)** | +4,620 (thrown up) | -0.81 |
| The MuJoCo solver, with speculative contacts (reported) | -8,001 | -8,040 | -9,801 | -9,850 |

- R1 held (8 of 8); R2 held (as released all three through, every scene and step); **R4 held: the slides byte for byte
  the chain's on all three** (162,966, 163,362 and 163,364 um) and the holds 6, 0 and 0 um/s; R5 held.
- **R3 failed on SemiImplicit and Featherstone inside the gap**: the first step cuts the cube's speed so that it closes
  to the slab exactly at the step's end, and it arrives still closing at 12.5 m/s (5 cm over 4 ms); the next step finds
  it touching (separation 0), which the third form leaves to the penalty contact, and the penalty does not stop 12.5 m/s
  on a 5 mm slab within a 4 ms step (through) or a 1.5 ms one (past the middle). The first form took separation 0 as
  apart, which kept these cubes (Study 33) and gave a slide's touching start a frictionless first step.
- XPBD with Newton's own configuration rests on the slab in every scene, as in Study 33.
- After the run, not registered (host checks): the second form on Featherstone at 1 and 64 sweeps (the cut not reached
  beyond the gap: the cube tilts to one contact in the first step and goes on at 94 m/s), so the friction a closing
  contact needs is what Featherstone's joint-space pass does not converge on. A contact closing fast once it touches
  needs the normal impulse too, with friction counted on it, on both solvers; not yet designed for Featherstone.
- By the registration issue 20's tunnelling stays open on SemiImplicit and Featherstone; on XPBD, Studies 33 and 34
  together hold it fixed by Newton's own configuration in every scene played.
