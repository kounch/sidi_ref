# Configuración de la tarjeta SD

## Fichero mist.ini

[Documentación oficial](https://github.com/mist-devel/mist-board/wiki/DocIni) (en inglés)

### Varios

Si la placa tiene 64Mb, esto es necesario en el fichero

    sdram64=1                      ; set to 1 if you have a 64Mb SDRAM model, 0 for Stock 32Mb

Las últimas versiones permiten que, si se conecta vía USB al Mac, se vea el contenido de la SD como un disco (pero sólo de lectura), poniendo esto en la configuración

    usb_storage=1                  ; set to 1 and the device will appear as a mass-storage device in the OS (if you power it from an USB port of your computer)

### Joystick remap

Es posible asignar botones a un mando. Aunque las últimas versiones del firmware permiten gestionarlo desde el propio menú, esta es la forma de hacerlo manualmente.

Puede ser un poco confuso al principio. Lo primero, es tener claro qué código se debe usar para indicar el botón que se quiere que la SiDi interprete, según esta numeración (hexadecimal):

    00001 right
    00002 left
    00004 down
    00008 up
    00010 A
    00020 B
    00040 Sel
    00080 Start
    00100 X
    00200 Y
    00400 L
    00800 R
    01000 L2
    02000 R2
    04000 L3
    08000 R3
    10000 right 2
    20000 left  2
    40000 down  2
    80000 up    2

Ahora, tras ver cómo se identifica el mando en el menú (`VID` Y `PID`), y en qué orden detecta los botones, se ha de asignar así:

    joystick_remap=VID,PID,mapeo del botón 1, mapeo del botón 2, ...

Por ejemplo, si el botón A del mando es visto como botón 1 (es decir, por defecto lo ve como cursor derecho), y nosotros queremos que se use como A

    joystick_remap=VID,PID,10, ...

Algunos ejemplos de mapeos:

    joystick_remap=0810,e501,1,2,4,8,200,20,10,100,40,0,400,800,1000,80 ; SIDI 
    joystick_remap=06f8,a300,1,2,4,8,400,1000,800,2000,100,200,20,10,4000,8000,40,80  ; Gillemot Dual Leader
    joystick_remap=054c,0cda,1,2,4,8,200,20,10,100,1000,2000,400,800,40,80 ; Playstation Classic
    joystick_remap=20d6,a710,1,2,4,8,100,10,20,200,400,800,1000,2000,40,80,4000,8000 ; Mayflash Magic-NS (Red)
    joystick_remap=20d6,a710,1,2,4,8,100,10,20,200,400,800,1000,2000,40,80,4000,8000,40000,80000,10000,20000 ; Mayflash Magic-NS (Red)

### Asignar teclas a botones del joystick

Muy útil para manejar menús, cores, etc. sin conectar un teclado. Se hace asociando un código (o suma de códigos) del mando (ver lista más arriba), a un código de tecla (véase la tabla de referencia [más abajo](#Códigos-de-teclado))

    joy_key_map=código del mando, código del teclado

Por ejemplo, para asociar la pulsación simultánea de `L+R` (`0x400 + 0x800 = 0xC00`) a la tecla Esc (`29`)

    joy_key_map=C00,29

Así, para los cores Arcade Gehstock, estas asignaciones pueden ser útiles

`L -> P1 Start (F1)`
`R -> P2 Start (F2)`
`L+R -> Insert Coin (Esc)`

Y se pueden asignar (si el core se inicia desde `Tetris.arc`) poniendo esto en `mist.ini`

    [Tetris]
    joy_key_map=400,3A
    joy_key_map=800,3B
    joy_key_map=C00,29

## Ocultar ficheros de core

Útil cuando un core (RBF) se invoca desde varios [ficheros ARC](./Cores.md#ARC), y sólo se quieren ver estos últimos. Por ejemplo:

    chflags hidden /Volumes/SiDi/Arcade/JOTEGO-CPS1/jtcps1.rbf

Para volver a hacer visible el fichero:

    chflags nohidden /Volumes/SiDi/Arcade/JOTEGO-CPS1/jtcps1.rbf

## Incluir cores en subdirectorios

Este procedimiento sólo es válido para discos formateados con FAT16 o FAT32. Para unidades con formato exFat, se ha de usar otro sistema operativo que no sea macOS.

Primero se han de instalar [mtools](https://www.gnu.org/software/mtools/), por ejemplo, usando [Homebrew](https://brew.sh):

    brew install mtools

Averiguar el dispositivo asociado a la tarjeta SD

    diskutil list

Editar .mtoolsrc (en este ejemplo, el dispositivo encontrado es `/dev/disk6s1`)

    drive s: file="/dev/disk6s1"
    mtools_skip_check=1 

Desmontar la unidad

    diskutil unmount /dev/disk6s1

Ejecutar, con permisos elevados, el comando `mattrib` para añadir permisos a todos los directorios donde haya archivos RBF de core (incluyendo los directorios superiores, si los hubiera).

Por ejemplo, para los directorios `Computer` y `Console` en la raíz de la tarjeta:

    sudo mattrib +s s:/Computer
    sudo mattrib +s s:/Console

Finalmente, expulsar la SD completa para usarla:

    diskutil unmountDisk /dev/disk6

## Códigos de teclado

"HID Usage ID" obtenido desde [este documento](https://www.hiemalis.org/~keiji/PC/scancode-translate.pdf).

Key Name           |HID Usage ID
-------------------|------------
System Power       |81
System Sleep       |82
System Wake        |83
No Event           |00
Overrun Error      |01
POST Fail          |02
ErrorUndefined     |03
aA                 |04
bB                 |05
cC                 |06
dD                 |07
eE                 |08
fF                 |09
gG                 |0A
hH                 |0B
iI                 |0C
jJ                 |0D
kK                 |0E
lL                 |0F
mM                 |10
nN                 |11
oO                 |12
pP                 |13
qQ                 |14
rR                 |15
sS                 |16
tT                 |17
uU                 |18
vV                 |19
wW                 |1A
xX                 |1B
yY                 |1C
zZ                 |1D
1!                 |1E
2@                 |1F
3#                 |20
4$                 |21
5%                 |22
6^                 |23
7&                 |24
8*                 |25
9(                 |26
0\)                |27
Return             |28
Escape             |29
Backspace          |2A
Tab                |2B
Space              |2C
-_                 |2D
=+                 |2E
[{                 |2F
]}                 |30
\|                 |31
Europe 1**         |32
;:                 |33
'"                 |34
`~                 |35
,<                 |36
.>                 |37
/?                 |38
Caps Lock          |39
F1                 |3A
F2                 |3B
F3                 |3C
F4                 |3D
F5                 |3E
F6                 |3F
F7                 |40
F8                 |41
F9                 |42
F10                |43
F11                |44
F12                |45
Print Screen       |46
Scroll Lock        |47
Break (Ctrl-Pause) |48
Pause              |48
Insert             |49
Home               |4A
Page Up            |4B
Delete             |4C
End                |4D
Page Down          |4E
Right Arrow        |4F
Left Arrow         |50
Down Arrow         |51
Up Arrow           |52
Num Lock           |53
Keypad /           |54
Keypad *           |55
Keypad -           |56
Keypad +           |57
Keypad Enter       |58
Keypad 1 End       |59
Keypad 2 Down      |5A
Keypad 3 PageDn    |5B
Keypad 4 Left      |5C
Keypad 5           |5D
Keypad 6 Right     |5E
Keypad 7 Home      |5F
Keypad 8 Up        |60
Keypad 9 PageUp    |61
Keypad 0 Insert    |62
Keypad . Delete    |63
Europe 2**         |64
App                |65
Keyboard Power     |66
Keypad =           |67
F13                |68
F14                |69
F15                |6A
F16                |6B
F17                |6C
F18                |6D
F19                |6E
F20                |6F
F21                |70
F22                |71
F23                |72
F24                |73

Nota **: Estas teclas pueden variar según el idioma de fabricación del teclado. Europe 1 suele estar en la posición 42 (AT-101), al lado de la tecla Enter. Europe 2 suele estar en la posición 42 (AT-101), Entre la tecla de mayúsculas y la Z.
