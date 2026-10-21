# Run 017: why the friction patch fails the refinement chain (T08)

15 October 2026. Not registered: a reading of run 007's kept plays, no new plays, by [`read.sh`](read.sh) (pushed
before it ran); reading `reading.txt`, made with Senua AI's `sx_contact` (`gap`, `bounce`).

## The question

On the first deep dive's ten-test suite, SemiImplicit and Featherstone pass the refinement chain (T08) as released and
fail it with Study 1's friction patch (run 007). T08 reads the measure's gap between each step and the next finer one
on the chain scene: a 2 kg cube dropped 80 mm with 1.5 m/s sideways, friction 0.4, for 1 s. The summed height
difference at the 10 ms instants must fall at every refinement.

## What was read

| Gap, summed height difference (um), each step against the next finer | 1 / 2 | 2 / 4 | 4 / 8 | 8 / 16 | 16 / 32 | 32 / 64 | T08 |
|---|---|---|---|---|---|---|---|
| Chain, Featherstone as released | 7,734,224 | 1,404,959 | 361,169 | 303,202 | 95,501 | 20,620 | falls: PASS |
| Chain, Featherstone patched | 6,041,432 | 651,438 | 17,338 | **9,176** | **11,713** | 2,223 | rises once: FAIL |
| Chain, SemiImplicit patched | 7,817,885 | 569,333 | 17,138 | **9,374** | **11,730** | 2,224 | rises once: FAIL |
| The frictionless drop, both solvers, released or patched (the same files) | 3,159,783 | 31,711 | 9,156 | **5,177** | **5,932** | 1,614 | rises once |

(The steps are 10 ms over 1 to 64; SemiImplicit's drop reads 3,159,790, 31,714 and the same after.)

| The rebound after the landing, um (measure `bounce`) | 2.5 ms | 1.25 ms | 0.625 ms | 0.3125 ms | 0.156 ms |
|---|---|---|---|---|---|
| The frictionless drop, both solvers, released or patched | 92 | 830 | 1,258 | 2,011 | 2,140 |
| Chain, patched (both solvers within 2 um) | 688 | 1,482 | 2,210 | 3,565 | 3,779 |
| The chain's against the drop's | 7.5 | 1.78 | 1.76 | 1.77 | 1.77 |
| Chain, Featherstone as released | 1,111 | 17,936 | 18,918 | 19,134 | 18,931 |

## What it shows

- **The step at which T08 stops falling is 1/16 to 1/32, and it is the rebound after the landing.** With the patch
  the cube lands, slides and rises off the ground once, by 1.5 mm at 1.25 ms, 2.2 mm at 0.625 ms and 3.6 mm at
  0.3125 ms. The rebound grows most between 1/16 and 1/32, and that is where the gap rises.
- **The same happens with no friction at all.** The frictionless drop, whose files are byte-identical with and without
  the patch, rebounds 0.83, 1.26, 2.01 and 2.14 mm at the same steps, and its gap rises at the same refinement
  (5,177 to 5,932). From 1.25 ms down, the patched chain's rebound is the drop's times 1.76 to 1.78 at every step: the
  normal contact's rebound, raised by the oblique landing.
- **The cause is in Newton's normal contact, not in the patch.** Newton's body contact kernel
  (`semi_implicit/kernels_contact.py`, `eval_body_contact`) damps the normal contact only while it closes:
  `fd = min(vn, 0) * kd`. On separation the spring hands back what the damper did not take, so the contact law itself
  rebounds, with a restitution of 0. At large steps the integrator loses energy of its own and hides it; as the step
  shrinks that loss goes, and the rebound rises toward the contact law's own (2.7% of the drop at 0.156 ms, still
  rising). That is why both solvers fail the bounce test (T04) as released, patch or no patch.
- **As released, T08 passes because the friction error is larger.** The excess friction (F1) pitches the cube over and
  it leaves the ground by 18 to 19 mm; that tumble dominates the gaps, and it happens to shrink at every refinement. The
  patch removes the tumble (gaps 8 to 33 times smaller from 2.5 ms down) and exposes the contact's rebound.
- **The patch at zero slip is not involved.** Its friction is `vt / |vt| * min(kf |vt|, mu N)`, which is `kf vt` as
  the slip goes to zero: continuous, no singular direction. Where the patched chain's slide comes to a stop (360 ms to
  420 ms) its plays at 1/16 and 1/32 differ by at most 4 um.

No revision of the friction patch follows from this: what fails is Newton's normal contact. A correction of that is a
separate patch. The candidate grounded in the contact literature is damping in both phases with the normal force kept
from pulling: the linear spring-dashpot with no tension (Schwager and Poeschel, Coefficient of restitution and linear-dashpot model revisited, Granular Matter 9, 465-469, 2007), using
Newton's own `ke` and `kd`. It is not designed or played here.
