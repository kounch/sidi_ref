#!/bin/bash
# Updates and gets jt cores
# Retrieves new game ROMS if needed from archive.org
# Don't forget to set the SYSTEM attribute for any subdirectories
# on the SD card. Needs to be done in Windows "attrib +s JT-SYSTEM16"

# Original version for MiST obtained from
#       https://gist.github.com/squidrpi/4ce3ea61cbbfa3900e116f9565d45e74

MYPATH=`realpath "$0"`
MYPATH=`dirname "${MYPATH}"`

main () {
  BASEDIR="${MYPATH}/_temp"
  SRCDIR="${BASEDIR}/git/SiDi"
  ZIPDIR="${BASEDIR}/mame_gehstock"
  MRABIN="${MYPATH}/mra"

  FLAGFILE="${BASEDIR}/update_arcade.flag"
  if [[ ! -f "${FLAGFILE}" ]]; then
    touch -t 197201010000 "${FLAGFILE}"
  fi

  mkdir -p "${ZIPDIR}"

  echo "Getting repository updates.."
  # Clone git repo if it doesn't exist
  if [[ ! -d "${SRCDIR}" ]]; then
    mkdir -p "${BASEDIR}/git"
    (cd "${BASEDIR}/git"; git clone https://github.com/eubrunosilva/SiDi)
  fi
  # Update cores and mra from SiDi github
  (cd "${SRCDIR}"; git pull > /dev/null)

  #Set timestamps on git files to match repository commit dates
  (cd "${SRCDIR}"; git ls-files | sed "s/'/\\\'/g" | xargs -I{} bash -c 'touch -t $(git log -n1 --pretty=format:%cd --date=format:%Y%m%d%H%M.%S -- "{}") "{}" 2>/dev/null')
  rm "${SRCDIR}/{}" 2>/dev/null

  echo "Updating MRA..."
  find "${SRCDIR}/Arcade" -type f -iname '*.mra' -newer "${FLAGFILE}" -print0  | while read -d $'\0' MRAFILE
  do
    # Process RBF names
    RBF=$("${MRABIN}" -l "${MRAFILE}" | grep 'rbf name:' | sed 's/rbf name: //' | tr '[:upper:]' '[:lower:]')

    # Exclude jotego arcades
    [[ "${RBF}" == *jt* ]] && continue

    # Find RBF file
    RBFORIG=$(find "${SRCDIR}/Arcade" -type f -iname "${RBF}*.rbf" | head -1)

    set_destdir "${RBF}"
    mkdir -p "${DESTDIR}"
  
    # Copy RBF if needed
    if [[ ! -f "${RBFORIG}" ]]; then
      echo "RBF ${RBF} is missing for MRA `basename "${MRAFILE}"`"
    else
      copy_changed "${RBFORIG}" "${DESTDIR}/${RBF}.rbf"
    fi

    # Check if ROM exists
    ZIPFILE=$("${MRABIN}" -l "${MRAFILE}" | grep 'zip\[0\]' | head -1 | awk '{print $2}')
    if [[ "${ZIPFILE}" != "" ]]; then
      echo "${ZIPFILE}"
      if [[ ! -f "${ZIPDIR}/${ZIPFILE}" ]]; then
        echo "${MRAFILE}"
        echo Downloading ROM ${ZIPFILE}...
        (cd "${ZIPDIR}";  curl -sOL https://archive.org/download/MAME216RomsOnlyMerged/${ZIPFILE})
        #cp "/Volumes/MAME 0232/${ZIPFILE}" "${ZIPDIR}/"
        #(cd "${ZIPDIR}";  curl -sOL https://archive.org/download/mame-merged/mame-merged/${ZIPFILE})
        #(cd "${ZIPDIR}";  curl -sOL https://archive.org/download/hbmame0224roms/${ZIPFILE})
        #(cd "${ZIPDIR}";  curl -sOL https://archive.org/download/MAME223RomsOnlyMerged/${ZIPFILE})
        #(cd "${ZIPDIR}";  curl -sOL https://archive.org/download/mame-0.221-roms-merged/${ZIPFILE})
        #(cd "${ZIPDIR}";  curl -sOL https://archive.org/download/MAME216RomsOnlyMerged/${ZIPFILE})
      fi
    fi
  
    # Make ROM and ARC
    "${MRABIN}" -A -O "${DESTDIR}"/ -z "${ZIPDIR}" "${MRAFILE}" | egrep -v 'expected: None|Coin|Bonus|Credit|Demo|Level|Continu' 
  done

  echo "Updating cores..."
  find "${SRCDIR}/Arcade" -type f -iname '*.rbf' -print0  | while read -d $'\0' RBFFILE
  do
    RBFNAME=`basename "${RBFFILE}"`

    # Exclude jotego arcades
    [[ "${RBFNAME}" == *jt* ]] && continue

    # Fix unorthodox RBF names 
    RBFDEST=$(echo "${RBFNAME}" | sed 's/_[0-9]*\././' | tr '[:upper:]' '[:lower:]')

    set_destdir "${RBFDEST}"
    mkdir -p "${DESTDIR}"

    # Copy RBF if needed
    copy_changed "${RBFFILE}" "${DESTDIR}/${RBFDEST}"
  done

  touch "${FLAGFILE}"

  echo "Finished"
}

# Set DESTDIR variable depending on the text received
set_destdir () {
    TESTFILE=$1

    DESTARCADE="${MYPATH}/Arcade/GEHSTOCK"
    DESTDIR="${DESTARCADE}/Otros"
    RBFS=("2048" "arkanoid" "flappybird" "riveraid")
    for i in "${!RBFS[@]}"; do
      [[ "${TESTFILE}" == *"${RBFS[i]}"* ]] && DESTDIR="${DESTARCADE}/Non Arcade"
    done
    RBFS=("alibaba" "birdiy" "crushroller" "dreamshopper" "eeekk" "eggor" "eyes" "gorkans" "lizardwizard" "mrtnt" "mspacman" "pacman" "pacmanclub" "pacmanicminer" "pacmanplus" "pengo" "ponpoko" "superglob" "vanvancar" "woodpecker")
    for i in "${!RBFS[@]}"; do
      [[ "${TESTFILE}" == *"${RBFS[i]}"* ]] && DESTDIR="${DESTARCADE}/Namco Pacman Hardware"
    done
    RBFS=("bagman" "botanic" "pickin" "squash" "superbagman")
    for i in "${!RBFS[@]}"; do
      [[ "${TESTFILE}" == *"${RBFS[i]}"* ]] && DESTDIR="${DESTARCADE}/Bagman Hardware"
    done
    [[ "${TESTFILE}" == *centipede* ]] && DESTDIR="${DESTARCADE}/Atari Centipede Hardware"
    RBFS=("berzerk" "frenzy")
    for i in "${!RBFS[@]}"; do
      [[ "${TESTFILE}" == *"${RBFS[i]}"* ]] && DESTDIR="${DESTARCADE}/Berzerk Hardware"
    done
    RBFS=("blackwidow" "gravitar" "lunarlander")
    for i in "${!RBFS[@]}"; do
      [[ "${TESTFILE}" == *"${RBFS[i]}"* ]] && DESTDIR="${DESTARCADE}/Atari Vector"
    done
    [[ "${TESTFILE}" == *bombjack* ]] && DESTDIR="${DESTARCADE}/Tehkan Bombjack Hardware"
    RBFS=("burgertime" "burninrubber")
    for i in "${!RBFS[@]}"; do
      [[ "${TESTFILE}" == *"${RBFS[i]}"* ]] && DESTDIR="${DESTARCADE}/Data East Burger Time Hardware"
    done
    RBFS=("canyonbomber" "dominos" "sprint2" "sprintone" "superbreakout" "ultratank")
    for i in "${!RBFS[@]}"; do
      [[ "${TESTFILE}" == *"${RBFS[i]}"* ]] && DESTDIR="${DESTARCADE}/Atari BW Raster Hardware"
    done
    RBFS=("capitol" "phoenix" "pleiads")
    for i in "${!RBFS[@]}"; do
      [[ "${TESTFILE}" == *"${RBFS[i]}"* ]] && DESTDIR="${DESTARCADE}/Phoenix Hardware"
    done
    [[ "${TESTFILE}" == *computerspace* ]] && DESTDIR="${DESTARCADE}/Atari Discrete Logic"
    RBFS=("cosmicavenger" "dorodon" "ladybug" "snapjack")
    for i in "${!RBFS[@]}"; do
      [[ "${TESTFILE}" == *"${RBFS[i]}"* ]] && DESTDIR="${DESTARCADE}/Ladybug Hardware"
    done
    RBFS=("craterraider" "spyhunter" "turbotag")
    for i in "${!RBFS[@]}"; do
      [[ "${TESTFILE}" == *"${RBFS[i]}"* ]] && DESTDIR="${DESTARCADE}/Midway MCR Scroll"
    done
    RBFS=("crazyclimber" "crazykong" "riverpatrol" "silverland")
    for i in "${!RBFS[@]}"; do
      [[ "${TESTFILE}" == *"${RBFS[i]}"* ]] && DESTDIR="${DESTARCADE}/Crazy Climber Hardware"
    done
    RBFS=("defender" "robotron")
    for i in "${!RBFS[@]}"; do
      [[ "${TESTFILE}" == *"${RBFS[i]}"* ]] && DESTDIR="${DESTARCADE}/Williams 6809 rev.1 Hardware"
    done
    RBFS=("digdug" "galaga" "xevious")
    for i in "${!RBFS[@]}"; do
      [[ "${TESTFILE}" == *"${RBFS[i]}"* ]] && DESTDIR="${DESTARCADE}/Galaga Hardware"
    done
    [[ "${TESTFILE}" == *donkeykong* ]] && DESTDIR="${DESTARCADE}/Nintendo Radar Scope Hardware"
    [[ "${TESTFILE}" == *dottorikun* ]] && DESTDIR="${DESTARCADE}/Dottori-Kun Hardware"
    [[ "${TESTFILE}" == *druaga* ]] && DESTDIR="${DESTARCADE}/Namco Super Pacman Hardware"
    RBFS=("galaxian" "zigzag")
    for i in "${!RBFS[@]}"; do
      [[ "${TESTFILE}" == *"${RBFS[i]}"* ]] && DESTDIR="${DESTARCADE}/Galaxian Hardware"
    done
    [[ "${TESTFILE}" == *gberet* ]] && DESTDIR="${DESTARCADE}/Konami Green Beret Hardware"
    RBFS=("gunfight" "lunarrescue" "ozmawars" "spaceinvaders" "spacelaser" "superearthinvasion" "vortex" )
    for i in "${!RBFS[@]}"; do
      [[ "${TESTFILE}" == *"${RBFS[i]}"* ]] && DESTDIR="${DESTARCADE}/Midway-Taito 8080 Hardware"
    done
    [[ "${TESTFILE}" == *iremm62* ]] && DESTDIR="${DESTARCADE}/IremM62 Hardware"
    RBFS=("moonpatrol" "travrusa")
    for i in "${!RBFS[@]}"; do
      [[ "${TESTFILE}" == *"${RBFS[i]}"* ]] && DESTDIR="${DESTARCADE}/IremM52 Hardware"
    done
    [[ "${TESTFILE}" == *mcr1* ]] && DESTDIR="${DESTARCADE}/Midway MCR 1"
    RBFS=("journey" "mcr2")
    for i in "${!RBFS[@]}"; do
      [[ "${TESTFILE}" == *"${RBFS[i]}"* ]] && DESTDIR="${DESTARCADE}/Midway MCR 2"
    done
    [[ "${TESTFILE}" == *mcr3* ]] && DESTDIR="${DESTARCADE}/Midway MCR 3"
    [[ "${TESTFILE}" == *ninjakun* ]] && DESTDIR="${DESTARCADE}/Nova2001_Hardware"
    [[ "${TESTFILE}" == *pacman* ]] && DESTDIR="${DESTARCADE}/Namco Pacman Hardware"
    RBFS=("pooyan" "powersurge" "timepilot")
    for i in "${!RBFS[@]}"; do
      [[ "${TESTFILE}" == *"${RBFS[i]}"* ]] && DESTDIR="${DESTARCADE}/Konami Classic"
    done
    RBFS=("popeye" "skyskipper")
    for i in "${!RBFS[@]}"; do
      [[ "${TESTFILE}" == *"${RBFS[i]}"* ]] && DESTDIR="${DESTARCADE}/Nintendo Popeye Hardware"
    done
        [[ "${TESTFILE}" == *rallyx* ]] && DESTDIR="${DESTARCADE}/Namco Rally-X Hardware"
    RBFS=("scramble" "theend")
    for i in "${!RBFS[@]}"; do
      [[ "${TESTFILE}" == *"${RBFS[i]}"* ]] && DESTDIR="${DESTARCADE}/Konami Scramble Hardware"
    done
    [[ "${TESTFILE}" == *tetris* ]] && DESTDIR="${DESTARCADE}/Atari Tetris"
    [[ "${TESTFILE}" == *tropicalangel* ]] && DESTDIR="${DESTARCADE}/IremM57 Hardware"
    [[ "${TESTFILE}" == *zaxxon* ]] && DESTDIR="${DESTARCADE}/Sega Zaxxon Hardware"
}

# Copy file if destination does not exist or if dates are different, or if content is different
copy_changed () {
  SRC=$1
  DST=$2

  if [[ -f "${SRC}" && ! -f "${DST}" ]]; then
    cp -p "${SRC}" "${DST}"
    echo Update "${DST}"
  else
    if [[ "${SRC}" -nt "${DST}" ]]; then
      cp -p "${SRC}" "${DST}"
      echo Update "${DST}"
    else
      #Check checksum
      MD5SRC=`md5sum "${SRC}" | awk '{print $1}'`
      MD5DST=`md5sum "${DST}" | awk '{print $1}'`
  
      if [[ "${MD5SRC}" != "${MD5DST}" ]]; then
        cp -p "${SRC}" "${DST}"
        echo Update "${DST}"
      fi
    fi
  fi
}

main "$@"
