# Utilidades para SiDi

## RBF Catalog

Permite identificar ficheros RBF de cores de SiDi.

Es un script que puede invocar directamente usando Python (versión 3.6 o superior), (por ej. `python3 rbf_catalog.py -i SPECTRUM.RBF`)

### Argumentos

    -h, --help                   Mostrar ayuda
    -v, --version                Mostrar la versión del script
    -i INPUT_PATHS, --input_path RUTA a un fichero RBF o a un directorio
    -r, --recurse                Si se indica(n) directorio(s), buscar recursivamente
    -q, --check                  Indicar si la versión de los cores es la más reciente conocida
    -s, --show_hashes            Mostrar los datos hash de los ficheros

### Ejemplos

Mostrar información de un fichero de core:

    python3 rbf_catalog.py -i SPECTRUM.RBF

Mostrar información de todos los ficheros RBF dentro de un directorio:

    python3 rbf_catalog.py -i ...directorio

Mostrar información de todos los ficheros RBF dentro de un directorio y sus subdirectorios:

    python3 rbf_catalog.py -ri ...directorio

Mostrar información de todos los ficheros RBF dentro de un directorio y sus subdirectorios, indicando si son la última versión conocida o no:

    python3 rbf_catalog.py -rqi ...directorio

### Archivo JSON de RBF

El archivo `rbf_catalog.json` es un objeto donde los nombres principales indican distintas plataformas de FPGA (por el momento sólo "sidi") y tiene la siguiente estructura:

    "version":                          -> Fecha de modificación del JSON
    "(plataforma)": {                   -> Por ahora, sólo "sidi"
        "description":                  -> Descripción de la plataforma
        "hashtype":                     -> "sha256sum" por el momento
        "extensions": ["(Extension)", .... ]
        "parts": {
            "header":                   -> Cabecera identificadora de un fichero de core   
        },
        "cores": {
            "(Nombre de core)": {
                "platforms": {
                    "(plataforma)": {   -> Por ahora, sólo "sidi"
                        "versions": {   -> Diccionario con hashes
                            "(Descripción de versión)": "(Hash)"
                        },
                    (...)
                    },
                (...)
                },
            (...)
            },
        (...)
        }
    }

## ZX ROM Catalog

Permite identificar tanto ficheros con ROM de ZX Spectrum y algunos de sus dispositivos (Multiface, esxdos, etc.) como los ficheros utilizados por los distintos cores de ZX Spectrum, donde hay varias ROM concatenadas (pack).

Es un script que puede invocar directamente usando Python (versión 3.6 o superior), (por ej. `python3 zxrom_catalog.py -i SPECTRUM.ROM`)

### Argumentos de comandos

    -h, --help                   Mostrar ayuda
    -v, --version                Mostrar la versión del script
    -i INPUT_PATHS, --input_path RUTA a un fichero RBF o a un directorio
    -r, --recurse                Si se indica(n) directorio(s), buscar recursivamente
    -s, --show_hashes            Mostrar los datos hash de los ficheros
    -x, --extract                Extraer las todas ROMs de un pack a ficheros individuales
    -S, --scan                   Si es un pack desconocido, buscar en el interior ROMs individuales conocidas

### Ejemplos de uso

Mostrar información de un fichero de ROM:

    python3 zxrom_catalog.py -i SPECTRUM.ROM

Mostrar información de todos los ficheros ROM dentro de un directorio:

    python3 zxrom_catalog.py -i ...directorio

Mostrar información de todos los ficheros ROM dentro de un directorio y sus subdirectorios:

    python3 zxrom_catalog.py -ri ...directorio

Extraer los ficheros ROM individuales dentro de un pack:

    python3 zxrom_catalog.py -xi ...fichero.rom

Investigar un fichero desconocido que contiene ROMs individuales:

    python3 zxrom_catalog.py --scan -i ...fichero.rom

### Archivo JSON de ROMs

El archivo `zxrom_catalog.json` es un objeto donde los nombres principales indican distintas plataformas de FPGA (por el momento sólo "sidi") y tiene la siguiente estructura:

    "version":                 -> Fecha de modificación del JSON
    "ROM": {                   -> Extensión de los ficheros ROM
        "description":         -> Descripción de los ficheros
        "hashtype":            -> "sha256sum" por el momento
        "extensions": ["(Extension)", .... ]
        "parts": {
            "(nombre de pack de ROMS": [
                "(nombre de ROM individual)", 
                "(nombre de ROM individual)",
                (...)
            ] 
        },
        (...)
        "(nombre de ROM individual)": {
            "size":           -> Tamaño de la ROM en bytes
            "header":         -> Cabecera identificadora (si la hay)
            "versions": {     -> Diccionario con hashes
                "(Descripción de versión)": "(Hash)",
                    (...)
            },
        },
        (...)
    }

## macOS_install_arm-none-eabi-gcc.sh

Script que permite instalar lo necesario en macOS para [compilar el firmware](../doc/Firmware.md#Compilación-del-firmware) de la placa.

## SiDi FPGA update scripts

Conjunto de scripts que permiten obtener las versiones más recientes de cores del repositorio oficial.

[Ver aquí para más detalles](<./Sidi FPGA update scripts/>)

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
