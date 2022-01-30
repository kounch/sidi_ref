#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# -*- mode: Python; tab-width: 4; indent-tabs-mode: nil; -*-
# Do not modify previous lines. See PEP 8, PEP 263.
"""
Copyright (c) 2020-2021, kounch
All rights reserved.

SPDX-License-Identifier: BSD-2-Clause

This is a tool that identifies ZX ROM files (Individual or for SiDi core)


Requires a zxrom_catalog.json file with hashes of the ROM files

"""

from __future__ import print_function
import os
import sys
import logging
import ssl
import ctypes
import argparse
from pathlib import Path
import json
from binascii import unhexlify
import hashlib

if os.name == 'nt':
    import msvcrt  # pylint: disable=import-error
if sys.version_info.major == 3:
    import urllib.request

__MY_VERSION__ = '0.0.1'

MAIN_URL = 'https://github.com/kounch/sidi_ref/raw/main/src'
MY_DIRPATH = os.path.dirname(sys.argv[0])
MY_DIRPATH = os.path.abspath(MY_DIRPATH)

IS_COL_TERM = False

LOGGER = logging.getLogger(__name__)
LOGGER.setLevel(logging.INFO)
LOG_FORMAT = logging.Formatter(
    '%(asctime)s [%(levelname)-5.5s] - %(name)s: %(message)s')
LOG_STREAM = logging.StreamHandler(sys.stdout)
LOG_STREAM.setFormatter(LOG_FORMAT)
LOGGER.addHandler(LOG_STREAM)

if sys.version_info < (3, 6, 0):
    LOGGER.error('This software requires Python version 3.6 or greater')
    sys.exit(1)

ssl._create_default_https_context = ssl._create_unverified_context  # pylint: disable=protected-access


def main():
    """Main routine"""

    enable_term_col()

    LOGGER.debug('Starting up...')
    arg_data = parse_args()

    fulldict_hash = load_json_bd()
    LOGGER.debug(fulldict_hash['version'])

    for input_path in arg_data['input_paths']:
        analyze_files(input_path, fulldict_hash, arg_data['show_hashes'],
                      False, arg_data['recurse'], arg_data['extract'],
                      arg_data['force'], arg_data['scan'])


def enable_term_col():
    """
    Enable TERM colours (Windows 10)
    https://stackoverflow.com/questions/53574442/how-to-reliably-test-color-capability-of-an-output-terminal-in-python3
    """

    global IS_COL_TERM  # pylint: disable=global-statement

    if os.name == 'nt':
        enable_virtual_terminal_processing = 4
        kernel32 = ctypes.WinDLL('kernel32', use_last_error=True)
        hstdout = msvcrt.get_osfhandle(sys.stdout.fileno())
        mode = ctypes.c_ulong()  # pylint: disable = no-value-for-parameter
        IS_COL_TERM = kernel32.GetConsoleMode(
            hstdout, ctypes.byref(mode)) and (
                mode.value & enable_virtual_terminal_processing != 0)

        if not IS_COL_TERM:
            IS_COL_TERM = kernel32.SetConsoleMode(
                hstdout, mode.value | enable_virtual_terminal_processing) > 0
    else:
        IS_COL_TERM = True


# https://ozzmaker.com/add-colour-to-text-in-python/
class Colours:
    """Colour handling for terminal"""
    BLACK = '\033[1;30m'
    RED = '\033[1;31m'
    GREEN = '\033[1;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[1;34m'
    PURPLE = '\033[1;35m'
    CYAN = '\033[1;36m'
    ENDC = '\033[m'


def printcol(str_col, str_txt, end=''):
    """Print with TERM colour"""
    if IS_COL_TERM:
        print(f'{str_col}{str_txt}{Colours.ENDC}', end=end)
    else:
        print(str_txt, end=end)


