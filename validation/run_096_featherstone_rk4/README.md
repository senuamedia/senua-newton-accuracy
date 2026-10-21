# Run 096: Featherstone's step as the classic Runge-Kutta scheme (issue 11)

Not registered: a design probe, its predictions pushed with [`play.sh`](play.sh) before any play. Newton 1.7.0 from
PyPI, and the same with Senua AI's Featherstone RK4 patch in design first on the path
([`featherstone_rk4_on_1.7.0.diff`](../../patches/in_design/featherstone_rk4_on_1.7.0.diff), sha256 af3664356c9db9e3...,
switch `NEWTON_FEATHERSTONE_RK4=1`).

## The patch

Featherstone integrates the joints by semi-implicit Euler; its joint-space inertia depends on the configuration, so
the scheme is not symplectic, and a free chain's energy drifts in proportion to the step (issue 11, F8: 9.7% gained in
2 s at 10 ms, run 014). On the MuJoCo solver its own RK4 keeps the chain within 5 ppm
([Study 9](../../docs/studies/09-newtons-own-options.md)). The patch makes Featherstone's step in four stages as MuJoCo
makes its RK4 (`mj_RungeKutta`): each stage's joint accelerations are the stock step's own, evaluated at the stage's
coordinates and speeds (the stock step called on a scratch state); a stage's coordinates are the step's start moved
along a weighted sum of the stages' speeds, by Featherstone's own joint integration with no acceleration, its speeds
the start's plus the weighted accelerations; the step ends at the start moved along the stages' speeds weighted 1/6,
1/3, 1/3 and 1/6. Contacts are those given for the step, as in the stock step. It applies to steps with no gradients,
observables, particles, kinematic joints, joint mimics or free joints below another joint; any other step is the
stock one.

## What is played

On Featherstone as released (`stock`), the patched tree with the switch unset (`off`) and set (`rk4`), Featherstone's
angular damping set to 0 (its default, 0.05, damps the chain): Study 9's free chain (no gravity; 0.7 and 1.3 kg,
turning at 2.2 and -1.1 rad/s) at 10, 8, 2, 0.5 and 0.125 ms; a swinging chain under gravity (0.9 and 0.6 kg, released
at rest at 0.3 and 0.8 rad, a double pendulum) at 10, 2.5 and 0.5 ms; the free chain at Featherstone's default angular
damping at 2 ms; the contact suite as released and with RK4.

## Predictions (pushed before the plays)

| Check | Prediction |
|---|---|
| C0 | `off` byte for byte the release in every play; every `rk4` play a number |
| C1 | With RK4 the free chain's kinetic energy and its angular momentum within 5 ppm of their start at every step |
| C2 | With RK4 the swinging chain's total energy within 100 ppm of its start at every step |
| C3 | With RK4 the contact suite loses no verdict that passes as released |

Reported: the release's drift, the damped chain, every verdict.

## What it found

Played 20 October 2026 on the Newton host (`started.txt`, `finished.txt`); the measured lines in `measured.txt` (each
chain's energy drift at its end and its largest, and its angular momentum's drift, in ppm), the checks in
[`checks.txt`](checks.txt), the suites under `suites/`. **3 of 6 checks held.**

| Check | Result |
|---|---|
| C0 | Held: `off` 9 of 9 byte for byte the release; every `rk4` play a number |
| C1 | Energy **failed** at the smallest step: its largest drift 2, 1, 2, 4 and 14 ppm at 10, 8, 2, 0.5 and 0.125 ms; momentum held: 0, 0, 0, 1 and 2 ppm |
| C2 | **Failed** at 10 ms: the swinging chain's largest drift 2,225 ppm; 7 and 3 ppm at 2.5 and 0.5 ms |
| C3 | **Failed**: two verdicts lost, T01 and T08 (below) |

| Chain | Step | As released: drift at the end, largest | With RK4 |
|---|---|---|---|
| Free | 10 ms | 41,220, 41,863 ppm | -2, 2 ppm |
| Free | 2 ms | 9,322, 9,323 ppm | 0, 2 ppm |
| Free | 0.125 ms | 612, 613 ppm | 5, 14 ppm |
| Swinging | 10 ms | -112,334, 167,443 ppm | -1,863, 2,225 ppm |
| Swinging | 2.5 ms | -296,542, 296,542 ppm | -6, 7 ppm |
| Swinging | 0.5 ms | -8,389, 11,411 ppm | 2, 3 ppm |

- **RK4 keeps the free chain's energy** within 4 ppm from 10 to 0.5 ms, where as released it gains 4.1% at 10 ms and
  0.24% at 0.5 ms, and its angular momentum within 2 ppm at every step (as released 2.8% at 10 ms). At 0.125 ms, 16,000
  steps, its largest drift is 14 ppm (5 at the end): Featherstone keeps its joints in 32 bits, so a longer play gathers
  more rounding; as released the drift there is 613 ppm.
- **The swinging chain** is kept within 7 ppm at 2.5 ms and 3 at 0.5 ms; at 10 ms it departs 2,225 ppm, 318 times the
  2.5 ms drift for a step four times longer, the fourth-order scheme's own error (4^4 = 256); as released it departs
  11% at 10 ms and 30% at 2.5 ms.
- **The suite**: RK4 passes T04, the bounce no longer depending on the step (spread 417 per 10,000 of the drop, within
  500; as released 16,925), and loses T01 and T08. T01 asks that a free fall's error halve as the step halves, a
  first-order scheme's signature: RK4 integrates a free fall exactly, and its gaps between steps are 88, 129, 116, 713,
  3,637 and 6,285 um summed over the 100 instants compared (the largest 2 um), rounding that grows with the steps,
  where as released they halve from 1,237,356. T08's refinement chain, a drop with a sideways speed, falls from 288,007
  to 543 but rises once, from 35,404 to 63,815 at the fourth halving; as released it falls from 7,734,224 to 20,620 at
  every halving, each of RK4's gaps below the release's at the same halving.
- The free chain at Featherstone's default angular damping (0.05) at 2 ms plays byte for byte as with it at 0, as
  released and with RK4.
