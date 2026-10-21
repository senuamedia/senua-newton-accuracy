# Run 086: SemiImplicit's limit with a stiff joint attachment (issue 16)

Not registered: a design probe that decides nothing and states no prediction. Run 084 found SemiImplicit's strike on
heavy arms governed by its soft joint attachment (joint_attach_ke 1e4 N/m stretches about 5 cm under the limit's
reaction, and its damper takes the strike's energy): the 5 kg arm barely rebounds (-1.014 rad against -0.229). Here
the same strikes with joint_attach_ke 1e6, inside its explicit bounds at 0.25 and 0.0625 ms for these arms, as
released and with the limit kept from pulling, beside Featherstone: does SemiImplicit's limit then show its pull?

## What was found

Played 20 October 2026 on the Newton host, from the record at 249f272 (`measured.txt`). Every play a number throughout.

| Where the arm turns back, rad | 5 kg: 0.25 ms | 0.0625 ms | 2 kg: 0.25 ms | 0.0625 ms |
|---|---|---|---|---|
| SemiImplicit as released, attachment 1e6 | **-0.228** | **-0.231** | **-0.348** | **-0.341** |
| SemiImplicit, the limit kept from pulling | -0.223 | -0.224 | -0.330 | -0.327 |
| Featherstone as released | -0.242 | -0.241 | -0.360 | -0.360 |
| Featherstone, `=1` | -0.234 | -0.234 | -0.345 | -0.345 |
| The no-tension spring-dashpot | -0.229 | | -0.340 | |

- **With its attachment stiff enough to be a joint, SemiImplicit's strike is its limit's**, and as released it turns
  the arm back within 0.008 rad of the no-tension form at both masses and steps (within 0.002 at 0.0625 ms). The limit's
  pull is there in its law (the release turns 0.005 to 0.018 rad lower than the no-pull form), but on SemiImplicit what
  is left of the attachment's compliance returns about as much: kept from pulling, it turns back 0.006 to 0.013 rad
  above the form.
- **On SemiImplicit issue 16 shows no departure beyond the record's 0.02 rad**, the joint stiff enough to be one; with
  the default attachment (1e4 N/m) the strike is the soft joint's (run 084), a configuration of SemiImplicit's joints.
