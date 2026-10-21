# Run 076: Featherstone's joint limit on a serial arm (issue 28)

Not registered: a design probe that decides nothing and states no prediction. Two light links (0.05 kg each) under
gravity, the first joint released level onto its lower limit at -0.5 rad, on Featherstone as released and with the
limit patch's three forms, at 1/240 s to 20 us: does a limit on a coupled chain stay a number, and rest, where the
release diverges? Each play's last line (the joints' angles and speeds) and where it stopped being a number.

## What was found

Played 20 October 2026 on the Newton host, from the record at 0b90a9e. Each play's last line (the first joint's angle,
urad, and speed, urad/s; the second's) and where it stopped being a number (`measured.txt`).

| Two light links, the first on its limit at -0.5 rad | 1/240 s | 1 ms | 250 us | 50 us | 20 us |
|---|---|---|---|---|---|
| As released | stops, step 16 | step 59 | step 236 | step 1,416 | step 8,708 |
| `=1`, kept from pulling, explicit | step 16 | step 59 | step 236 | step 1,416 | step 8,708 |
| `=2`, implicit: the first joint at the end | -0.500759 rad, 0.756 rad/s | -0.500632, -0.319 | -0.500069, -0.054 | -0.500002, -0.0002 | -0.500003, 0.0008 |
| **`=3`**, decided on the implicit force | **-0.500001 rad, -28 urad/s** | **-0.500006, -164** | **-0.500002, -106** | **-0.500002, -230** | **-0.500003, 769** |

The second link swings free under gravity in every play that stays a number (-1.9 to -2.8 rad, 21 to 32 rad/s at the
end).

- **On a serial arm the release diverges at every step from 1/240 s to 20 us**, as the reported 6-axis arms do; the
  limit kept from pulling alone does not change that (its bound is the explicit one).
- **The implicit forms never stop being a number**, and the third holds the limited joint at rest on its limit at
  every step, the second link swinging free above it: issue 28's divergence removed on a coupled chain. At 20 us the
  speed column again reads a 32-bit stuck angle (runs 068, 070).
