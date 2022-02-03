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
  SRCDIR="${BASEDIR}/git/jtbin"
  ZIPDIR="${BASEDIR}/mame"
  MRABIN="${MYPATH}/mra"

  FLAGFILE="${BASEDIR}/update_jtcores.flag"
  if [[ ! -f "${FLAGFILE}" ]]; then
    touch -t 197201010000 "${FLAGFILE}"
  fi

  mkdir -p "${ZIPDIR}"

  echo "Getting repository updates.."
  # Clone git repo if it doesn't exist
  if [[ ! -d "${SRCDIR}" ]]; then
    mkdir -p "${BASEDIR}/git"
    (cd "${BASEDIR}/git"; git clone https://github.com/jotego/jtbin.git)
  fi
  # Update cores and mra from jtbin github
  (cd "${SRCDIR}"; git pull > /dev/null)

  #Set timestamps on git files to match repository commit dates
  (cd "${SRCDIR}"; git ls-files | sed "s/'/\\\'/g" | xargs -I{} bash -c 'touch -t $(git log -n1 --pretty=format:%cd --date=format:%Y%m%d%H%M.%S -- "{}") "{}" 2>/dev/null')
  rm "${SRCDIR}/{}" 2>/dev/null

  echo "Updating MRA..."
  find "${SRCDIR}/mra" -type f -iname '*.mra' -newer "${FLAGFILE}" -print0  | while read -d $'\0' MRAFILE
  do
    # Exclude what I'm not interested in
    [[ "${MRAFILE}" == *_alternatives* ]] && continue

    # Process RBF names
    RBF=$("${MRABIN}" -l "${MRAFILE}" | grep 'rbf name:' | sed 's/rbf name: //')
    # Fix wrong named RBFs
    RBF=$(echo "${RBF}" | sed 's/jtcommando/jtcom/')
    RBF=$(echo "${RBF}" | sed 's/jtgunsmoke/jtgun/')
    RBF=$(echo "${RBF}" | sed 's/jtsectionz/jtsz/')
    RBF=$(echo "${RBF}" | sed 's/jtf1dream/jtf1drm/')
    # Fix unorthodox RBF names 
    RBFORIG=$(echo "${RBF}" | sed 's/jtsf.rbf/jtsf_20210519.rbf/')

    set_destdir "${RBF}"
    mkdir -p "${DESTDIR}"
  
    # Copy RBF if needed
    if [[ ! -f "${SRCDIR}/sidi/${RBFORIG}.rbf" ]]; then
      echo "RBF ${RBF} is missing for MRA `basename "${MRAFILE}"`, probably BETA"
    else
      copy_changed "${SRCDIR}/sidi/${RBFORIG}.rbf" "${DESTDIR}/${RBF}.rbf"
    fi

    # Check if ROM exists
    ZIPFILE=$("${MRABIN}" -l "${MRAFILE}" | grep 'zip\[0\]' | head -1 | awk '{print $2}')
    echo "${ZIPFILE}"
    if [[ ! -f "${ZIPDIR}/${ZIPFILE}" ]]; then
      echo Downloading ROM ${ZIPFILE}...
      (cd "${ZIPDIR}";  curl -sOL https://archive.org/download/mame-merged/mame-merged/${ZIPFILE})
      #cp "/Volumes/MAME 0232/${ZIPFILE}" "${ZIPDIR}/"
      #(cd "${ZIPDIR}";  curl -sOL https://archive.org/download/mame-merged/mame-merged/${ZIPFILE})
      #(cd "${ZIPDIR}";  curl -sOL https://archive.org/download/hbmame0224roms/${ZIPFILE})
      #(cd "${ZIPDIR}";  curl -sOL https://archive.org/download/MAME223RomsOnlyMerged/${ZIPFILE})
      #(cd "${ZIPDIR}";  curl -sOL https://archive.org/download/mame-0.221-roms-merged/${ZIPFILE})
      #(cd "${ZIPDIR}";  curl -sOL https://archive.org/download/MAME216RomsOnlyMerged/${ZIPFILE})
    fi
  
    # Make ROM and ARC
    "${MRABIN}" -A -O "${DESTDIR}"/ -z "${ZIPDIR}" "${MRAFILE}" | egrep -v 'expected: None|Coin|Bonus|Credit|Demo|Level|Continu' 
  done

  echo "Updating cores..."
  find "${SRCDIR}/sidi" -type f -iname '*.rbf' -print0  | while read -d $'\0' RBFFILE
  do
    RBFNAME=`basename "${RBFFILE}"`

    # Fix unorthodox RBF names 
    RBFDEST=$(echo "${RBFNAME}" | sed 's/jtsf_20210519/jtsf/')

    set_destdir "${RBFDEST}"
    mkdir -p "${DESTDIR}"
    copy_changed "${RBFFILE}" "${DESTDIR}/${RBFDEST}"
  done

  touch "${FLAGFILE}"

  echo "Finished"
}

# Set DESTDIR variable depending on the text received
set_destdir () {
    TESTFILE=$1

    DESTDIR="${MYPATH}/Arcade/JOTEGO-VARIOS"
    [[ "${TESTFILE}" == *jtexed* ]] && DESTDIR="${MYPATH}/Arcade/JOTEGO-EXEDEXES"
    [[ "${TESTFILE}" == *jtbubl* ]] && DESTDIR="${MYPATH}/Arcade/JOTEGO-BUBBLETOKIO"
    [[ "${TESTFILE}" == *jtcontra* ]] && DESTDIR="${MYPATH}/Arcade/JOTEGO-CONTRA"
    RBFS=("jt1942" "jtbtiger" "jtf1drm" "jtgunsmoke" "jtrumble" "jtsz" "jtvulgus jt1943" "jtcom" "jtgng" "jthige" "jtsarms" "jttora jtbiocom" "jtcomsc" "jtgun" "jtlabrun" "jtsf" "jttrojan")
    for i in "${!RBFS[@]}"; do
      [[ "${TESTFILE}" == *"${RBFS[i]}"* ]] && DESTDIR="${MYPATH}/Arcade/JOTEGO-CPS0"
    done
    [[ "${TESTFILE}" == *jtcps1* ]] && DESTDIR="${MYPATH}/Arcade/JOTEGO-CPS1"
    [[ "${TESTFILE}" == *jtcps15* ]] && DESTDIR="${MYPATH}/Arcade/JOTEGO-CPS15"
    [[ "${TESTFILE}" == *jtcps2* ]] && DESTDIR="${MYPATH}/Arcade/JOTEGO-CPS2"
    [[ "${TESTFILE}" == *jtdd* ]] && DESTDIR="${MYPATH}/Arcade/JOTEGO-DD"
    [[ "${TESTFILE}" == *jtflane* ]] && DESTDIR="${MYPATH}/Arcade/JOTEGO-FASTLANE"
    [[ "${TESTFILE}" == *jtmx5k* ]] && DESTDIR="${MYPATH}/Arcade/JOTEGO-MX500"
    RBFS=("jtninja" "jtcop")
    for i in "${!RBFS[@]}"; do
      [[ "${TESTFILE}" == *"${RBFS[i]}"* ]] && DESTDIR="${MYPATH}/Arcade/JOTEGO-NINJA"
    done
    [[ "${TESTFILE}" == *jts16* ]] && DESTDIR="${MYPATH}/Arcade/JOTEGO-SYSTEM16"
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
