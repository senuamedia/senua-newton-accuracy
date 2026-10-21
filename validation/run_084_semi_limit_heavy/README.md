# Run 084: SemiImplicit's limit on arms its joint attachment can carry (issue 16)

Not registered: a design probe that decides nothing and states no prediction. Runs 077 and 079 could not read a
strike on SemiImplicit: on run 042's light arms its joint attachment acts on the link's own small inertia, past its
explicit bounds. Here two heavy, large arms (5 kg, half-size 0.2 m; 2 kg, half-size 0.15 m; centres 0.4 m out), whose
own inertia puts the attachment's angular damper bound at 2.7 ms and above, released level onto Newton's limit at -1
rad, as released and with the limit kept from pulling, beside Featherstone. The no-tension form turns them back at
-0.229 and -0.340 rad. Each play's swing (where it turns, and how much it keeps a swing).

## What was found

Played 20 October 2026 on the Newton host, from the record at 7dae255 (`measured.txt`). Every play a number throughout.

| Where the arm turns back after its first strike, rad | 5 kg: 1 ms | 0.25 ms | 0.0625 ms | 2 kg: 1 ms | 0.25 ms | 0.0625 ms |
|---|---|---|---|---|---|---|
| SemiImplicit as released | -1.014 | -1.014 | -1.014 | -0.757 | -0.762 | -0.763 |
| SemiImplicit, the limit kept from pulling | -1.014 | -1.014 | -1.014 | -0.757 | -0.761 | -0.762 |
| Featherstone as released | -0.247 | -0.242 | -0.241 | -0.374 | -0.360 | -0.360 |
| Featherstone, its limit patch's `=1` | -0.235 | -0.234 | -0.234 | -0.348 | -0.345 | -0.345 |
| The no-tension spring-dashpot | -0.229 | | | -0.340 | | |

- **SemiImplicit plays these arms but its strike is not the limit's.** The 5 kg arm barely rebounds (it turns back 14
  mrad above the limit), the 2 kg arm turns back at -0.76 rad: SemiImplicit's joint is a penalty, its attachment 1e4
  N/m, which the limit's reaction stretches by centimetres (the 5 kg arm's strike torque about 190 N m over its 0.4 m
  lever), its damper taking the strike's energy. The limit kept from pulling moves the 2 kg strike by 1 mrad.
- **Featherstone with the patch's first form is the no-tension form** to 0.005 rad at both masses and every step, as
  Study 11 validated.
- On SemiImplicit the limit is read through its joint attachment; run 086 stiffens it.