def parse_args():
    """
    Parses command line
    :return: Dictionary with different options
    """
    global LOGGER  # pylint: disable=global-statement

    values = {}
    values['input_paths'] = []
    values['recurse'] = False
    values['show_hashes'] = False
    values['extract'] = False
    values['force'] = False
    values['scan'] = False

    parser = argparse.ArgumentParser(description='ZX ROM Catalog Tool',
                                     epilog='Analyze ROM files')
    parser.add_argument('-v',
                        '--version',
                        action='version',
                        version=f'%(prog)s {__MY_VERSION__}')
    parser.add_argument('-i',
                        '--input_path',
                        required=False,
                        action='append',
                        dest='input_paths',
                        help='ROM File or directory')
    parser.add_argument('-r',
                        '--recurse',
                        required=False,
                        action='store_true',
                        dest='recurse',
                        help='Recurse directories')
    parser.add_argument('-s',
                        '--show_hashes',
                        required=False,
                        action='store_true',
                        dest='show_hashes',
                        help='Show computed hashes')
    parser.add_argument('-x',
                        '--extract',
                        required=False,
                        action='store_true',
                        dest='extract',
                        help='Extract all ROMs')
    parser.add_argument('-S',
                        '--scan',
                        required=False,
                        action='store_true',
                        dest='scan',
                        help='Scan for ROMs in Pack')

    parser.add_argument('--debug', action='store_true', dest='debug')

    arguments = parser.parse_args()

    if arguments.debug:
        printcol(Colours.PURPLE, 'Debugging Enabled!!', end='\n')
        LOGGER.setLevel(logging.DEBUG)

    LOGGER.debug(sys.argv)

    if arguments.input_paths:
        for input_file in arguments.input_paths:
            values['input_paths'].append(Path(input_file))

    if arguments.recurse:
        values['recurse'] = arguments.recurse

    if arguments.show_hashes:
        values['show_hashes'] = arguments.show_hashes

    if arguments.extract:
        values['extract'] = arguments.extract

    if arguments.scan:
        values['scan'] = arguments.scan

    return values


def load_json_bd(str_update=False, base_dir=None):
    """
    Loads the Hash Database
    :param str_file: Input file (to determine if update)
    :param output_file: Output file (to determine if update)
    :param str_update: Update parameter from options
    :return: Dictionary with Hashes from database
    """

    str_json = os.path.join(MY_DIRPATH, 'zxrom_catalog.json')
    if base_dir:
        str_json = os.path.join(base_dir, 'zxrom_catalog.json')

    fulldict_hash = {}
    # Update JSON
    if str_update:
        if os.path.isfile(str_json):
            os.remove(str_json)

    if not os.path.isfile(str_json):
        dl_url = MAIN_URL + '/zxrom_catalog.json'
        print('\nDownloading JSON database...', end='')
        urllib.request.urlretrieve(dl_url, str_json)
        print('OK')

    if not os.path.isfile(str_json):
        LOGGER.error('Hash database not found: %s', str_json)
    with open(str_json, 'r', encoding='utf-8') as json_handle:
        LOGGER.debug('Loading dictionary with hashes...')
        fulldict_hash = json.load(json_handle)
        LOGGER.debug('%s loaded OK', str_json)

    return fulldict_hash


def analyze_files(input_path,
                  fullhash_dict,
                  b_hashes=False,
                  b_ignore=False,
                  b_recurse=False,
                  b_extract=False,
                  b_force=False,
                  b_scan=False):
    """Analyzes the given path. If it's a file analyze it (and optionally
    extract all ROMs inside), or if it's a directory, check all children (with
    optional recursion)"""
    if input_path.is_dir():
        try:
            for child in input_path.iterdir():
                child_path = Path(input_path, child)
                if child_path.is_file():
                    analyze_file(child_path, fullhash_dict, b_hashes, True)
                elif child_path.is_dir() and b_recurse:
                    analyze_files(child_path, fullhash_dict, b_hashes, True,
                                  b_recurse)
        except PermissionError:
            LOGGER.error('Permission Error on %s', input_path)
    else:
        str_dir = input_path.parent
        analyze_file(input_path, fullhash_dict, b_hashes, b_ignore, str_dir,
                     b_extract, b_force, b_scan)


def analyze_file(input_file,
                 fullhash_dict,
                 b_hashes=False,
                 b_ignore=False,
                 str_dir='',
                 b_extract=False,
                 b_force=False,
                 b_scan=False):
    """Detect type and try to analyze a single file"""
    _, dict_hash, str_type = detect_file(input_file, fullhash_dict, b_ignore)
    if str_type != 'Unknown':
        printcol(Colours.BLACK, f'File: {input_file}', end='\n')
        LOGGER.debug('Analyzing %s (possibly %s...', input_file, str_type)
        find_roms(input_file, dict_hash, str_type, b_hashes, str_dir,
                  b_extract, b_force)
    else:
        if not b_ignore:
            print('Unknown file')

        if b_scan:
            scan_roms(input_file, dict_hash, b_hashes)


