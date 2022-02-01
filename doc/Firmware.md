# Firmware

## Flash

Como el firmware es compartido con otras placas, se puede obtener siempre la última versión en [el repositorio GitHub de MiST](https://github.com/mist-devel/mist-binaries/tree/master/firmware).

### MacOS

El programa [BOSSA](https://github.com/shumatech/BOSSA/releases) permite actualizar la Flash directamente desde macOS.

### Windows (Virtual)

También se puede hacer desde una máquina virtual de Windows que tenga acceso al puerto USB donde esté conectada la placa. Normalmente, las máquinas virtuales con Windows 7 funcionan sin problemas.

Se debe descargar la versión de sam-ba 2.16 desde [la web oficial](https://www.microchip.com/en-us/development-tool/SAM-BA-In-system-Programmer), en [este enlace](https://ww1.microchip.com/downloads/en/DeviceDoc/sam-ba_2.16_windows.exe).

## Compilación del firmware

Primero es necesario instalar en macOS `mpc`. Lo mas sencillo suele ser utilizar [Homebrew](https://brew.sh):

    brew install mpc

Descargar el [script](https://raw.githubusercontent.com/mist-devel/mist-board/master/tools/install_arm-none-eabi-gcc.sh) modificado desde este mismo repositorio: [macOS_install_arm-none-eabi-gcc.sh](https://github.com/kounch/sidi_ref/raw/main/src/macOS_install_arm-none-eabi-gcc.sh)

Crear una imagen de disco, al menos de 2500MBytes de espacio y con soporte para mayúsculas y minúsculas (necesario para que funcionen bien las utilidades basadas en Linux)

    hdiutil create -size 2500M -fs HFSX -volname sidibuild -partitionType Apple_HFS -attach sidibuild

Copiar al nuevo disco el archivo que se ha bajado, iniciar Terminal y compilar en la imagen de disco:

    cd /Volumes/sidibuild/
    ./install_arm-none-eabi-gcc.sh

Obtener último firmware

    cd /Volumes/sidibuild/src
    git clone https://github.com/mist-devel/mist-firmware.git

    export PATH=/Volumes/sidibuild/arm-none-eabi/bin:$PATH
    cd /Volumes/sidibuild/src/mist-firmware/
    make

Una vez acabe, si no hay errores, el el directorio estará tanto el fichero `.bin` como el fichero `.upg`.
