#!/usr/bin/env bash

# Step 0 - Some handy-dandy functions, yell at the user if necessary
function showHelp() {
  echo "Example usage: ${0} -v 4.2.3"
  echo "  -v: [Required] The version number"
}
if [ "${EUID}" != 0 ]; then
  >&2 echo "This script must be run as root. Terminating..."
  exit 1
fi

# Determine architecture
ARCH=false
RELEASE_VER=false
MIRROR_URL="https://nodejs.org/download/release"
DEST_DIR="/usr/local"

case "$(uname -m)" in
  i[36]86)  ARCH="86";;
  x86_64)   ARCH="64";;
esac

if [ "${ARCH}" = false ]; then
  >&2 echo "Unsupported architecture."
  exit 2
fi
if [ "$(uname -s)" != "Linux" ]; then
  >&2 echo "Operating system ($(uname -s)) not supported."
  exit 3
fi

# Parse the arguments
while getopts "v:v h" flag
do
  case $flag in
    h)  showHelp && exit;;
    v)  RELEASE_VER="${OPTARG}";;
  esac
done

if [ "${RELEASE_VER}" = false ]; then
  >&2 echo "Please provide a version to install (e.g. '-v 4.2.3')"
  >&2 echo "Not too sure which one to pick?" \
    "Head over to https://nodejs.org/en/download/releases."
  exit 4
fi

FILENAME="node-v${RELEASE_VER}-linux-x${ARCH}"
FILE_URL="${MIRROR_URL}/v${RELEASE_VER}/${FILENAME}.tar.gz"
# Check for an existing directory
if [ -d "${FILENAME}" ]; then
  printf "Removing existing directory..."
  rm -rf "${FILENAME}" && echo ' Done!'
  if [ "${?}" != 0 ]; then
    >&2 echo "An error occurred while trying to remove the existing directory."
    exit 5
  fi
fi

printf "Downloading version %s from %s..." "${RELEASE_VER}" "${MIRROR_URL}"
curl -sL "${FILE_URL}" | tar zx &&
echo ' Done!'

if [ "${?}" != 0 ]; then
  >&2 echo -e "An error occured while trying to download the package from"\
    "the mirror."\
    "\nURL: ${FILE_URL}"
  exit 6
fi

# Unpack the installation into /usr/local, and clean up the temporary files.
printf "Unpacking nodejs content into %s..." "${DEST_DIR}"
for i in lib include bin share; do
  cp -r "${FILENAME}/${i}" "${DEST_DIR}"
done && rm -rf "${FILENAME}"
echo ' All done - Have fun!'
