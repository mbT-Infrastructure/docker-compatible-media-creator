#!/usr/bin/env bash
set -e -o pipefail

INPUT_DIR=/media/compatible-media-creator/input
LOCK_FILE="/run/lock/$(basename "$0").lock"
OUTPUT_DIR=/media/compatible-media-creator/output
TMPDIR=/media/workdir

export TMPDIR

# Aquire lock
if [ -e "$LOCK_FILE" ]; then
    echo "Error: $(basename "$0") is already running. Exiting."
    exit 1
fi
touch "$LOCK_FILE"

function cleanup {
    rm "$LOCK_FILE"
}
trap cleanup EXIT

echo "Starting compatibility version creation."

mapfile -t INPUT_FILES < <(find "$INPUT_DIR" -type f \
    | grep --extended-regexp '\)[^-]*\[.*\].(mkv|mp4)$' || true)
OUTPUT_FILES="$(find "$OUTPUT_DIR" -type f \
    | sed --expression "s|^${OUTPUT_DIR}||" \
        --expression 's/ - [0-9]*p h264 \[.*\]\.\(mp4\|mkv\)$//')"

for INPUT_FILE in "${INPUT_FILES[@]}"; do
    if [[ ! -f "$INPUT_FILE" ]]; then
        continue
    fi

    TRIMMED_INPUT_FILE="$(sed --expression "s|^${INPUT_DIR}||" \
        --expression 's/ \[.*\]\.\(mp4\|mkv\)$//' <<< "$INPUT_FILE")"
    if  grep --silent --fixed-strings "$TRIMMED_INPUT_FILE" <<< "$OUTPUT_FILES"; then
        echo "\"$INPUT_FILE\" is already processed."
        continue
    fi

    echo "Processing \"$TRIMMED_INPUT_FILE\""

    RELATIVE_DIR="$(dirname "${INPUT_FILE#"${INPUT_DIR}/"}")"
    create-compatibility-version.sh --output "${OUTPUT_DIR}/$RELATIVE_DIR" "$INPUT_FILE" \
        | sed "s|^|    |"
done
