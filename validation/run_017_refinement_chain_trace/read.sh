#!/usr/bin/env bash
# Run 017, a reading of kept plays (not registered, no new plays): why SemiImplicit and Featherstone fail the
# refinement chain (T08) with Study 1's friction patch on and pass it without (run 007). The suite's T08 reads the
# measure's gap between each step and the next finer one on the chain scene (a cube dropped 80 mm with 1.5 m/s
# sideways, friction 0.4): the summed height difference at the 10 ms instants must fall at every refinement. Here the
# same gap is read on run 007's chain plays and on its frictionless drops (the same drop, no friction: those files are
# byte-identical with and without the patch), and the measure's bounce reads the rebound after each landing.
# usage: read.sh <sx_contact binary>   (from the repository root; writes validation/run_017_refinement_chain_trace/reading.txt)
set -u
B="${1:?usage: read.sh <sx_contact binary>}"
O=validation/run_017_refinement_chain_trace
{
  for scene in chain drop; do
    for l in featherstone featherstone_patched semi semi_patched; do
      for k in 1 2 4 8 16 32; do
        echo "gap $scene $l 1/$k against 1/$((k * 2)) | $("$B" gap 10000000 suites/1/$l/${scene}_$k.txt suites/1/$l/${scene}_$((k * 2)).txt | tail -1)"
      done
    done
  done
  for scene in chain drop; do
    for l in featherstone featherstone_patched semi semi_patched; do
      for k in 1 2 4 8 16 32 64; do
        echo "bounce $scene $l 1/$k | $("$B" bounce suites/1/$l/${scene}_$k.txt | tail -1)"
      done
    done
  done
  for l in featherstone semi; do
    n=0; same=0
    for k in 1 2 4 8 16 32 64; do
      n=$((n + 1)); cmp -s suites/1/$l/drop_$k.txt suites/1/${l}_patched/drop_$k.txt && same=$((same + 1))
    done
    echo "CHECK $l drop, patched against released: $same of $n files byte-identical"
  done
} > $O/reading.txt
