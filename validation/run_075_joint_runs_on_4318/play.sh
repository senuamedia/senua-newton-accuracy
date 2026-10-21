#!/usr/bin/env bash
# Run 075: runs 056 (a joint's velocity and effort limits), 062 (a driven joint at rest, issue 27's reports' scenes) and
# 063 (a loop-closing joint) played again unchanged, each by its own play.sh in a scratch copy of the record, with pull
# request #4318 and the speed-floor patch first on the path (run 065's pr4318_nofloor engine, NEWTON_XPBD_NO_SPEED_FLOOR=1)
# for every solver, a design probe that decides nothing and states no prediction: what #4318 changes on issues 19 and 27
# beyond XPBD's drive. Each run's readings and checks are kept here beside the record's (readings/<run>_*).
# usage: play.sh <sx_contact binary> <engine folder>   (repository root; the engine folder made by run 065's setup_engine.sh)
set -u
B="$(cd "$(dirname "${1:?usage: play.sh <sx_contact binary> <engine folder>}")" && pwd)/$(basename "$1")"; E="$(cd "${2:?}" && pwd)"
O=validation/run_075_joint_runs_on_4318; ROOT=$(pwd); mkdir -p $O/readings
date -u +%FT%TZ > $O/started.txt
for r in run_056_joint_velocity_effort_limits run_062_rest_reports_scenes run_063_loop_joint; do
  ( X=$(mktemp -d); git archive --format=tar HEAD | tar xf - -C $X; cd $X
    rm -rf validation/$r/runs validation/$r/stats validation/$r/err
    export NEWTON_XPBD_NO_SPEED_FLOOR=1
    STOCK_VENV=$E/pr4318_nofloor bash validation/$r/play.sh "$B" > $ROOT/$O/readings/${r%%_[a-z]*}_out.txt 2>&1
    for f in reading.txt checks.txt measured.txt rules.txt; do [ -f validation/$r/$f ] && cp validation/$r/$f $ROOT/$O/readings/${r%%_[a-z]*}_$f; done
    cd $ROOT; rm -rf $X ) &
done
wait
date -u +%FT%TZ > $O/finished.txt
grep -rlIF "$HOME" $O 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
for f in $O/readings/*_checks.txt; do echo "$f: $(tail -1 $f)"; done
