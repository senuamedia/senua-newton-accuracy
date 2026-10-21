# The measuring side

The measuring programs of the Senua AI Robotics Core read what a rig wrote and decide the registered rules. Every
measuring program this record ran is in this folder. They are written in Simplex, the language Senua AI is built in,
and published so that every right answer and every tolerance can be read line by line. They do not build outside
Senua AI: the Simplex toolchain and the Senua AI engine are not distributed. What they printed is kept in the run
folders under [`../validation/`](../validation/), beside the raw plays they read.

## The Senua AI engine: two calls, nothing more

The programs are plain arithmetic on the rigs' text files. Of the Senua AI engine each uses only two calls, both in its
file reader, `xc_ints`, and each is commented where it is made with what it asks for, why, and what the engine returns:

| Call | What it asks for | What the engine returns |
|---|---|---|
| `os_file_access(path)` | Whether the rig's file exists, so a missing file is never read | 0 when it exists, anything else when it does not |
| `os_file_read_all(path, meta)` | The whole file, read into a buffer of the engine's own | The buffer (0 when the file cannot be read), with the number of bytes read written into `meta`; the program frees it |

In these published files the engine is named by one include line, `// use "senua_engine.sx"`, which stands where the
program as run names the engine's helper files, and the comments say what the two calls do; no line of code differs
from the program as run.

## What is here

| File | Used by | sha256 as run | sha256 as published here |
|---|---|---|---|
| [`registered/sx_contact_before_correction.sx`](registered/sx_contact_before_correction.sx) | The record's early runs, read before the measure's correction of 17 October 2026: runs 001 to 008 and 030 re-made byte for byte with it from their kept files (21 October 2026) | 87e921cd4d2c03bf... | 3e05661d4ad7a8fd... |
| [`sx_contact.sx`](sx_contact.sx) | Runs 052 on, every study from Study 7: as corrected, with `fastest` | b1047b84134afc4f... | c3f69ccd64a3db5a... |
| [`runners/sx_contact_suite.sh`](runners/sx_contact_suite.sh) | The runs that play the contact suite ([`../tools/contact_suite.sh`](../tools/contact_suite.sh)) and read its T-numbered verdicts, among them Studies 7, 8, 15 and 16 (runs 052, 053, 088 and 100): every play of one label read by `sx_contact` | 553d46ecdaf2bd95... | 161586e543ba6e69... |

The build of the program before the correction carried one reading more, `pairg` (the SuperDex record's twenty-third
registration), which the early runs do not use; with or without it they read the same. The correction (the step read
in whole microseconds, and the distance slid) is described in the SuperDex record's `measure/README.md`; of the early
runs' readings it changes the 9 `stop` lines [the audit](../docs/audit.md) lists, which the program as published here
re-makes as the record has them. The Newton host's build of the corrected program (sha256 of the binary
b1d1b2906041219e...) read runs 052 to 063; a laptop build of the same source made every reading and every check of
runs 054 to 063 again, byte for byte, 20 October 2026. [`SHA256SUMS`](SHA256SUMS) lists the published files.

`sx_contact` and its suite runner were written for the first deep dive, Meta's SuperDex Physics, and are published
there too (`measure/` in [senuamedia/senua-superdex-accuracy](https://github.com/senuamedia/senua-superdex-accuracy)),
where the same programs carry the same code. Their header comments name that record's registrations and rigs (its
`sdx_contact` and the others); this record's rigs in [`../tools/`](../tools/) write the same file format, one line a
step, so the same readings apply.

## The readings this record uses

Each takes a rig's file and holds it to an answer that does not depend on the time step:

| Reading | What it reads | The right answer |
|---|---|---|
| `creep` | A cube pushed with less than friction can hold; a body that should stay still | Its mean speed over the second half of the play: 0, it holds |
| `stop` | A cube that slides to a stop | Where it stopped: Coulomb's distance, v^2 / (2 mu g) |
| `accel` | A cube decelerating over a window of the play | The deceleration Coulomb's law gives, mu g |
| `final` | Any play | Its last state: a position, an angle, a speed, a depth |
| `fastest` | Any play, over its last steps | The largest speed there: a body at rest has none faster than the rule's bound |
| `bounce`, `impact`, `settle`, `rest`, `pull` | A cube dropped, landing obliquely, set down, lifted | A rebound that does not depend on the step; Coulomb's friction over an impact and after it; the weight carried |
| `gap`, `pairg` | Two bodies coupled; two cubes that both move | The largest gap between their motions; momentum kept between them (`pairg`, each mass in whole grams) |
| `chain`, `swing` | Two arms on two joints; one swinging | Energy and angular momentum kept with nothing doing work; the swing comes back |
| `rule` | One registered rule and its numbers | Whether it held |

## Its range

Its readings multiply whole numbers directly, which is exact while every product stays below 2^47 on x86-64 and below
2^31 on arm64 (the Simplex backends' limits). Every reading the record makes is made on x86-64 (the audit re-reads
arm64 replays there for this reason), and a play whose energies grow past the range reads as nonsense: XPBD's chain at
full relaxation, which diverges, was misread once as departing by 274 ppm (run 125's notes, corrected 21 October 2026).
