#!/bin/bash

# Gets the latest cores and checks all the directories
# in the current for any changes to the cores.
# The directories MUST match the ones in the SiDi-FPGA/cores so just create
# the directories of the cores you want.

# Original version for MiST obtained from
#       https://gist.github.com/squidrpi/4ce3ea61cbbfa3900e116f9565d45e74

MYPATH=`realpath "$0"`
MYPATH=`dirname "${MYPATH}"`
LOGFILE="${MYPATH}/update_cores.log"

date >"${LOGFILE}"
echo >>"${LOGFILE}"

main () {
  BASEDIR="${MYPATH}/_temp"
  SRCDIR="${BASEDIR}/git/SiDi-FPGA/Cores"

  echo "Getting repository updates.."

  # Clone git repo if it doesn't exist
  if [[ ! -d "${SRCDIR}" ]]; then
    mkdir -p "${BASEDIR}/git"
    (cd "${BASEDIR}/git"; git clone https://github.com/ManuFerHi/SiDi-FPGA.git)
  fi

  # Update the repository from github
  (cd "${SRCDIR}"; git pull > /dev/null)

  #Set timestamps on git files to match repository commit dates
  (cd "${SRCDIR}"; git ls-files | sed "s/'/\\\'/g" | xargs -I{} bash -c 'touch -t $(git log -n1 --pretty=format:%cd --date=format:%Y%m%d%H%M.%S -- "{}") "{}"')

  echo "Checking for firmware updates..."
  cd "${MYPATH}"
  SRC=`ls -Lt "${SRCDIR}/../Firmware"/*.upg 2>/dev/null | head -1`
  DST=_firmware/`basename "${SRC}"`

  mkdir -p _firmware
  if [[ ! -f "${DST}" ]]; then
    cp -p "${SRC}" "${DST}"
    echo ==================
    echo FIRMWARE UPDATED!!! $DST | tee -a "${LOGFILE}"
    echo ==================
    echo 
  fi

  echo "Checking computer cores updates..."
  if [[ -d "${MYPATH}/Computer" ]]; then
    update_dir "${MYPATH}/Computer" "${BASEDIR}/git/SiDi-FPGA/cores/Computer"
  fi

  echo "Checking console cores updates..."
  if [[ -d "${MYPATH}/Console" ]]; then
    update_dir "${MYPATH}/Console" "${BASEDIR}/git/SiDi-FPGA/cores/Console"
  fi

  echo "Finished"
}

# Update the contents of a dir, using as reference the git information
update_dir () {
  CURRENTDIR=$1
  DIRTOCHECK=$2

  # Check all the cores in git with current matching directories 
  cd "${CURRENTDIR}"
  find . -maxdepth 1 -type d -not -path '*/_temp*' -print0  | while read -d $'\0' FILE
  do
    DIR="${FILE:2}"
    DST="${DIR}/${DIR}.rbf"

    # Change long file names to short
    DIR_ORIG=("ZX Spectrum" "ZX Spectrum 48K Kyp" "Sam Coupe" "Amstrad CPC")
    DIR_REPLACE=("spectrum" "zx48kyp" "samcoupe" "CPC")
    for i in "${!DIR_ORIG[@]}"; do
      if [[ "${DIR}" = "${DIR_ORIG[i]}" ]];then
        DST="${DIR}/${DIR_REPLACE[i]}.rbf"
      fi
    done

    # Find SiDi .rbf files
    SRC=`ls -Lt "${DIRTOCHECK}/${DIR}"/*.rbf 2>/dev/null | grep -i "_SiDi" | head -1`
    if [[ -z $SRC ]]; then
      # Find any .rbf file
      SRC=`ls -Lt "${DIRTOCHECK}/${DIR}"/*.rbf 2>/dev/null | head -1`
    fi

    if [[ -z "$SRC" || -z "${DST}" ]]; then
      continue
    fi 

    # Copy core file if changed
    cd "${CURRENTDIR}"
    copy_changed "$SRC" "${DST}"

    # Copy special ROMS if changed
    cd "${DIRTOCHECK}/${DIR}"
    DIR_ROMS=("Atari800" "BBC" "C16" "Next186" "QL" "Sam Coupe" "Speccy" "VIC20" "ZX Spectrum")
    for i in "${!DIR_ROMS[@]}"; do
      if [[ "${DIR}" = "${DIR_ROMS[i]}" ]];then
        find . -maxdepth 1 -type f -iname '*.ROM' -print0  | while read -d $'\0' ROM_FILE
        do
          cd "${CURRENTDIR}"
          copy_changed "${DIRTOCHECK}/${DIR}/${ROM_FILE:2}" "${DIR}/${ROM_FILE:2}"
        done
      fi
    done

  done
}

# Copy file if destination does not exist or if dates are different, or if content is different
copy_changed () {
  SRC=$1
  DST=$2

  if [[ -f "${SRC}" && ! -f "${DST}" ]]; then
    cp -p "${SRC}" "${DST}"
    echo Update $DST | tee -a "${LOGFILE}"
  else
    if [[ "${SRC}" -nt "${DST}" ]]; then
      cp -p "${SRC}" "${DST}"
      echo Update "${DST}" | tee -a "${LOGFILE}"
    else
      #Check checksum
      MD5SRC=`md5sum "${SRC}" | awk '{print $1}'`
      MD5DST=`md5sum "${DST}" | awk '{print $1}'`
  
      if [[ $MD5SRC != $MD5DST ]]; then
        cp -p "$SRC" "${DST}"
        echo Update $DST | tee -a "${LOGFILE}"
      fi
    fi
  fi
}

main "$@"
