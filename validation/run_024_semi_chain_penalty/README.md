# Run 024: why SemiImplicit cannot play the two-link chain

15 October 2026, on the Newton host, by [`play.sh`](play.sh), whose hypothesis and predictions were pushed before
the plays. Not registered: a trace. Newton 1.6.1 from PyPI. Reading `reading.txt`, made with Senua AI's
`sx_contact chain` and the rig's own statistics lines (`out_of_range_at_step`, as in run 014), re-made byte for byte
on the laptop from the kept files.

## The question

In [run 014](../run_014_chain/README.md) SemiImplicit blew up on the free two-link chain at every step played, from
the 7th step at 10 ms to after 0.40 s at 0.156 ms (F10). SemiImplicit holds a joint together with an explicit
penalty between the joint's two anchor points, `joint_attach_ke` 10,000 N/m and `joint_attach_kd` 100 N s/m by
default (`kernels_body.py`, `eval_body_joints`), applied at the anchors, so it also turns the arms. Is the blow-up
that penalty past its explicit limit?

## The hypothesis

Across an arm, the mass a joint's anchor sees is m_eff = 1 / (1 / m + l^2 / I), l the anchor's distance from the
arm's centre: 20.1 g for run 014's first arm at the fixed joint, and 8.8 g at the joint between the arms (both arms in
series). An explicit damper is stable only while h kd / m_eff < 2, and with the spring the critical step is
(2 / w)(sqrt(1 + z^2) - z), w^2 = ke / m_eff, z the damping ratio (Belytschko, Liu and Moran, Nonlinear Finite
Elements for Continua and Structures, Wiley 2000, sections 6.2 and 6.6): 0.17 ms at the joint between the arms, where
h kd / m_eff is 1.8 at run 014's finest step (the blow-up there came late), and 0.40 ms at the fixed joint. With
`joint_attach_kd` 0, the spring alone is stable to 1.9 ms. The joint's swing penalty (ke on the angle out of the
hinge's plane) is stable only to 0.41 ms, but the chain moves in its plane, so only rounding can excite it.

## What was played

Run 014's free chain (arms of 1.2 and 0.6 kg, half-size 0.04 m, the joints 0.5 m apart, no gravity, set turning at
2.5 and 1.5 rad/s, 2 s) on SemiImplicit, its defaults but where named.

| SemiImplicit, the free chain | h kd / m_eff between the arms | Result | Kinetic energy after 2 s, per million of the start | Angular momentum, change, ppm |
|---|---|---|---|---|
| Run 014, 10 ms to 0.156 ms, as released | 114 to 1.8 | leaves the range at every step | | |
| 0.3125 ms, as released | 3.6 | **leaves the range at step 38** | | |
| 0.078125 ms, as released | 0.89 | **plays its 2 s** | 989,288 | -852 |
| 0.0390625 ms, as released | 0.44 | **plays its 2 s** | 989,387 | -824 |
| 0.3125 ms, `joint_attach_kd` 0 | 0 | **plays its 2 s** | 997,620 | -554 |
| 0.625 ms, `joint_attach_kd` 0 | 0 | plays its 2 s | 997,604 | -559 |

| Prediction | Result |
|---|---|
| P1: at 0.078 and 0.039 ms the chain plays its 2 s | Held |
| P2: at 0.3125 ms it leaves the range within a few hundred steps, and with `joint_attach_kd` 0 it plays its 2 s | Held (step 38) |
| P3: at 0.625 ms with `joint_attach_kd` 0 it still leaves the range, if rounding excites the swing | **Failed**: it plays its 2 s; nothing out of the hinge's plane was excited |

## What it shows

- **F10 is SemiImplicit's joint penalty past its explicit limit.** The chain plays wherever the step is inside the
  damper's limit at the joint between the arms (h kd / m_eff 0.89 and 0.44) and blows up where it is outside (3.6,
  and run 014's every step); take the damper away and it plays at 0.3125 and 0.625 ms, steps at which it blew up with
  it. The limit is set by the arms' inertia seen at the joint, 8.8 g here: an arm-shaped body needs a step under
  about 2 m_eff / kd, 0.17 ms for this chain with Newton's default kd.
- **Where it plays, the penalty joint takes energy of its own.** At 0.078 and 0.039 ms the chain keeps 98.93% and
  98.94% of its kinetic energy after 2 s: the same at both steps, so not the integrator's error, which would halve,
  but the damped soft joint's own loss. With kd 0 it keeps 99.76% at both steps. A free chain's right answer is
  100%; Featherstone and the MuJoCo solver, which hold joints exactly, gain energy at large steps and converge on it
  (run 014).
- The out-of-plane swing penalty was never excited in plane motion, so its own limit was not tested here.