def detect_file(str_file, fulldict_hash, ignore_unknown=False):
    """
    Analyzes a file and tries to determine it's kind
    :param str_file: Input file to analyze
    :param fulldict_hash: Dictionary with hash database
    :return: Normalized extension, subDictionary of hashes and filetype
    """

    str_extension = os.path.splitext(str_file)[1]
    str_extension = str_extension[1:].upper()

    # Check that file extension is available in Hash Database
    dict_hash = {}
    for str_kind in fulldict_hash:
        if "extensions" in fulldict_hash[str_kind]:
            for str_tmp in fulldict_hash[str_kind]['extensions']:
                if str_tmp == str_extension:
                    dict_hash = fulldict_hash[str_kind]
                    break

    filetype = 'Unknown'
    if not dict_hash:
        if not ignore_unknown:
            LOGGER.error('Unknown file extension: %s', str_extension)
    else:
        # Is the file known?
        filetype = validate_file(str_file, dict_hash)

    return str_extension, dict_hash, filetype


def validate_file(str_in_file, hash_dict):
    """
    Try to detect file type from first bytes and/or size
    :param str_in_file: Path to file
    :param str_magic: String with the bytes to match
    :return: True if bytes match, False in other case
    """
    f_size = os.stat(str_in_file).st_size

    filetype = 'Unknown'
    for rom_pack in hash_dict.get('parts', {}):
        test_size = 0
        for rom_name in hash_dict['parts'][rom_pack]:
            rom_data = hash_dict.get(rom_name, {})
            test_size += rom_data.get('size', 0)

        if f_size == test_size:
            filetype = rom_pack
            break

    if filetype == 'Unknown':
        for rom_name in hash_dict:
            if 'size' in hash_dict[rom_name]:
                if f_size == hash_dict[rom_name]['size']:
                    filetype = 'ROM'
                    str_magic = hash_dict[rom_name].get('header', '')
                    b_magic = unhexlify(str_magic)
                    if b_magic:
                        b_validate = False
                        with open(str_in_file, "rb") as bin_file:
                            bin_data = bin_file.read(len(b_magic))
                            b_validate = validate_bin(bin_data, str_magic)
                        if b_validate:
                            filetype = rom_name
                            break

    return filetype


def validate_bin(bin_data, str_magic):
    """
    Try to detect data type from first bytes
    :param bin_data: binary data of file
    :param str_magic: String with the bytes to match
    :return: True if bytes match, False in other case
    """
    magic_bin = unhexlify(str_magic)
    if magic_bin:
        return magic_bin == bin_data[:len(magic_bin)]

    return False


def find_roms(str_in_file,
              hash_dict,
              str_type,
              show_hashes,
              str_dir='',
              extract=False,
              force=False):
    """
    Try to guess file from hash
    :param str_in_file: Path to file
    :param hash_dict: Dictionary with hashes for different blocks
    :param show_hashes: If True, print also found block hashes
    :param b_detail: If True, show extra info
    """

    if str_type in hash_dict['parts']:
        # ROM Pack
        print(f'{str_type}')
        with open(str_in_file, "rb") as in_zxdata:
            bin_offset = 0
            for rom_part in hash_dict['parts'][str_type]:
                bin_size = hash_dict.get(rom_part, {}).get('size', 0)
                LOGGER.debug('%s - %i:%i', rom_part, bin_offset, bin_size)
                bin_data = in_zxdata.read(bin_size)
                str_hash = hashlib.sha256(bin_data).hexdigest()
                str_version = 'Unknown'
                rom_dict = hash_dict.get(rom_part, {})
                if 'versions' in rom_dict:
                    rom_hash_dict = rom_dict['versions']
                    for hash_elem in rom_hash_dict:
                        if str_hash == rom_hash_dict[hash_elem]:
                            str_version = hash_elem
                            break
                printcol(Colours.BLUE, f'  {rom_part}')
                print(f' Version: {str_version}')
                if show_hashes:
                    print(f'Hash: {str_hash}')
                if extract:
                    str_outfile = os.path.join(
                        str_dir, f'{rom_part}_{str_version}.ROM')
                    export_bindata(bin_data, str_outfile, force)
                bin_offset += bin_size
    elif str_type in hash_dict:
        # ROM with known header and size
        str_hash = get_file_hash(str_in_file)
        str_version = get_data_version(str_hash, hash_dict[str_type])
        printcol(Colours.BLUE, f'{str_type}')
        print(f' Version: {str_version}')
        if show_hashes:
            print(f'Hash: {str_hash}')
    elif str_type == 'ROM':
        # Other ROM
        f_size = os.stat(str_in_file).st_size
        str_type = str_version = 'Unknown'
        for str_rom in hash_dict:
            if 'size' in hash_dict[str_rom]:
                if f_size == hash_dict[str_rom]['size']:
                    str_hash = get_file_hash(str_in_file)
                    str_vers = get_data_version(str_hash, hash_dict[str_rom])
                    if str_vers != 'Unknown':
                        str_type = str_rom
                        str_version = str_vers
                        break
        printcol(Colours.BLUE, f'{str_type}')
        print(f' Version: {str_version}')
        if show_hashes:
            print(f'Hash: {str_hash}')
    else:
        LOGGER.error('Unexpected ROM file type')


