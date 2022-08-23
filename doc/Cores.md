# Cores

## ARC

Los archivos ARC son ficheros de texto que contienen información adicional que relaciona un fichero RBF de core con un fichero de ROM. Además puede tener información extra de configuración del core. Son útiles cuando una única versión de un core se puede utilizar con distintos ficheros de ROM.

### Estructura

Se debe mantener el orden de estos elementos.

Elemento | Obligatorio | Explicación
---------|--------------|--------
[ARC]    | Sí           | Cabecera
RBF      | Sí           | Nombre en mayúsculas del fichero RBF sin extensión
NAME     | Sí           | Nombre en mayúsculas del fichero .ROM a cargar, sin extensión
MOD      | Sí           | Byte de configuración del core. Puede ser hexadecimal (`0x...`)
DEFAULT  | No           | Valor por defecto del estado del core
DIR      | No           | Directorio por defecto donde abrir archivos. Si no se indica, se usará `NAME`
CONF     | No           | Texto de configuración (si el core tiene `"DIP;"` definido). Una entrada por línea

El bit 0 del estado no se puede definir (se usa internamente para hacer reset).

Los nombres de ficheros ROM y RBF deberían ser de menos de 8 letras.

Por ejemplo, para ejecutar el Core de Spectrum (`spectrum.rbf`) con un conjunto de ROMs diferentes (`misroms.rom`), y con el directorio por defecto `Speccy`, se puede crear un fichero llamado `Mi ZX Spectrum.arc` con este contenido:

    [ARC]
    RBF=SPECTRUM
    NAME=MISROMS
    MOD=0
    DIR=SPECCY

## MRA

Los archivos MRA son ficheros XML de texto utilizados por la FPGA MiSTer para cargar directamente distintas versiones de ROM con un único core. Usando la versión de comandos de `mra` (en mra-tools), se pueden generar ficheros .ROM y .ARC para utilizar con SiDi.

### Obtener la utilidad mra

