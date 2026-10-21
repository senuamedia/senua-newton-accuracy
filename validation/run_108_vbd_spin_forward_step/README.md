# Run 108: VBD's spinning body with its solve left out (issue 13)

Not registered: a design probe that decides nothing and states no prediction. [Run 104](../run_104_vbd_spin_iterations/README.md)
found the drift of VBD's spinning body the same at 10 and 40 iterations, the solve converged, and 162 um/s at 0.125
ms with the carried velocity. VBD's forward step is SemiImplicit's integration, which keeps this centre still; with no
iterations VBD's step is that forward step and its velocity read-back alone. Here run 074's spinning body on VBD and
VBD-ALM, as released and with the carried velocity, at 0, 1 and 10 iterations, at 2, 0.5 and 0.125 ms, beside
SemiImplicit: which part of VBD's step moves the centre?

## What it measured

Played 20 October 2026 on the Newton host (`started.txt`, `finished.txt`); each play's reading in `measured.txt`.

| Centre's mean speed, um/s, at 2, 0.5, 0.125 ms | 0 iterations | 1 | 10 (default) |
|---|---|---|---|
| VBD and VBD-ALM, as released | 18, -150, -1,097 | 6, 187, -2,022 | 19, 133, -3,751 |
| VBD and VBD-ALM, with the carried velocity | 0, 0, 0 | 1, 110, 1,086 | -1, 51, 162 |
| SemiImplicit | 0, 0, 0 | | |

- **VBD's step without its solve keeps the centre still** once its velocity is carried rather than read back: at 0
  iterations, with the carried velocity, VBD's play is SemiImplicit's byte for byte at every step (3 of 3), the centre still.
  As released the velocity read back from 32-bit positions moves it (1,097 um/s at 0.125 ms, Study 4's cause).
- **The solve moves it**: with the carried velocity, one iteration moves the centre at 1,086 um/s at 0.125 ms and ten
  at 162 (run 104: converged by ten). The body touches nothing, so the solve's only term is the inertial one, which at
  its first iteration is computed from the very pose the forward step wrote: its increment should be zero. Its
  rotational residual is the rotation of the current orientation's inverse times the inertial target read back as an
  axis and an angle, in 32 bits; whether that returns exactly zero, and how a turn it makes moves the centre the
  carried velocity then carries, is the next thing to read in the source. VBD and VBD-ALM play alike throughout.