def scan_roms(str_in_file, hash_dict, show_hashes=False):
    """
    Try find known ROMs inside a file
    :param str_in_file: Path to file
    :param hash_dict: Dictionary with hashes for different blocks
    :param show_hashes: If True, print also found block hashes
    """

    printcol(Colours.BLACK, 'Scanning...', end='\n')
    f_size = os.stat(str_in_file).st_size
    with open(str_in_file, "rb") as in_zxdata:
        bin_offset = old_offset = 0
        b_scanning = False
        while bin_offset < f_size:
            if not b_scanning:
                printcol(Colours.BLACK, 'Offset:')
                print(f'{bin_offset} -> ', end='')
                b_scanning = True

            str_rom = 'Unknown'
            str_version = 'Unknown'
            for str_rom in hash_dict:
                if 'size' in hash_dict[str_rom]:
                    bin_size = hash_dict[str_rom]['size']
                    if bin_offset + bin_size <= f_size:
                        in_zxdata.seek(bin_offset, 0)
                        bin_data = in_zxdata.read(bin_size)
                        str_hash = hashlib.sha256(bin_data).hexdigest()
                        str_vers = get_data_version(str_hash,
                                                    hash_dict[str_rom])
                        if str_vers != 'Unknown':
                            str_version = str_vers
                            break

            if str_version != 'Unknown':
                if b_scanning:
                    if old_offset != bin_offset:
                        print('Unknown Block')
                        in_zxdata.seek(old_offset, 0)
                        bin_data = in_zxdata.read(bin_offset - old_offset)
                        tmp_hash = hashlib.sha256(bin_data).hexdigest()
                        if show_hashes:
                            print(f'Hash: {tmp_hash}')
                        printcol(Colours.BLACK, 'Offset:')
                        print(f'{bin_offset} -> ', end='')

                    b_scanning = False
                    old_offset = bin_offset + bin_size

                printcol(Colours.BLUE, f'  {str_rom}')
                print(f' Version: {str_version}')
                if show_hashes:
                    print(f'Hash: {str_hash}')
            else:
                bin_size = 1

            bin_offset += bin_size


def get_file_hash(str_in_file):
    """
    Get file sha26 hash
    :param str_in_file: Path to file
    :return: String with hash data
    """
    sha256_hash = hashlib.sha256()
    with open(str_in_file, "rb") as f_data:
        # Read and update hash string value in blocks of 4K
        for byte_block in iter(lambda: f_data.read(4096), b""):
            sha256_hash.update(byte_block)

    return sha256_hash.hexdigest()


def get_data_version(str_hash, hash_dict):
    """
    Obtain version string from hash
    :param str_hash: Hash string to check
    :param hash_dict: Dictionary with hashes for different blocks
    :return: List with version string and hash string
    """
    str_version = 'Unknown'

    if 'versions' in hash_dict:
        hash_dict = hash_dict['versions']

    for hash_elem in hash_dict:
        if str_hash == hash_dict[hash_elem]:
            str_version = hash_elem
            break

    return str_version


def export_bindata(bin_data, str_out_bin, b_force=False):
    """
    Extract binary data to file
    :param bin_data: Binary data
    :param str_out_bin: Path to bin file to create
    """
    if b_force or check_overwrite(str_out_bin):
        with open(str_out_bin, "wb") as out_zxdata:
            out_zxdata.write(bin_data)
            print(f'{str_out_bin} created OK.')


def check_overwrite(str_file):
    """
    Check if file exists. If so, ask permission to overwrite
    :param str_file: Path to file
    :return: Bool, if True, permission granted to overwrite
    """
    b_writefile = True
    if os.path.isfile(str_file):
        str_name = os.path.basename(str_file)
        b_ask = True
        while b_ask:
            chk_overwrite = input(f'{str_name} exists. Overwrite? (Y/N): ')
            if chk_overwrite.upper() == 'N' or chk_overwrite == '':
                b_writefile = False
                b_ask = False
            if chk_overwrite.upper() == 'Y':
                b_ask = False

    return b_writefile


if __name__ == "__main__":
    main()
