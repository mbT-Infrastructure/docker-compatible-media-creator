#!/usr/bin/env bash
set -e -o pipefail

COMPATIBILITY_VIDEO_HEIGHT=1080
COMPATIBILITY_VIDEO_WIDTH=1920
INPUT_FILES=()
OUTPUT_DIR=""
SCHED_POLICY="${SCHED_POLICY:-idle}"
SCHED_POLICY="${SCHED_POLICY#SCHED_}"
SKIP_COMPATIBLE=true
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

    FFPROBE_OUTPUT="$(ffprobe -v error -show_entries \
        "stream=index,codec_name,codec_type,width,height:\
stream_tags=language:disposition=visual_impaired" \
        -print_format compact "$INPUT_FILE")"
    VIDEO_STREAM="$(grep --extended-regexp '|codec_type=video|' <<< "$FFPROBE_OUTPUT" \
        | head --lines 1)"
    VIDEO_CODEC="$(sed 's/^.*|codec_name=\([^|]*\)|.*$/\1/' <<< "$VIDEO_STREAM")"
    VIDEO_WIDTH="$(sed 's/^.*|width=\([^|]*\)|.*$/\1/' <<< "$VIDEO_STREAM")"
    VIDEO_HEIGHT="$(sed 's/^.*|height=\([^|]*\)|.*$/\1/' <<< "$VIDEO_STREAM")"
    AUDIO_CODEC="$(grep '|codec_type=audio|' <<< "$FFPROBE_OUTPUT" \
        | head --lines 1 \
        | sed 's/^.*|codec_name=\([^|]*\)|.*$/\1/')"
    STREAMS_TO_REMOVE="$(grep --extended-regexp '\|codec_type=(audio|subtitle)\|' \
        <<< "$FFPROBE_OUTPUT" \
        | grep --extended-regexp --invert-match \
            '\|disposition:visual_impaired=0\|tag:language=(deu|eng|und)(\|.*)?$' \
        | sed 's/^.*|index=\([^|]*\)|.*$/\1/')" || true

    ADDITIONAL_ARGUMENTS=()
    if [[ "$ENCODER_CPU" == true ]]; then
        ADDITIONAL_ARGUMENTS+=( --cpu )
    fi
    if  [[ "$VIDEO_HEIGHT" -gt "$COMPATIBILITY_VIDEO_HEIGHT" ]] \
        || [[ "$VIDEO_WIDTH" -gt "$COMPATIBILITY_VIDEO_WIDTH" ]]; then
        ADDITIONAL_ARGUMENTS+=( --scale "${COMPATIBILITY_VIDEO_WIDTH}x${COMPATIBILITY_VIDEO_HEIGHT}" )
    elif [[ "$VIDEO_CODEC" == "h264" ]]; then
        ADDITIONAL_ARGUMENTS+=( --no-video )
    fi
    if [[ "$AUDIO_CODEC" == "aac" ]]; then
        ADDITIONAL_ARGUMENTS+=( --no-audio )
    fi
    for STREAM in $STREAMS_TO_REMOVE; do
        ADDITIONAL_ARGUMENTS+=( --remove-stream "$STREAM" )
    done
    echo "Additional arguments: ${ADDITIONAL_ARGUMENTS[*]}"
    if [[ "$SKIP_COMPATIBLE" == true ]] \
        && [[ "${ADDITIONAL_ARGUMENTS[*]}" == *"--no-video"*"--no-audio"* ]]; then
        echo "Skipping \"$INPUT_FILE\" because audio and video is already compatible."
        continue
    fi

    low-priority.sh encode.sh --compatibility --output "$WORKING_DIR" \
        --audio-channels 2 "${ADDITIONAL_ARGUMENTS[@]}" "$INPUT_FILE"

    LANGUAGES=""
    if grep --silent '|codec_type=audio|.*|tag:language=\(deu\|und\)\(|.*\)\?$' \
        <<< "$FFPROBE_OUTPUT"; then
        LANGUAGES+=",de"
    fi
    if grep --silent '|codec_type=audio|.*|tag:language=eng\(|.*\)\?$' <<< "$FFPROBE_OUTPUT"; then
        LANGUAGES+=",en"
    fi
    LANGUAGES="${LANGUAGES#,}"
    RESULT_RESOLUTION="$(video-resolution.sh "$(basename "$INPUT_FILE")")"
    rename "s/\[.*\]/- $RESULT_RESOLUTION h264 [${LANGUAGES}]/" "$(basename "$INPUT_FILE")"
    mkdir --parents "$OUTPUT_DIR"
    mv ./* "$OUTPUT_DIR"
    echo
done
