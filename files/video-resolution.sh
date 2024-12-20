#!/usr/bin/env bash
set -e -o pipefail

INPUT_FILE=""

# Check arguments
INPUT_FILE="$1"
if [[ -z "$INPUT_FILE" ]]; then
    echo "Please specify exactly one video file."
    exit 1
fi

FFPROBE_OUTPUT="$(ffprobe -v error -select_streams V:0 -show_entries \
    "stream=width,height" -print_format compact "$INPUT_FILE")"

VIDEO_WIDTH="$(sed --silent 's/^.*|width=\([^|]*\)|.*$/\1/p' <<< "$FFPROBE_OUTPUT")"
VIDEO_HEIGHT="$(sed --silent 's/^.*|height=\([^|]*\)\(|.*\)\?$/\1/p' <<< "$FFPROBE_OUTPUT")"

if [[ "$((VIDEO_WIDTH * 100 / VIDEO_HEIGHT))" -gt "$(( 1600 / 9 ))" ]]; then
    echo "$((VIDEO_WIDTH * 9 / 16 ))p"
else
    echo "${VIDEO_HEIGHT}p"
fi
