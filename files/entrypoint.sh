#!/usr/bin/env bash
set -e -o pipefail

mkdir --parents /media/compatible-media-creator/{input,output}

echo "$CRON root bash --login -c 'ENCODER_CPU=$ENCODER_CPU run.sh > /proc/1/fd/1 2>&1'" \
    > /media/cron/compatible-media-creator

exec /entrypoint-cron.sh "$@"
