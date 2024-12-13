#!/usr/bin/env bash
set -e -o pipefail

INPUT_FILES=()
OUTPUT_DIR=""
WORKING_DIR="${TMPDIR:-/tmp}/temp-$(basename "$0")-$(cat /proc/sys/kernel/random/uuid)"

function cleanup {
    rm -f -r "$WORKING_DIR"
}
trap cleanup EXIT

# Check arguments
while [[ -n "$1" ]]; do
    if [[ "$1" == "--output" ]]; then
        shift
        OUTPUT_DIR="$1"
    else
        INPUT_FILES+=( "$(realpath "$1")" )
    fi
    shift
done

if [[ -z "$OUTPUT_DIR" ]]; then
    echo "OUTPUT_DIR is not set"
    exit 1
fi

mkdir "$WORKING_DIR"
cd "$WORKING_DIR"

for INPUT_FILE in "${INPUT_FILES[@]}"; do
    rm -rf ./*
    echo "Processing \"$INPUT_FILE\""
    FFPROBE_OUTPUT="$(ffprobe -v error -show_entries \
        stream=index,codec_name,codec_type:stream_tags=language:disposition=visual_impaired \
        -print_format compact "$INPUT_FILE")"
    VIDEO_CODEC="$(grep --extended-regexp '|codec_type=video|' <<< "$FFPROBE_OUTPUT" \
        | head --lines 1 \
        | sed 's/^.*|codec_name=\([^|]*\)|.*$/\1/')"
    AUDIO_CODEC="$(grep '|codec_type=audio|' <<< "$FFPROBE_OUTPUT" \
        | head --lines 1 \
        | sed 's/^.*|codec_name=\([^|]*\)|.*$/\1/')"
    STREAMS_TO_REMOVE="$(grep --extended-regexp '\|codec_type=(audio|subtitle)\|' \
        <<< "$FFPROBE_OUTPUT" \
        | grep --extended-regexp --invert-match \
            '\|disposition:visual_impaired=0\|tag:language=(deu|eng)$' \
        | sed 's/^.*|index=\([^|]*\)|.*$/\1/')" || true

    ADDITIONAL_ARGUMENTS=()
    if [[ "$ENCODER_CPU" == true ]]; then
        ADDITIONAL_ARGUMENTS+=( --cpu )
    fi
    if [[ "$VIDEO_CODEC" == "h264" ]]; then
        ADDITIONAL_ARGUMENTS+=( --no-video )
    fi
    if [[ "$AUDIO_CODEC" == "aac" ]]; then
        ADDITIONAL_ARGUMENTS+=( --no-audio )
    fi
    for STREAM in $STREAMS_TO_REMOVE; do
        ADDITIONAL_ARGUMENTS+=( --remove-stream "$STREAM" )
    done
    echo "Additional arguments: ${ADDITIONAL_ARGUMENTS[*]}"
    encode.sh --compatibility --scale "'min(1920,iw)':-2" --output "$WORKING_DIR" \
        --audio-channels 2 "${ADDITIONAL_ARGUMENTS[@]}" "$INPUT_FILE"

    LANGUAGES="de"
    if grep --silent '|codec_type=audio|.*|tag:language=eng$' <<< "$FFPROBE_OUTPUT"; then
        LANGUAGES+=",en"
    fi
    rename "s/\[.*\]/ - 1080p h264 [${LANGUAGES}]/" "$(basename "$INPUT_FILE")"
    mv ./* "$OUTPUT_DIR"
    echo
done