La versión para macOS se puede descargar [desde GitHub](https://github.com/kounch/mra-tools-c/tree/master/release/macos) o bien, compilarla uno mismo, siguiendo estos pasos (se necesita tener instalado XCode o las herramientas de comandos de XCode):

    git clone https://github.com/kounch/mra-tools-c.git
    cd mra-tools-c
    make

### Uso de la utilidad

Teniendo la utilidad `mra`, y, en un mismo directorio un fichero MRA, los ficheros ZIP necesarios (cuya versión y nombre se pueden averiguar inspeccionando las entradas `<setname>` y `<mameversion>`), se puede utilizar de esta manera para generar los ficheros .ROM y .ARC:

    .../mra -A <...fichero.MRA> -O <directorio destino>

## Modificar el contenido de una imagen de disco VHD

Montar la imagen desde Terminal con

    hdiutil attach -imagekey diskimage-class=CRawDiskImage /path_to_your_vhd

...y expulsarla al finalizar los cambios

## Spectrum

### Core ZX Spectrum

Basado en el core [ZX Spectrum 128K for MiST Board](https://github.com/mist-devel/mist-binaries/tree/master/cores/spectrum)

#### Teclado

`F1` - pausa/continuar (reproducción de cinta)

`F2` - retroceder al trozo anterior (durante el tono piloto) o al comienzo de la parte actual (en otro caso) (reproducción de cinta)

`F3` - Saltar a la siguiente parte (reproducción de cinta)

`F4` - CPU a velocidad normal (3.5MHz)

`F5` - CPU a 7MHz

`F6` - CPU a 14MHz

`F7` - CPU a 28MHz

`F8` - CPU a 56MHz

`F9` - Pausar/Continuar la CPU

`F10` - Entrar al menú +D de snapshot (con IMG/MGT montado), y si no, menú de Multiface. Con esxdos activo, menú NMI de esxdos

`Mayús Derecha+F10` - menú de Multiface 128 (o menú NMI de esxdos)

`F11` - Reinicio en caliente

`Alt+F11` - Reinicio en frío (como apagar y encender el Spectrum)

`Ctrl+F11` - Reinicio en caliente con auto carga

`F12` - Menú OSD del core

#### Fichero ROM

El fichero `spectrum.rom` (229K) tiene esta estructura

    esxdos (8K)
    esxdos (8K)
    TR-DOS (16K)
    Pentagon 128 ROM (32K)
    ZX Spectrum +2A EN ROM (64K)
    Plus DOS ROM (16K)
    Multiface 128 ROM (16K)
    Multiface 3 ROM (16K)
    ZX Spectrum ROM (16K)
    General Sound ROM (16K)

Se puede analizar y extraer su contenido con `ZX ROM Catalog`.

Para crear un fichero ROM nuevo, se puede hacer desde línea de comandos, uniendo todos los ficheros necesarios en el orden correcto:

    cat "esxdos ROM_0.8.8.ROM" "esxdos ROM_0.8.8.ROM" "TR-DOS ROM_5.04T.ROM" "32K Spectrum ROM_Pentagon 128.ROM" "64K Spectrum ROM_ZX Spectrum +2A EN.ROM" "G+DOS ROM_system 2a (MiST patched).ROM" "Multiface 128 ROM_87.2.ROM" "Multiface 3 ROM_3.C.ROM" "16K Spectrum ROM_ZX Spectrum.ROM" "General Sound ROM_1.05b.ROM" > "spectrum.rom"

#### Imagen VHD

Se puede crear una imagen de disco RAW para que utilice el core con esxdos (nombre por defecto `spectrum.vhd`)

Por ejemplo, siguiendo estos pasos, se puede tener una imagen de 2GB FAT16

1. Crear arhivo vacío (2G)

        dd if=/dev/zero of=spectrum.vhd bs=8m count=256

2. Crear particiones en el archivo

        fdisk -e spectrum.vhd
        fdisk: could not open MBR file /usr/standalone/i386/boot0: No such file or directory
        The signature for this MBR is invalid.
        Would you like to initialize the partition table? [y] y
        Enter 'help' for information
        fdisk:*1> erase
        fdisk:*1> edit 1
                    Starting       Ending
            #: id  cyl  hd sec -  cyl  hd sec [     start -       size]
        ------------------------------------------------------------------------
            1: 00    0   0   0 -    0   0   0 [         0 -          0] unused      
        Partition id ('0' to disable)  [0 - FF]: [0] (? for help) 6
        Do you wish to edit in CHS mode? [n]
        Partition offset [0 - 4194304]: [63] 128
        Partition size [1 - 4194176]: [4194176]
        fdisk:*1> flag 1
        Partition 1 marked active.
        fdisk:*1> w
        Writing MBR at offset 0.
        fdisk: 1> exit

3. Preparar el nuevo disco:

        hdiutil attach -imagekey diskimage-class=CRawDiskImage -nomount spectrum.vhd

4. Tomar nota de cuál es el nuevo dispositivo (en este ejemplo `/dev/disk7s1`) y formatear en FAT16:

        newfs_msdos -F 16 -v SPECTRUM -c 128 /dev/disk7s1
        hdiutil detach /dev/disk7

5. Montar imagen para poder copiar los ficheros que se quiera:

        hdiutil attach -imagekey diskimage-class=CRawDiskImage spectrum.vhd

### Core Speccy

Basado en el core [ZX_Spectrum-128K_MIST de 2016-06-12](https://github.com/sorgelig/ZX_Spectrum-128K_MIST/tree/bb24714d1e340ed57c69c173354021b39495a88a)

#### Atajos de Teclado

`F1` - pausa/continuar (reproducción de cinta)

`F2` - retroceder al trozo anterior (durante el tono piloto) o al comienzo de la parte actual (en otro caso) (reproducción de cinta)

`F3` - Saltar a la siguiente parte (reproducción de cinta)

`F4` - CPU a velocidad normal (3.5MHz)

`F5` - CPU a 7MHz

`F6` - CPU a 14MHz

`F7` - CPU a 28MHz

`F8` - CPU a 56MHz

`F11` - Inicializa esxdos. Posteriormente, llamada NMI de esxdos

`Ctrl+F11` - Reinicio en caliente

`Alt+F11` - Reinicio en frío (como apagar y encender el Spectrum)

`F12` - Menú OSD del core

#### Configuraciones

- Model Sinclair + Feature 48K/1024K = ZX Spectrum 48K video timings. Model Sinclair + Feature 128K = ZX Spectrum 128K video timings. 128KB memory available for both Sinclair features.

- Model Pentagon + Feature 128K = Pentagon 128 video timings with 128KB memory. Model Pentagon + Feature 128K/1024K = Pentagon 128 video timings with 1024KB available. Bits 7-5 of port 7FFD provide access to additional 896KB of RAM (Bit 5 doesn't lock 7FFD port).

#### Fichero de ROMs

El fichero `speccy.rom` (74K) tiene esta estructura

    Retroleum Diagnostic ROM (16K)
    TR-DOS ROM (16K)
    Pentagon 128 ROM (32K)
    esxdos (8K)

Se puede analizar y extraer su contenido con `ZX ROM Catalog`.

Para crear un fichero ROM nuevo, se puede hacer desde línea de comandos, uniendo todos los ficheros necesarios en el orden correcto:

    cat "Retroleum Diagnostic ROM_1.24.ROM" "TR-DOS ROM_5.04T.ROM" "32K Spectrum ROM_Pentagon 128.ROM" "esxdos ROM_0.8.5.ROM" > speccy.rom"

### Core ZX Spectrum 48K de Jozsef Laszlo

Basado en el core [MiST ZX Spectrum 48K](http://joco.homeserver.hu/fpga/mist_zx48_en.html)

#### Uso del Teclado

`F12` - Menú OSD del core

#### Fichero de ROM

El fichero `zx48.rom` (16K) contiene la ROM del Spectrum y se puede analizar con `ZX ROM Catalog`.

### Core ZX Spectrum Next

Basado en el core 

#### Teclado Spectrum Next

`F9` - NMI

#### Imagen VHD Spectrum Next

Se puede crear una imagen de disco RAW para que utilice el core con esxdos (nombre por defecto `zxn.vhd`)

Por ejemplo, siguiendo estos pasos, se puede tener una imagen de 2GB FAT32

1. Crear arhivo vacío (4G)

        dd if=/dev/zero of=zxnext.vhd bs=8m count=512

2. Crear particiones en el archivo

        fdisk -e zxnext.vhd
        fdisk: could not open MBR file /usr/standalone/i386/boot0: No such file or directory
        The signature for this MBR is invalid.
        Would you like to initialize the partition table? [y] y
        Enter 'help' for information
        fdisk:*1> erase
        fdisk:*1> edit 1
                Starting       Ending
        #: id  cyl  hd sec -  cyl  hd sec [     start -       size]
        ------------------------------------------------------------------------
        1: 00    0   0   0 -    0   0   0 [         0 -          0] unused  
        Partition id ('0' to disable)  [0 - FF]: [0] (? for help) b
        Do you wish to edit in CHS mode? [n] n
        Partition offset [0 - 8388608]: [63] 128
        Partition size [1 - 8388480]: [8388480] 
        fdisk:*1> flag 1
        Partition 1 marked active.
        fdisk:*1> w
        Writing MBR at offset 0.
        fdisk: 1> q

3. Preparar el nuevo disco:

        hdiutil attach -imagekey diskimage-class=CRawDiskImage -nomount zxnext.vhd

4. Tomar nota de cuál es el nuevo dispositivo (en este ejemplo `/dev/disk7s1`) y formatear en FAT16:

        newfs_msdos -F 32 -v ZXNEXT -b 4096 -c 128 /dev/rdisk7s1
        hdiutil detach /dev/disk7

5. Montar imagen para poder copiar los ficheros que se quiera:

        hdiutil attach -imagekey diskimage-class=CRawDiskImage zxnext.vhd

### Sintetizar Cores

Es posible instalar Quartus Lite (buscar el [instalador QuartusLiteSetup-17.1.0.590-windows.exe](https://fpgasoftware.intel.com/17.1/?edition=lite&platform=windows&download_manager=dlm3)), con [Wineskin](https://github.com/Gcenx/WineskinServer).

Usando `WineCX64Bit21.1.0` e invocando al instalador desde la Shell de Wine, se obtiene una versión funcional para, al menos, sintetizar cores sencillos.
