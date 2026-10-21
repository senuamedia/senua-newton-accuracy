# Run 104: VBD's spinning body against its iterations (issue 13)

Not registered: a design probe that decides nothing and states no prediction. Run 074 found the centre of a body
spinning about a centre of mass off its origin, touching nothing, drifting on VBD and VBD-ALM faster as the step shrinks
(3,751 um/s at 0.125 ms), and Study 4's carried velocity cutting the drift twentyfold without removing it (162 um/s).
VBD's forward step is the integration SemiImplicit uses, which keeps this centre within 3 um/s (run 030); VBD then
iterates its solve on the poses. Here run 074's spinning body on VBD and VBD-ALM, as released and with the carried
velocity, at 1, 10 (the default) and 40 iterations, at 2, 0.5 and 0.125 ms: does the drift follow the iterations?

## What it measured

Played 20 October 2026 on the Newton host (`started.txt`, `finished.txt`); each play's reading in `measured.txt`.

| Centre's mean speed, um/s | 1 iteration: 2, 0.5, 0.125 ms | 10 (default): 2, 0.5, 0.125 ms | 40: 2, 0.5, 0.125 ms |
|---|---|---|---|
| As released | 6, 187, -2,022 | 19, 133, -3,751 | 19, 133, -3,751 |
| With the carried velocity | 1, 110, 1,086 | -1, 51, 162 | -1, 51, 162 |

- **The drift does not follow the iterations past the default**: at 40 every play is byte for byte the play at 10, on
  both paths, so the solve has converged and the drift is in what it converges to, not in a solve left unfinished. One
  iteration moves it either way.
- **VBD and VBD-ALM play byte for byte alike** here: the body touches nothing, so their contact paths play no part.
- The carried velocity cuts the drift twentyfold at 0.125 ms and leaves 162 um/s. With nothing acting on it the
  solve's answer is the forward step's own pose, SemiImplicit's integration, which keeps this centre within 3 um/s
  (run 030); what remains is how the solve updates and stores that pose, in 32 bits, about the body's origin rather than
  its centre: a rounding of the turn about an origin 30 mm from the centre moves the centre. Not traced further here.
