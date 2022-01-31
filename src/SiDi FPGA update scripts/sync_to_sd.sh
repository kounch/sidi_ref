#!/bin/bash

# Prepares a SD structure from previous runs of "update_core.sh" and syncs to
# SD card the changed files.

# Original version for MiST obtained from
#       https://gist.github.com/squidrpi/4ce3ea61cbbfa3900e116f9565d45e74

MYPATH=`realpath "$0"`
MYPATH=`dirname "${MYPATH}"`

main () {
  DESTVOL=$1
  if [ -z "${DESTVOL}" ]; then
    echo "Usage: sync_to_sd.sh /Volumes/SiDi"
    exit 1
  fi
  DESTVOL=`realpath "${DESTVOL}"`

  BASEDIR="${MYPATH}/_temp"
  SDDIR="${BASEDIR}/SD"

  echo "Preparing SD temp data..."
  rm -rf "${SDDIR}" 2>/dev/null
  mkdir -p "${SDDIR}"

  DIR_CORES=("Computer" "Console")
  for i in "${!DIR_CORES[@]}"; do
    echo "${DIR_CORES[i]} cores..."
    if [[ -d "${MYPATH}/${DIR_CORES[i]}" ]]; then
      populate_dir "${MYPATH}/${DIR_CORES[i]}" "${SDDIR}/${DIR_CORES[i]}" "RBF"
    fi
  done

  echo "Computer ROMs..."
  if [[ -d "${MYPATH}/Computer" ]]; then
    populate_dir "${MYPATH}/Computer" "${SDDIR}" "ROM"
  fi

  echo
  echo "Synchronizing (rsync) to SD..."
  rsync -utr --modify-window=1 --exclude='*.ini' --exclude='*.CFG' \
             --exclude='*.RAM' --exclude='*.sav' --exclude='QXL.WIN' \
             --exclude='.Trashes' --exclude='.fseventsd' --exclude='.DS_Store' \
             --exclude='.Spotlight-V100' --exclude='System Volume Information' \
              "${SDDIR}/" "${DESTVOL}"

  echo

  echo "Clearing SD temp data..."
  rm -rf "${SDDIR}" 2>/dev/null
  echo

  echo "Finished"
}

populate_dir () {
  CURRENTDIR=$1
  DIRTOMAKE=$2
  FILETYPE=$3

  mkdir -p "${DIRTOMAKE}"

  # Check all the cores
  cd "${CURRENTDIR}"
  find . -maxdepth 2 -type f -iname "*.${FILETYPE}" -print0  | while read -d $'\0' FILE
  do
    SRC="${CURRENTDIR}/${FILE:2}"
    DST="${DIRTOMAKE}/"

    cp -p "$SRC" "${DST}"
  done
}

main "$@"
