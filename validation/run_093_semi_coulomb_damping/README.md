# Run 093: SemiImplicit's Coulomb friction pass on the contact damping patch (issues 6 and 9)

Not registered: a design probe, its predictions pushed with [`play.sh`](play.sh) before any play. Newton 1.7.0 from
PyPI, and the same with Senua AI's unit friction direction and contact damping patches
([`patches/newton-1.7.0/`](../../patches/newton-1.7.0/README.md)) and the third form of its SemiImplicit Coulomb
friction patch in design
([`semi_coulomb_friction_v3_on_damping.diff`](../../patches/in_design/semi_coulomb_friction_v3_on_damping.diff), sha256
b1351279c950603f...) first on the path.

## The patch

[Run 092](../run_092_semi_coulomb_sweeps/README.md) found the second form holds the cube from 16 sweeps a step and keeps
the slide Coulomb's, but loses the suite's refinement chain (T08) to the bounce, which grows as the step shrinks as
released (issue 4). Issue 4 is fixed by the contact damping patch, `NEWTON_CONTACT_DAMPING_NO_PULL=1`, which damps the
normal contact in both phases and keeps it from pulling ([Study 3](../../docs/studies/03-normal-contact.md)); the
friction pass's force pass is a copy of the stock one and so did not take it. The third form, on 1.7.0 with the damping
patch, makes the same change in its force pass when that switch is set; unset, it is the second form.

## What is played

On SemiImplicit as released (`stock`); with the damping patch alone (`damp`); with the third form at 64 sweeps, the
damping switch unset (`k64`); and with both, at 16 and 64 sweeps (`d16`, `d64`): run 090's hold and slide at 2, 0.5 and
0.125 ms; the contact suite for `damp`, `d16` and `d64` (as released, run 092's suite, played by the same code).

## Predictions (pushed before the plays)

| Check | Prediction |
|---|---|
| C0 | Every play with a patch a number; `k64` each hold and slide byte for byte run 092's at 64 sweeps, and `stock` run 092's as released |
| C1 | `d64`'s hold within 10 um/s of still at every step |
| C2 | `d64`'s slide within 1 in 100 of Coulomb's 102,041 um at every step |
| C3 | `d64`'s suite passes T06, and loses no verdict that passes as released or with the damping patch alone |

Reported: `d16`, the damping patch's suite, every verdict.

## What it found

Played 20 October 2026 on the second x86-64 host (`started.txt`, `finished.txt`); the measured lines in
`measured.txt`, the checks in [`checks.txt`](checks.txt), the suites under `suites/`. **7 of 8 checks held.**

| Check | Result |
|---|---|
| C0 | Held: every play a number; `k64` 6 of 6 byte for byte run 092's at 64 sweeps, `stock` 6 of 6 run 092's as released |
| C1 | Held: `d64`'s hold 1, 0 and 0 um/s at 2, 0.5 and 0.125 ms |
| C2 | Held: `d64`'s slide 101,529, 102,279 and 102,467 um against 102,041 |
| C3 | T06 **failed** (27,501 um/s at the suite's largest step, 0 at its 1/16); nothing lost against the release or the damping patch alone |

- **With both patches the suite passes 7 of 10**, as released 4 and with the damping patch alone 4: steady sliding
  (T02), Coulomb at impact (T05), the friction over an impact (T10) and the refinement chain (T08: 3,804,355 falling to
  1,055 at every halving, where with the friction pass alone it rose at the fifth) all pass.
- **What fails, fails at the suite's largest step only, 10 ms**, where the normal contact is past SemiImplicit's
  explicit limit: there the cube rebounds 1.69 times its drop height (T04: 16,936 per 10,000) as released, with the
  damping patch and with both, and 0 at every smaller step with the damping patch; T06 creeps 27,501 um/s there and 0 at
  1/16; T07 is 990,500 um/s at 1/16, within its 3 in 100 of 980,000, and 1,440,300 at 10 ms. Issue 9's normal part is
  fixed by a step within m / (4 kd) ([Study 9](../../docs/studies/09-newtons-own-options.md)), which the suite's 10 ms
  step is not.
- The damping patch alone does not hold the cube (469,945 um/s at 2 ms, 700 and 735 at the smaller steps) and leaves
  the slide 197,944 to 38,713 um: the friction is the friction pass's to fix.
- The 16-sweep suite and plays are the 64-sweep ones to within 1 in 1,000 but T06 and T07 at 10 ms.
