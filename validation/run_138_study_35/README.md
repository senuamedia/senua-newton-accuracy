# Run 138: Study 35, a fast body kept from passing through a thin slab, every contact given its normal (issue 20's tunnelling)

The thirty-fifth registered study ([`PREREGISTRATION_35.md`](../../preregistrations/PREREGISTRATION_35.md)), played once
with [`play.sh`](play.sh) on the engines made by [`setup_engine.sh`](setup_engine.sh): Newton 1.7.0 as released; with
the record's validated friction chains (`chain`); and the chain with Senua AI's speculative normal patch, its fourth form
([`semi_speculative_normal_v4_on_chain.diff`](../../patches/in_design/semi_speculative_normal_v4_on_chain.diff), sha256
97407bbb600c175f...), its switch unset (`off`) and set (`on`).

The fourth form, after Studies 33 and 34 and their host checks: every contact the force pass finds gets a normal impulse
in the Coulomb pass, one still apart the impulse that keeps it apart at the step's end, one closed the impulse that
stops its closing, never pulling; each contact's friction cone counts that impulse beside the penalty's; and
Featherstone's pass rebuilds its joint-space inertia where the joints are each sweep (traced: with it built where the
step left the joints, a fast cube's rotation grew from 0.001 to 149 rad/s over 48 sweeps of one step, friction answering
the slip that the normal impulse's 40 cm move gave a rotation). On the host: every drop of Studies 33 and 34 kept on both
solvers, most at rest on the slab within 0.7 um of its surface; the slides stopping dead, 0.24 to 0.38% shorter than the
chain's and within 0.25% of Coulomb's distance; the holds at 1 um/s.

## What it found

Played 20 October 2026 (UTC) on the second x86-64 host (`started.txt`, `finished.txt`); the measured lines in
`measured.txt`, the rules in [`rules.txt`](rules.txt). **6 of 6 rule lines held.**

| The cube's lowest face at the end (the slab 4 mm, its top at 0) | in the gap, 3 ms | in, 1 ms | beyond, 3 ms | beyond, 1 ms |
|---|---|---|---|---|
| As released, XPBD, SemiImplicit, Featherstone | 4.4 to 8.9 m below | 7.0 to 7.6 m below | 3.9 to 10.6 m below | 10.6 to 10.7 m below |
| XPBD, the configuration | at rest, 7 nm | at rest, 7 nm | at rest, 7 nm | at rest, 7 nm |
| SemiImplicit, the configuration | thrown up, 1.32 m above at 13.3 m/s | at rest, 19 nm | thrown up, 0.40 m | at rest, 34 nm |
| Featherstone, the configuration | thrown up, 1.32 m above at 13.3 m/s | at rest, 19 nm | thrown up, 0.19 m | at rest, 30 nm |
| The MuJoCo solver, as released and with speculative contacts (reported) | 8.9 m below | 8.0 m below | 10.6 m below | 10.7 m below |

- R1 held (8 of 8 plays off byte for byte the chain's with speculative contacts). R2 held: as released all three go
  through in every scene at both steps. **R3 held: with the configuration none goes through**: at 1 ms SemiImplicit
  and Featherstone bring the cube to rest on the slab within 34 nm of its surface, XPBD everywhere within 7 nm; at 3 ms
  the penalty contact throws SemiImplicit's and Featherstone's cube back up (its explicit damping on a cube arriving at
  speed: the record's F5 and F11 bounce, reported, not ruled). R4 held: the slides 154,051, 154,070 and 154,061 um
  against Coulomb's 154,337 (within 1 in 540; the chain's 154,051, 154,336 and 154,337), the holds 6, 1 and 1 um/s. R5
  held.
- **Issue 20's tunnelling fixed on Newton's own solvers**: on XPBD by Newton's own configuration (64 iterations and
  speculative contacts, Studies 33 to 35), on SemiImplicit and Featherstone by Senua AI's speculative normal patch with
  speculative contacts. With the patch their slide stops dead 0.17% short of Coulomb's distance, where with the chain
  alone it is within 1 in 100,000 and creeps after stopping.
- The MuJoCo solver goes through with or without speculative contacts, the same bytes: MuJoCo's contact acts on no
  contact still apart.
