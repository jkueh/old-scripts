#!/bin/bash

# This script is designed to be run on a Synology NAS, with connected USB drives
# e.g. a 6TB portable hard drive to be run overnight, taking a full snapshot of
# the volume from the selected source directories.

VOLUME_ROOT="usbshare"
# Source dirs are examples - Redacted identifying information.
SOURCE_DIRS=(
  '/volume1/example_folder'
  '/volume2/example_folder'
  '/volume3/Guest'
)

CP="/bin/cp"
DATE="/bin/date"
ECHO="/bin/echo"
FIND="/bin/find"
GREP="/bin/grep"
MKDIR="/bin/mkdir"
MOUNT="/bin/mount"
PS="/bin/ps"

function clearLog() { if [ -f "${1}" ]; then cat /dev/null > "${1}"; fi }
function log() {
  # $1 - The message to send
  # $2 - The logfile to append to, if provided.
  # MSGR refers tp an internal messaging tool that we used to send log messages
  # to a Slack channel.
  MSGR='/usr/local/sbin/cm'
  if [ -f "${MSGR}" ]; then
    ($MSGR -t '#systems' -u 'NAS' -m "[$(${DATE} +%H%M)h] ${1}" -r) &
  fi
  [ "${2}" != "" ] && "${ECHO}" "${1}" >> "${2}"
}

if [ "$(${PS} ax | ${GREP} 'bdrive_backup.sh' | ${GREP} -v 'grep' | ${GREP} -vc ${$})" -ne 1 ]; then
  log 'Skipping backup run - Detected another running instance.'
fi

for VOLUME in /volumeUSB[0-9]; do

  # Set some handy-dandy variables
  VOLUME_ALIAS="${VOLUME##*/}"
  VOLROOT="${VOLUME}/${VOLUME_ROOT}"
  TARGET="${VOLROOT}/$(${DATE} +%Y-%m-%d)"

  # Check if the drive is physically present via the 'mount' command.
  if ${MOUNT} | ${GREP} "${VOLUME}" > /dev/null 2>&1; then
    log "Beginning backup to ${VOLUME_ALIAS}"
  else
    log "Volume ${VOLUME_ALIAS} does not appear to be mounted, but the target\
 directory exists."
    # If we can't see it, then skip to the next loopg iteration.
    continue
  fi

  # Begin the backup process.
  "${FIND}" "${VOLROOT}" -mindepth 1 -delete
  [ ! -d "${TARGET}" ] && "${MKDIR}" "${TARGET}"
  for SOURCE in "${SOURCE_DIRS[@]}"; do
    SOURCENAME="${SOURCE##*/}"
    LOGFILE="${TARGET}/${SOURCENAME}.log"
    log "Backup for ${SOURCENAME} began at $(${DATE})." "${LOGFILE}"
    "${CP}" -rv "${SOURCE}" "${TARGET}" > "${LOGFILE}" 2>&1 &&
    log "Backup for ${SOURCENAME} ended at $(${DATE})." "${LOGFILE}"
  done
  if [ "${?}" = 0 ]; then
    log "Backup to ${VOLUME_ALIAS} is complete."
  else
    log "<@jordan>: An error occurred before the backup job for ${VOLUME_ALIAS} could complete."
  fi
done