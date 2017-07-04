#!/usr/bin/env bash
# This script converts a given file to a GIF using ffmpeg and some magic.
FFMPEG="$(/usr/bin/env which ffmpeg)"
[ "${FFMPEG}" = "" ] && >&2 echo "[ERROR] 'ffmpeg' not found." && exit 1

palette="/tmp/palette.png"
PALETTEGEN_OPTS="stats_mode=diff"
SCALE="-1:-1"
DITHER="bayer:bayer_scale=3"
# Default dither is bayer with scale 3 (bayer limit: 1-5)

while getopts "d:d i:i o:o s:s" opt; do
  case "${opt}" in
    d) DITHER="${OPTARG}";;
    i) INPUT_FILE="${OPTARG}";;
    o) OUTPUT_FILE="${OPTARG}";;
    s) SCALE="${OPTARG}";;
  esac
done

filters="scale=${SCALE}:flags=lanczos"

# Double check that valid files have been provided
[ "${INPUT_FILE}" = "" ] && >&2 echo "[ERROR] No input file provided (-i)." && exit 2
[ "${OUTPUT_FILE}" = "" ] && >&2 echo "[ERROR] No output file provided (-o)." && exit 3

# Double check that the file exists
[ ! -f "${INPUT_FILE}" ] && >&2 echo "[ERROR] Input file '${INPUT_FILE}' does not exist." && exit 4

function palette_cleanup() { [ -f "${palette}" ] && rm -f "${palette}"; }

# Ensure that we don't have an existing palette file
palette_cleanup
# Remove output files if they exist
[ -f "${OUTPUT_FILE}" ] && rm -f "${OUTPUT_FILE}"

ffmpeg -v warning -i "${INPUT_FILE}" -vf "${filters},palettegen=${PALETTEGEN_OPTS}" -y "${palette}" &&
ffmpeg -v warning -i "${INPUT_FILE}" -i "${palette}" -lavfi "${filters} [x]; [x][1:v] paletteuse=dither=${DITHER}" -y "${OUTPUT_FILE%%.gif}.gif" &&
palette_cleanup