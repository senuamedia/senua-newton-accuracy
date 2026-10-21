# Run 042: the MuJoCo limit patch's damping at light masses, against the step

15 October 2026, 10:37 to 10:41 UTC, on the Newton host, by [`play.sh`](play.sh), whose hypothesis and prediction were
pushed before the plays. Not registered: a trace. Run 039's patched source, its switch set. Reading `reading.txt`,
made with Senua AI's `sx_contact swing`, re-made byte for byte on the laptop from the same files. In the logs the home
folder is written `~/`.

## The question

With the patch in design (run 039) the MuJoCo solver's limit goes as deep as Featherstone's, but the light arms turn
back higher: -0.804 rad against -0.890 at 0.1 kg and -0.448 against -0.484 at 1 kg, at 0.25 ms. The hypothesis: that is
the step's discretization of MuJoCo's damper, and it shrinks as the step does.

| Where the arm turns back after the strike, rad | 0.1 kg | 1 kg |
|---|---|---|
| The MuJoCo solver with the patch, 0.25 ms (run 039) | -0.804 | -0.448 |
| The same, **0.0625 ms** | **-0.824** | **-0.454** |
| Featherstone, 0.25 ms (run 036) | -0.890 | -0.484 |
| Featherstone, 0.0625 ms | -0.913 | -0.484 |
| The spring and damper given, pulling at the end of the strike (run 036's closed form) | -0.90 | -0.48 |
| **The same spring and damper kept from pulling** (Schwager and Poeschel 2007) | **-0.815** | **-0.450** |

| Prediction | Result |
|---|---|
| P1: with the patch at 0.0625 ms the turn within 0.02 rad of Featherstone's at the same step | **Failed**: 0.089 and 0.030 rad higher, as at 0.25 ms |

## What it shows

- **The difference is not the step but whether the limit can pull.** A limit is one-sided: MuJoCo's constraint force
  cannot pull the arm back into the limit, while Newton's `joint_force`, which Featherstone plays, applies the damper
  until the angle is back at the limit, pulling as the arm leaves. For the linear spring-dashpot kept from pulling
  (Schwager and Poeschel, Granular Matter 9, 465-469, 2007), with damping ratio z the speed kept is
  exp(-(z / sqrt(1 - z^2)) (pi - arctan(2 z sqrt(1 - z^2) / (1 - 2 z^2)))): with Newton's ke and kd that gives the
  turns -0.815 and -0.450 rad, which the MuJoCo solver with the patch reads within 0.011 and 0.004 rad at both steps.
- **So the patch gives MuJoCo exactly the limit Newton gives it, as a limit that cannot pull.** Featherstone's limit
  pulls at the end of each strike (new finding F16): a contact kept from pulling is the one the record validated in
  Study 3.
