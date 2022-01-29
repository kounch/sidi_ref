# Configuración de la tarjeta SD

## Ocultar ficheros

Útil cuando un Core (RBF) se invoca desde varios ficheros ARC

    chflags hidden /Volumes/SIDI_TEST/core.rbf

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

## Códigos de teclado

[https://www.hiemalis.org/~keiji/PC/scancode-translate.pdf]