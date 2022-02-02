# Scripts de actualización para SiDi

Estos scripts permiten obtener la versión más reciente de uno o más cores del repositorio oficial, y luego sincronizar los que hayan cambiado a una tarjeta SD.

Están basados en [MIST FPGA update scripts](https://gist.github.com/squidrpi/4ce3ea61cbbfa3900e116f9565d45e74), pero aplicando cambios para hacerlos compatibles con macOS y la estructura del [Repositorio oficial de SiDi en GitHub](https://github.com/ManuFerHi/SiDi-FPGA/).

Para funcionar necesitan que [esté instalado git](https://git-scm.com/download/mac), y, a fecha de escribir este texto, un mínimo de 6G de espacio en el disco, y 2G en la tarjeta SD, si se utilizan todos los scripts con todos los cores.

## Modo de uso

### Actualizar cores de ordenadores y consolas

En primer lugar se debe crear, en la misma carpeta donde estén los scripts, una estructura indicando qué cores son los que se quier actualizar, imitando la estructura existente en el repositorio oficial.

Así, por ejemplo, si se quiere actualizar los cores `Amiga`, `Next186`, `ZX Spectrum` y `SNES`, se debería crear una estructura como la siguiente:

    |
    +-update_cores.sh
    |
    +-Computers/
    |   +-Amiga/
    |   +-Next186/
    |   +-ZX Spectrum/
    |
    +-Consoles/
        +-SNES/

Una vez esté todo, lanzar el script desde una shell de Terminal:

    .../update_cores.sh

La primera ejecución rellenará las carpetas con los ficheros de cores y ROM asociados y que se encuentren [en el repositorio](https://github.com/ManuFerHi/SiDi-FPGA).

Las siguientes veces que se lance sólo actualizará aquellos ficheros que hayan cambiado desde la ejecución anterior.

El script utiliza una carpeta llamada `_temp/git/SiDi-FPGA` para almacenar una copia del repositorio oficial.


### Actualizar cores de arcades

Lanzar el script desde una shell de Terminal el script que actualiz los cores de jotego:

    .../update_jtcores.sh

La primera ejecución rellenará las carpetas con los ficheros de cores y ROM asociados y que se encuentren [en el repositorio correspondiente](https://github.com/jotego/jtbin/tree/master/sidi).

Las siguientes veces que se lance sólo actualizará aquellos ficheros que hayan cambiado desde la ejecución anterior.

El script utiliza una carpeta llamada `_temp/git/jtbin` para almacenar una copia del repositorio oficial.

También utiliza una carpeta llamada `_temp/mame` para almacenar los ficheros zip con ROMs de [MAME](https://www.mamedev.org), que utiliza para construir los ficheros `.rom` para los cores. Si no encuentra algún fichero zip necesario, intenta descargarlo desde [Internet Archive](https://archive.org/download/mame-merged/mame-merged).

### Sincronizar a la tarjeta SD

Una vez puestos al día los ficheros de cores y ROM, usando el script anterior, se puede usar `sync_to_sd.sh` para copiar los que sean diferentes a una tarjeta SD.

Este script asume que la estructura de directorios en la tarjeta es como la siguiente:

    |
    +-Arcade
    |   +-JOTEGO-(..)
    |   |   +-jt...rbf
    |   |   +-...rom
    |   |   +-...arc
    |   |   (...)
    |   +-(..)
    |   (...)
    |
    +-Computers/
    |   +-Fichero1.rbf
    |   +-Fichero2.rbf
    |   (...)
    |      
    +-Consoles/
    |   +-Fichero1.rbf
    |   +-Fichero2.rbf
    |   (...)
    |
    +-Archivo1.rom
    +-Archivo2.rom
    (...)

Así, los ficheros de core (RBF) actualizados con `update_cores.sh` se copiarán todos juntos según su carpeta de origen (en `Computers`, etc.)

Para sincronizar los ficheros a la tarjeta SD, ejecutar el script desde una shell de terminal, indicando la ruta a la raíz de la tarjeta. Por ejemplo:

    ...sync_to_sd.sh /Volumes/SiDi

## License

BSD 2-Clause License

Copyright (c) 2022, kounch
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

- Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Text and documentation is licensed uncer CC BY 4.0
