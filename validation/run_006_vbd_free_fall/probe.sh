#!/usr/bin/env bash
# Run 006, design probe (not registered): run 001 found VBD's free fall wrong in a way that grows as the step shrinks
# (9,801 mm/s2 at 2 ms, 9,775 at 0.5 ms, 9,536 at 0.125 ms, 15,258 at 0.031 ms), and the pattern fit positions held in
# 32-bit floats: a step's fall, g dt^2, against the spacing of 32-bit numbers near the cube's height. If that is the
# cause, the error depends on the height at which the cube falls, whatever else is the same: the spacing near 0.06 m is
# 3.7 nm, near 0.15 m 14.9 nm, near 1.05 m 119 nm, near 10.05 m 954 nm, and at 0.031 ms a step's fall is 9.6 nm, at
# 0.125 ms 153 nm. Written before the plays. The cube falls freely for 50 ms from four heights at the two steps, on VBD
# and VBD-ALM, and on XPBD for reference; the reading is the mean acceleration over the 50 ms, from the rig's files.
# usage: probe.sh      (from the repository root, Newton's Python environment on; writes the reading)
set -u
T="python tools/nwt_contact.py"; O=validation/run_006_vbd_free_fall; W=$O/runs; mkdir -p $W
for s in vbd vbd_alm xpbd; do
  for h0 in 0.01 0.1 1 10; do
    for dt in 0.000125 0.00003125; do
      $T $W/fall_${s}_${h0}_$dt.txt dt=$dt h0=$h0 mu=0.5 secs=0.05 solver=$s
    done
  done
done > $W/stats.txt 2> $W/log.txt
for s in vbd vbd_alm xpbd; do
  for h0 in 0.01 0.1 1 10; do
    line="$s, lowest face $h0 m above the ground (centre $(awk -v h=$h0 'BEGIN { print h + 0.05 }') m)"
    for dt in 0.000125 0.00003125; do
      f=$W/fall_${s}_${h0}_$dt.txt
      line="$line | $dt: $(awk -v dt=$(head -1 $f | awk '{print $3}') 'FNR > 1 { v = $4; n = $1 + 1 } END { printf "%d mm/s2", -v * 1e6 / (n * dt) }' $f)"
    done
    echo "$line"
  done
done
