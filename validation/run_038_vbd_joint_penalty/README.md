# Run 038: VBD's jointed-chain error at small steps, against its joint penalty

15 October 2026, 10:14 to 10:33 UTC, on the Newton host, by [`play.sh`](play.sh), whose hypothesis and predictions
were pushed before the plays. Not registered: a trace. Run 026's patched source (switch `2`: the validated carried
velocity; `0`: unset). Reading `reading.txt`, made with Senua AI's `sx_contact chain`, re-made byte for byte on the
laptop from the same files. In the logs the home folder is written `~/`.

## The question

With the validated carried velocity (Study 4) run 014's free chain gains 45% of its energy in 2 s on VBD at 0.05 ms (it
loses 8% as released). Runs 025, 026 and 029 ruled out the velocity read-back and the warm-start decay. Read in the
source, VBD's legacy path holds a joint with a penalty that starts at `rigid_joint_linear_k_start` (100 N/m) and
`rigid_joint_angular_k_start` (10 N m/rad) and does not ramp by default, against an inertia term m / h^2 that grows as
1 / h^2. The hypothesis: that unramped penalty is the cause.

| The free chain at 0.05 ms, energy after 2 s per million of the start (1,000,000) | With the carried velocity | Without |
|---|---|---|
| VBD, its defaults (Study 4's play, byte for byte) | 1,451,104 | 915,739 |
| VBD, the penalty started at its structural cap (1e5) | 1,451,104 (the same file) | 915,739 (the same file) |
| VBD, 40 iterations | 1,503,880 | 930,984 |
| VBD-ALM, the penalty started at its cap | 1,089,095 (Study 4's play) | |
| VBD-ALM, 40 iterations | 1,186,359 | |
| VBD at 0.2 ms, the penalty at its cap | 983,503 (Study 4's at 0.2 ms) | |

| Prediction | Result |
|---|---|
| P1: with the penalty started at its cap the chain keeps its energy within 2 in 100, with and without the carried velocity | **Failed**: every such play is the default's byte for byte |
| P2: 40 iterations move the energy less than the penalty's cap does | **Failed**: the cap moves nothing; 40 iterations move it by 5 in 100 |

No play stopped being a number.

## What it shows

- **The hypothesis is refuted:** the penalty's starting value plays no part in these plays (they are the defaults'
  files), and more iterations move the chain's energy a little further from the answer, not toward it.
- VBD's error at small steps is not its velocity read-back (runs 025, 026), nor its warm-start decay (run 029), nor its
  joint penalty's start (this run). The next candidate is the structural joint stiffness itself
  (`rigid_joint_linear_ke` and `rigid_joint_angular_ke`, 1e5), which a small step resolves rather than damps.
