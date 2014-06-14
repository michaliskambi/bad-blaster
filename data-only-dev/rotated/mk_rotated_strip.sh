#! /bin/bash

set -eu

# Robi mk_rotated i skleja obrazki w jeden pasek uzywajac combineStrip.
# Pierwsze dwa parametry jak mk_rotated, trzeci parametr to nazwa
# wynikowego pliku.

# parse params
DEGREE_STEP="$1"
IMG_0="$2"
OUT_IMAGE_NAME="$3"

# prepare tmp
TMP_PATH=/tmp/mk_rotated_strip-pid$$/
mkdir "$TMP_PATH"

./mk_rotated.sh "$DEGREE_STEP" "$IMG_0" "$TMP_PATH"
set +e
  let 'COUNT_TO = 360 - DEGREE_STEP'
set -e
combineStrip 0 "$COUNT_TO" "$DEGREE_STEP" \
  "$TMP_PATH"`stringoper AppendToFileName "$IMG_0" '_rotate%d'` \
  "$OUT_IMAGE_NAME"

# clean tmp
rm -fR "$TMP_PATH"

