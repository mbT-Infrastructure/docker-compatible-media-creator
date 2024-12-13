#!/usr/bin/env bash
set -e -o pipefail

INPUT_DIR=/media/compatible-media-creator/input
MAX_WIDTH_WITHOUT_REENCODE=1280
OUTPUT_DIR=/media/compatible-media-creator/output
TMPDIR=/media/workdir

export TMPDIR

echo "Starting compatibility version creation"

INPUT_FILES="$(find "$INPUT_DIR" -type f \
    | grep --extended-regexp '\[.*\].(mkv|mp4)$' || true)"
OUTPUT_FILES="$(find "$OUTPUT_DIR" -type f \
    | sed "s/- 1080p h264 [.*]\.\(mp4\|mkv\)$//")"
MISSING_FILES="$(grep --invert-match --fixed-strings \
    --file=<(sed 's/^/^/' <<< "$OUTPUT_FILES") <<< "$INPUT_FILES" || true)"

while read -r INPUT_FILE; do
    if [[ ! -f "$INPUT_FILE" ]]; then
        continue
    fi

    FFPROBE_OUTPUT="$(ffprobe -v error -show_entries \
        stream=index,codec_name,codec_type,width,height \
        -print_format compact "$INPUT_FILE")"

    VIDEO_STREAM="$(grep --extended-regexp '|codec_type=video|' <<< "$FFPROBE_OUTPUT" \
        | head --lines 1)"

    grep --silent --extended-regexp '|codec_name=h264|' <<< "$VIDEO_STREAM" \
        || continue

    VIDEO_WIDTH="$(sed 's/^.*|width=\([^|]*\)|.*$/\1/' <<< "$VIDEO_STREAM")"
    [[ "$VIDEO_WIDTH" -gt "$MAX_WIDTH_WITHOUT_REENCODE" ]] || continue

    RELATIVE_DIR="$(dirname "${INPUT_FILE#"${INPUT_DIR}/"}")"
    mkdir --parents "${OUTPUT_DIR}/$RELATIVE_DIR"
    echo TARGET_DIR="${OUTPUT_DIR}/$RELATIVE_DIR"
    create-compatibility-version.sh --output "${OUTPUT_DIR}/$RELATIVE_DIR" "$INPUT_FILE"
done <<< "$MISSING_FILES"
