# Run 079: SemiImplicit's limit kept from pulling, on a scene it can play (issue 16)

Not registered: a design probe that decides nothing and states no prediction. Run 077 could not measure SemiImplicit's
limit: with its default joint attachment the strike's arm leaves the rig's range before it reaches the limit (issue
10). Here the same strike with `joint_attach_kd=0` (Study 9's configuration for SemiImplicit's joints), as released
and with `NEWTON_SEMI_JOINT_LIMIT=1`, at 0.1 and 1 kg and three steps, beside Featherstone released and with its
limit patch's `=1`. The spring and damper kept from pulling turn the arm back at -0.815 and -0.450 rad (run 042).

## What was found

Played 20 October 2026 on the second x86-64 host, from the record at 0d58043 (`measured.txt`).

- **With `joint_attach_kd=0` SemiImplicit still cannot play the strike at 0.25 ms** (0.1 and 1 kg leave the rig's
  range at steps 1,181 and 1,418) **or at 0.0625 ms for 0.1 kg** (step 4,733): the attachment's angular spring acts on
  the link's own small inertia, about 1e-4 kg m^2, its explicit bound near 0.2 ms.
- **Where it plays, the arm is thrown about by the undamped attachment** (632 turns in 2 s at 0.0625 ms on 1 kg, its
  angle between -0.07 and -1.0 rad), so where it turns back after a strike cannot be read.
- **The limit kept from pulling changes nothing**: every SemiImplicit play is byte for byte the release's with
  `NEWTON_SEMI_JOINT_LIMIT=1`. Featherstone beside it: as released -0.890, -0.913, -0.904 rad (0.1 kg) and -0.484,
  -0.484, -0.481 rad (1 kg); with its limit patch's `=1`, -0.805, -0.826, -0.817 and -0.450, -0.456, -0.454 rad, the
  no-tension form's -0.815 and -0.450, at the three steps.
- Issue 16 on SemiImplicit waits on its joint attachment, which a strike cannot be read through.
