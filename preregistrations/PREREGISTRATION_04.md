# Fourth pre-registration: VBD's velocity carried, not read back from 32-bit poses

Registered 15 October 2026, after design probes (runs 006, 022, 025, 026, 029, 030, 031). Registered before any play of
this registration existed. To be played once, as run 034.

## The question

VBD reads each body's velocity back from its 32-bit poses after its solve, v = (x - x_prev) / dt, a whole number of
the poses' spacing per step, so a body high enough or a step small enough does not fall, or falls at the wrong rate
(F2; runs 006, 022). The patch in design `patches/in_design/vbd_carried_velocity_v2.diff`, with
`NEWTON_VBD_CARRIED_VELOCITY=2`, carries the velocity instead: the forward step's linear and angular velocity plus the
solve's correction, the same quantity without the cancellation. On scenes the probes did not use: does VBD as released
still fall wrong; with the patch, does it fall as Newton's other solvers do; does every reading that passes its test
without the patch still pass it; and with the switch unset, is the patched Newton the release byte for byte?

## How "nothing else gets worse" is ruled, and why

In runs 022 and 026 this check was posed against the released reading: no reading could move further from its answer
than the release's. That mis-poses it for readings the release already gets wrong for another cause, where any change
of trajectory moves a wrong value either way. The first deep dive met the same mis-posing in its G8 rule. Here it is
ruled against the right answer:

- **Every reading that passes its test without the patch must still pass it with the patch.**
- **A reading that fails its test without the patch, for another cause, may move**; its movement is reported with its
  distance from the answer, not ruled. The causes already found: VBD's hold creeps faster as the step shrinks (run 001),
  which is neither its velocity read-back (runs 022, 026) nor its warm-start decay (run 029); and VBD's joint chain
  loses energy, more at small steps, again neither (runs 025, 026, 029).

## Engines and arms

- **stock**: Newton 1.6.1 from PyPI with run 001's environment.
- **patched**: Newton v1.6.1 from source (commit 713fecd) with `vbd_carried_velocity_v2.diff` (sha256
  4e33692e4797541f...) applied, in its own environment, every dependency as stock's (run 022's).

| Arm | Engine | `NEWTON_VBD_CARRIED_VELOCITY` |
|---|---|---|
| stock | stock | unset |
| off | patched | unset |
| on | patched | 2 |

Solvers: VBD (its legacy rigid path, as released) and VBD-ALM (`rigid_compliant_alm`, which Newton 1.6 says will become
the default). The reference for the fall: SemiImplicit from stock, whose free fall is gravity's (runs 001, 006) and
whose free flight passes the refinement test T01 (run 007). Rigs as committed at this registration:
`tools/nwt_contact.py` and `tools/nwt_chain.py`. Measured by Senua AI's `sx_contact` (`gap`, `creep`, `rest`, `pull`,
`chain`) and judged by its `rule`. Warp's CPU device. Every scene at two steps no probe used: 0.2 ms and 0.05 ms.

## The scenes, registered parameters

None of these numbers was used in the probes. A cube of 1.6 kg, half-size 0.03 m.

- **The fall**: its lowest face 6 m above the ground, friction 0, 0.3 s (it falls 0.44 m and never lands). Right
  answer: gravity's fall, as SemiImplicit plays it.
- **The slide**: on the ground at 1.4 m/s, friction 0.3, 0.3 s. Test (the suite's T02): friction over the normal force
  within 1 in 100 of 3,000 per 10,000.
- **The rest**: on the ground, friction 0.3, 1 s. Test (T03): the ground's mean force within 1 in 100 of the weight,
  15,680 mN.
- **The lift**: on the ground, lifted with three times the weight (47.04 N) from 0.2 s, 0.4 s. Test (T09): the ground's
  lowest force 0 or more.
- **The hold**: on the ground, friction 0.55, pushed along x with 5.1744 N (0.6 of what friction holds) from 0.3 s,
  1 s. Test (T06): the mean speed within 10 um/s of 0.
- **The free chain** (reported only): run 014's two-link chain, no gravity, set turning, 2 s. Right answer: its
  kinetic energy kept. VBD fails it for another cause (above).

## The rules

Each judged by `sx_contact rule`, from the measured lines, and nowhere else.

| Rule | Statement | Kind |
|---|---|---|
| R1 safe when off | Every file the off arm plays is byte-identical to the stock arm's | eq (identical files, files) |
| R2 the defect is there | stock, both solvers, both steps: the fall's summed height difference from SemiImplicit's, at the 30 instants of 10 ms, at least 100,000 um | all_ge |
| R3 the fall | on, both solvers, both steps: the fall byte-identical to SemiImplicit's | eq (identical files, files) |
| R4 what passes still passes | For each of the slide, rest, lift and hold tests at both steps on both solvers (16 tests): the test is judged for the stock arm and for the on arm by its own rule lines (a hold passes when both of its lines hold); no test may hold for stock and fail for on | eq (tests held by stock and failed by on, 0) |
| R5 nothing blows up | on: no play's state stops being a number | eq (plays with nan_at_step, 0) |

The study holds if every rule holds. A rule that fails is reported as failed, with its numbers, and the patch stays in
design.

Reported, not deciding: every test the stock arm fails, with the on arm's reading and its distance from the answer;
the free chain's energy in every arm.

## The runner and its dry run

`validation/run_034_study_04/play.sh`, committed with this registration. Before the study it is played once with
`DRY=1`: the on arm only, with throwaway parameters (the suite's 2 kg cube, half-size 0.04 m, at 1.25 ms, shorter
plays), into `dry/`, only to check that it runs to the end and writes every measured line; no rule is read from it.
