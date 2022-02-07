#!/bin/bash

# Prepares a SD structure from previous runs of "update_core.sh" and syncs to
# SD card the changed files. Adapted for macOS.

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

  CHFLGBIN=`which chflags`
  DSKTLBIN=`which diskutil`
  MTTRBIN=`which mattrib`

  echo "Preparing SD temp data:"
  rm -rf "${SDDIR}" 2>/dev/null
  mkdir -p "${SDDIR}"

  echo "  Firmware..."
  cp -p "${MYPATH}/_firmware/"*.upg "${SDDIR}/firmware.upg"

  DIR_CORES=("Computer" "Console")
  for i in "${!DIR_CORES[@]}"; do
    echo "  ${DIR_CORES[i]} cores..."
    if [[ -d "${MYPATH}/${DIR_CORES[i]}" ]]; then
      populate_dir "${MYPATH}/${DIR_CORES[i]}" "${SDDIR}/${DIR_CORES[i]}" "RBF"
      populate_dir "${MYPATH}/${DIR_CORES[i]}" "${SDDIR}/${DIR_CORES[i]}" "ARC"
      populate_dir "${MYPATH}/${DIR_CORES[i]}" "${SDDIR}/${DIR_CORES[i]}" "ROM"
      populate_dir "${MYPATH}/${DIR_CORES[i]}" "${SDDIR}" "VHD"
    fi
  done

  echo "Synchronizing (rsync) to SD..."
  # Arcade
  rsync -utr --modify-window=1 --exclude='*.ini' \
             --exclude='.Trashes' --exclude='.fseventsd' --exclude='._*' \
             --exclude='.DS_Store' --exclude='.Spotlight-V100' \
             --exclude='System Volume Information' \
              "${MYPATH}/Arcade" "${DESTVOL}"
  # Other
  rsync -utr --modify-window=1 --exclude='*.ini' --exclude='*.CFG' \
             --exclude='*.RAM' --exclude='*.sav' --exclude='QXL.WIN' \
             --exclude='.Trashes' --exclude='.fseventsd' --exclude='._*' \
             --exclude='.DS_Store' --exclude='.Spotlight-V100' \
             --exclude='System Volume Information' \
              "${SDDIR}/" "${DESTVOL}"

  echo "Clearing SD temp data..."
  rm -rf "${SDDIR}" 2>/dev/null

  echo "Removing unnecessary macOS files..."
  find "${DESTVOL}" -name "._*" -exec rm {} 2>/dev/null \;
  find "${DESTVOL}" -name ".DS_Store" -exec rm {} 2>/dev/null \;

  DIRSJ=("JOTEGO-CPS0" "JOTEGO-CPS2" "JOTEGO-FASTLANE" "JOTEGO-SYSTEM16" "JOTEGO-BUBBLETOKIO" "JOTEGO-CPS1" "JOTEGO-DD" "JOTEGO-MX500" "JOTEGO-VARIOS" "JOTEGO-CONTRA" "JOTEGO-CPS15" "JOTEGO-EXEDEXES" "JOTEGO-NINJA")
  DIRSG=("Atari BW Raster Hardware" "IremM52 Hardware" "Namco Pacman Hardware" "Atari Centipede Hardware" "IremM57 Hardware" "Namco Rally-X Hardware" "Atari Discrete Logic" "IremM62 Hardware" "Namco Super Pacman Hardware" "Atari Tetris" "" "Konami Classic" "" "Nintendo Popeye Hardware" "Atari Vector" "" "Konami Green Beret Hardware" "Nintendo Radar Scope Hardware" "Bagman Hardware" "" "Konami Scramble Hardware" "Non Arcade" "Berzerk Hardware" "Ladybug Hardware" "Nova2001_Hardware" "Crazy Climber Hardware" "Midway MCR 1" "" "Otros" "Data East Burger Time Hardware" "Midway MCR 2" "" "Phoenix Hardware" "Dottori-Kun Hardware" "Midway MCR 3" "" "Sega Zaxxon Hardware" "Galaga Hardware" "" "Midway MCR Scroll" "Tehkan Bombjack Hardware" "Galaxian Hardware" "Midway-Taito 8080 Hardware" "Williams 6809 rev.1 Hardware")
  if [ -e ${CHFLGBIN} ]; then
    echo "Hiding RBFs..."
    # jotego
    for i in "${!DIRSJ[@]}"; do
      ${CHFLGBIN} hidden "${DESTVOL}/Arcade/${DIRSJ[i]}/"*rbf
    done
    # geshtock
    #for i in "${!DIRSG[@]}"; do
    #  echo ${CHFLGBIN} hidden "${DESTVOL}/Arcade/GEHSTOCK/${DIRSG[i]}/"*rbf
    #done
  fi

  if [ -e ${MTTRBIN} ]; then
    if [ ! -e ${DSKTLBIN} ]; then
        echo "ERROR: diskutil not found"
        exit 2
    fi
    DESTDEV=`${DSKTLBIN} list "${DESTVOL}" | tail -1 | awk '{print $NF}'`

    if [[ $(id -u) -ne 0 ]]; then
      echo "ERROR: Run the script with root privileges"
      exit 3
    fi
  
    echo "Unmounting ${DESTVOL}..."
    ${DSKTLBIN} unmount "${DESTVOL}"

    echo "Adding system attrib to directories..."
    sed -i '' "s/^drive [sS]\:.*/drive s\: file=\"\/dev\/${DESTDEV}\"/" "${HOME}/.mtoolsrc"

    # Computer and Console
    sudo ${MTTRBIN} +s "s:/Computer"
    sudo ${MTTRBIN} +s "s:/Console"

    # Arcade (jotego)
    for i in "${!DIRSJ[@]}"; do
      sudo ${MTTRBIN} +s "s:/Arcade/${DIRSJ[i]}"
    done
    # Arcade (gehstock)
    for i in "${!DIRSG[@]}"; do
      sudo ${MTTRBIN} +s "s:/Arcade/GEHSTOCK/${DIRSG[i]}"
    done

    echo "Remounting device /dev/${DESTDEV}..."
    ${DSKTLBIN} mount "/dev/${DESTDEV}"
  fi

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
