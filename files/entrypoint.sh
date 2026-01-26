#!/usr/bin/env bash
set -e -o pipefail

mkdir --parents /media/compatible-media-creator/{input,output}

if [[ -n "$CRON_SCHEDULE" ]]; then
    echo "$CRON_SCHEDULE root bash --login -c 'ENCODER_CPU=$ENCODER_CPU \
        NICENESS_ADJUSTMENT=$NICENESS_ADJUSTMENT SCHED_POLICY=$SCHED_POLICY \
        run.sh > /proc/1/fd/1 2>&1'" \
        > /media/cron/compatible-media-creator
fi

"$@"
