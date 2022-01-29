# Cores

## Modificar el contenido de una imagen de disco VHD

Montar la imagen desde Terminal con

    hdiutil attach -imagekey diskimage-class=CRawDiskImage /path_to_your_vhd

...y expulsarla al finalizar los cambios

## Spectrum

### Core ZX Spectrum 128K for MiSTer Board

Basado en [https://github.com/mist-devel/mist-binaries/tree/master/cores/spectrum]

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
`F12` - Menú OSD del Core

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

#### Imagen VHD

Se puede crear una imagen de disco RAW para que utilice el core (nombre por defecto `spectrum.vhd`)

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

3. Formatear partición

    hdiutil attach -imagekey diskimage-class=CRawDiskImage -nomount spectrum.vhd
    newfs_msdos -F 16 -v SPECTRUM -c 128 /dev/disk7s1
    hdiutil detach /dev/disk7

Montar imagen y copiar ficheros

    hdiutil attach -imagekey diskimage-class=CRawDiskImage spectrum.vhd

### Core Speccy

Basado en [https://github.com/sorgelig/ZX_Spectrum-128K_MIST/tree/bb24714d1e340ed57c69c173354021b39495a88a] (ZX_Spectrum-128K_MIST de 2016-06-12)

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

#### Configuraciones

- Model Sinclair + Feature 48K/1024K = ZX Spectrum 48K video timings. Model Sinclair + Feature 128K = ZX Spectrum 128K video timings. 128KB memory available for both Sinclair features.

- Model Pentagon + Feature 128K = Pentagon 128 video timings with 128KB memory. Model Pentagon + Feature 128K/1024K = Pentagon 128 video timings with 1024KB available. Bits 7-5 of port 7FFD provide access to additional 896KB of RAM (Bit 5 doesn't lock 7FFD port).

#### Fichero de ROMs

El fichero `speccy.rom` (74K) tiene esta estructura

    Retroleum Diagnostic ROM (16K)
    TR-DOS ROM (16K)
    Pentagon 128 ROM (32K)
    esxdos (8K)

### Sintetizar Cores

Es posible instalar Quartus Lite (buscar el instalador QuartusLiteSetup-17.1.0.590-windows.exe), con Wineskin.

Usando `WineCX64Bit21.1.0` e invocando al instalador desde la Shell de Wine, se tiene una versión funcional para sintetizar cores sencillos.
