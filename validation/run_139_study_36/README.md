# Run 139: Study 36, VBD's chain far from the origin, its poses carried in two 32-bit numbers (issue 12)

The thirty-sixth registered study ([`PREREGISTRATION_36.md`](../../preregistrations/PREREGISTRATION_36.md)), played once
with [`play.sh`](play.sh) on the engines made by [`setup_engine.sh`](setup_engine.sh): Newton 1.7.0 with Senua AI's VBD
displacement patch (`dsp`, Study 23's engine), and with the displacement patch and Senua AI's VBD pose carry
([`vbd_pose_carry_on_displacement.diff`](../../patches/in_design/vbd_pose_carry_on_displacement.diff)), its switch unset
(`off`) and set (`on`), `NEWTON_VBD_DISPLACEMENT=1` in every play.

The pose carry, after run 125's host checks: each body's centre carried from step to step as two 32-bit numbers
(Fast2Sum), the forward step's target and the solve's pose made from them, each joint seen from the child's target
centre with the pairs, and the joints' starting error handed shifted copies of the poses made from them.

## What it found

Played 21 October 2026 (UTC) on the second x86-64 host (`started.txt`, `finished.txt`); the measured lines in
`measured.txt`, the rules in [`rules.txt`](rules.txt). **15 of 15 rule lines held.**

The chain's largest energy departure, ppm, on VBD's compliant-ALM path:

| Base of the chain | carry | 0.4 ms | 0.2 ms | 0.1 ms | 0.05 ms | 0.025 ms |
|---|---|---|---|---|---|---|
| origin | unset | 8,073 | 4,091 | 1,876 | 445 | 440 |
| origin | set | 7,957 | 4,042 | 2,015 | 999 | 462 |
| 15 m | unset | 6,144 | 2,882 | 1,495 | 2,868 | 5,762 |
| 15 m | set | 7,969 | 4,102 | 2,035 | 1,000 | 470 |
| 60 m | unset | 8,790 | 8,773 | 9,218 | 18,007 | 33,900 |
| 60 m | set | 7,987 | 4,047 | 2,058 | 995 | 454 |

- R1 held: with the switch unset, all 39 plays byte for byte the displacement patch's.
- R2 held: unset, the chain's departure at 0.025 ms is 5,762 ppm at 15 m and 33,900 at 60 m, against 440 at the origin.
- R3 held: set, the chain at 15 and 60 m within 1 in 10 of the origin's at every step (within 2.2% at every step).
- R4 held: set, the departure falls at each halving of the step at 0, 15 and 60 m, by about half each time, a first-order
  integrator's error; unset, the origin's falls but flattens between 0.05 and 0.025 ms (445, 440).
- R5 held: the spinning body's centre still (0 um/s at every step), the slide settling (151,905 and 152,004 um at 0.24
  and 0.06 ms against 152,022 at 0.03 ms), the hold still (0 um/s at both steps). Every one of these plays with the
  carry set is the same reading as unset but the slide at 0.24 and 0.06 ms (151,906 and 151,999 unset).
- R6 held: every play a number throughout.

Reported, not ruled: the legacy path (`rigid_compliant_alm=False`), the same chain:

| Base of the chain | carry | 0.4 ms | 0.2 ms | 0.1 ms | 0.05 ms | 0.025 ms |
|---|---|---|---|---|---|---|
| origin | unset | 7,981 | 3,956 | 1,782 | 55 | 161 |
| origin | set | 7,854 | 3,985 | 1,906 | 857 | 188 |
| 15 m | unset | 7,677 | 4,210 | 3,738 | 5,359 | 9,633 |
| 15 m | set | 8,603 | 3,833 | 1,916 | 894 | 448 |
| 60 m | unset | 9,455 | 5,888 | 5,519 | 12,684 | 15,311 |
| 60 m | set | 10,427 | 3,803 | 1,998 | 5,269 | 5,558 |

On the legacy path the carry plays 15 m out as at the origin but not 60 m out at the two smallest steps, as run 125's
notes found at 40 m: a second read rounded to the 32-bit spacing remains on that path, not traced.

## What it decides

**Issue 12's VBD part is fixed on VBD's compliant-ALM path**, the path Newton 1.6 says becomes VBD's default, by Senua
AI's VBD displacement patch and pose carry together: a free chain's energy departure falls with the step wherever the
chain is. The pose carry is validated into [`patches/newton-1.7.0/vbd_pose_carry.diff`](../../patches/newton-1.7.0/vbd_pose_carry.diff)
(the same file as its registration names). The legacy path's far chain and XPBD's part (a joint solve stable at full
relaxation) stay open, and issue 12 with them.

## Checked

- Every reading and rule made again on the laptop from the kept files (21 October 2026): all 117 readings and all 15
  rule lines byte for byte `measured.txt` and `rules.txt`.
- Played again on the Newton host (x86-64): all 117 play files and statistics byte for byte. Played again on the arm64
  host: every statistics file and the 27 spin, slide and hold plays byte for byte; 88 of the 90 chain plays differ in
  their low digits (2 s plays of up to 80,000 steps), their re-read on x86-64 not yet made.
