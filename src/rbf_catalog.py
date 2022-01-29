#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# -*- mode: Python; tab-width: 4; indent-tabs-mode: nil; -*-
# Do not modify previous lines. See PEP 8, PEP 263.
"""
Copyright (c) 2020-2021, kounch
All rights reserved.

SPDX-License-Identifier: BSD-2-Clause

This is a tool that identifies RBF files (SiDi FPGA cores)


Requires a rbf_catalog.json file with hashes of the core files

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

MAIN_URL = 'https://raw.githubusercontent.com/kounch/zx123_tool/main'
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

    if arg_data['stats']:
        print_stats(fulldict_hash, arg_data['detail'])
        sys.exit(0)

    for input_path in arg_data['input_paths']:
        analyze_files(input_path, fulldict_hash, arg_data['show_hashes'],
                      arg_data['check_updated'], arg_data['detail'], False,
                      arg_data['recurse'])


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
    values['check_updated'] = False
    values['detail'] = False
    values['stats'] = False

    parser = argparse.ArgumentParser(description='RBF Tool',
                                     epilog='Analyze RBF files')
    parser.add_argument('-v',
                        '--version',
                        action='version',
                        version=f'%(prog)s {__MY_VERSION__}')
    parser.add_argument('-i',
                        '--input_path',
                        required=False,
                        action='append',
                        dest='input_paths',
                        help='RBF File or directory')
    parser.add_argument('-r',
                        '--recurse',
                        required=False,
                        action='store_true',
                        dest='recurse',
                        help='Recurse directories')
    parser.add_argument('-q',
                        '--check',
                        required=False,
                        action='store_true',
                        dest='check_updated',
                        help='Check if cores are up to date')
    parser.add_argument('-s',
                        '--show_hashes',
                        required=False,
                        action='store_true',
                        dest='show_hashes',
                        help='Show computed hashes')
    parser.add_argument('-D',
                        '--details',
                        required=False,
                        action='store_true',
                        dest='detail',
                        help='Show Core Features')
    parser.add_argument('--stats', action='store_true', dest='stats')
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

    if arguments.check_updated:
        values['check_updated'] = arguments.check_updated

    if arguments.detail:
        values['detail'] = arguments.detail

    if arguments.stats:
        values['stats'] = arguments.stats

    return values


def load_json_bd(str_update=False, base_dir=None):
    """
    Loads the Hash Database
    :param str_file: Input file (to determine if update)
    :param output_file: Output file (to determine if update)
    :param str_update: Update parameter from options
    :return: Dictionary with Hashes from database
    """

    str_json = os.path.join(MY_DIRPATH, 'rbf_catalog.json')
    if base_dir:
        str_json = os.path.join(base_dir, 'rbf_catalog.json')

    fulldict_hash = {}
    # Update JSON
    if str_update:
        if os.path.isfile(str_json):
            os.remove(str_json)

    if not os.path.isfile(str_json):
        dl_url = MAIN_URL + '/rbf_catalog.json'
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
                  b_check=False,
                  b_detail=False,
                  b_ignore=False,
                  b_recurse=False):
    """Analyzes the given path. If it's a file analyze it, or if it's a
    directory, check all children (with optional recursion)"""
    if input_path.is_dir():
        try:
            for child in input_path.iterdir():
                child_path = Path(input_path, child)
                if child_path.is_file():
                    analyze_file(child_path, fullhash_dict, b_hashes, b_check,
                                 b_detail, True)
                elif child_path.is_dir() and b_recurse:
                    analyze_files(child_path, fullhash_dict, b_hashes, b_check,
                                  b_detail, True, b_recurse)
        except PermissionError:
            LOGGER.error('Permission Error on %s', input_path)
    else:
        analyze_file(input_path, fullhash_dict, b_hashes, b_check, b_detail,
                     b_ignore)


def analyze_file(input_file,
                 fullhash_dict,
                 b_hashes=False,
                 b_check=False,
                 b_detail=False,
                 b_ignore=False):
    """Detect type and try to analyze a single file"""
    _, dict_hash, str_type = detect_file(input_file, fullhash_dict, b_ignore)
    if str_type != 'Unknown':
        print(f'File: {input_file}')
        LOGGER.debug('Analyzing %s (possibly %s...', input_file, str_type)
        find_core(input_file, dict_hash, b_hashes, b_check, b_detail)
    else:
        if not b_ignore:
            print('Unknown file')


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
        # Is the file header known?
        if validate_file(str_file, dict_hash['parts']['header']):
            filetype = dict_hash['description']

    return str_extension, dict_hash, filetype


def validate_file(str_in_file, str_magic):
    """
    Try to detect file type from first bytes
    :param str_in_file: Path to file
    :param str_magic: String with the bytes to match
    :return: True if bytes match, False in other case
    """
    magic_bin = unhexlify(str_magic)
    if str_magic:
        try:
            with open(str_in_file, "rb") as bin_file:
                bin_data = bin_file.read(len(magic_bin))
                b_validate = validate_bin(bin_data, str_magic)
        except FileNotFoundError:
            b_validate = False

        return b_validate

    return False


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


def find_core(str_in_file,
              hash_dict,
              show_hashes,
              check_updated=False,
              b_detail=False):
    """
    Try to guess file from hash
    :param str_in_file: Path to file
    :param hash_dict: Dictionary with hashes for different blocks
    :param show_hashes: If True, print also found block hashes
    :param b_detail: If True, show extra info
    """
    found = False

    dict_res = {}
    dict_res['detail'] = {}

    str_file_hash = get_file_hash(str_in_file)
    dict_res['hash'] = str_file_hash
    if show_hashes:
        print(f'Hash: {str_file_hash}')

    # Check if it's a Core
    for core in hash_dict.get('cores', {}):
        platforms = hash_dict['cores'][core].get('platforms', {})
        for platform in platforms:
            block_version = get_data_version(str_file_hash,
                                             platforms[platform])
            if block_version != 'Not found':
                found = True
                print(f'Core: {core} - Version: {block_version}', end='')
                if check_updated:
                    latest_version = block_version
                    for version in platforms[platform].get('versions', {}):
                        if version > block_version:
                            latest_version = version

                    if latest_version == block_version:
                        printcol(Colours.GREEN, '  >> Up to date', end='')
                    else:
                        printcol(
                            Colours.YELLOW,
                            f'  >> Outdated!. Latest version: {latest_version}',
                            end='')
                print('')

                dict_res['kind'] = 'Core'
                dict_res['version'] = f'{core}: {block_version}'
                if b_detail:
                    printcol(Colours.BLUE,
                             f' Features of "{core}" Cores:',
                             end='\n')
                    dict_det = hash_dict['cores'][core].get('features', {})
                    print_detail(core, dict_det)
                    dict_res['detail'] = dict_det
                break

    if not found:
        print('Unknown core')

    return dict_res


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
    str_version = 'Not found'

    if 'versions' in hash_dict:
        hash_dict = hash_dict['versions']

    for hash_elem in hash_dict:
        if str_hash == hash_dict[hash_elem]:
            str_version = hash_elem
            break

    return str_version


def print_detail(str_name, dict_det):
    """Print detailed info"""

    if dict_det:
        for str_feature in dict_det:
            arr_feat, str_note = dict_det[str_feature]
            if arr_feat[0]:
                printcol(Colours.BLUE, f'   {str_feature}: ', end='')
                print(f'{", ".join(arr_feat)}', end='')
                if str_note:
                    print(f' ({str_note})', end='')
                print('')
        print('')
    else:
        printcol(Colours.RED,
                 f' No details available for {str_name}',
                 end='\n')


def print_stats(fulldict_hash, b_detail=False):
    """Show Stats"""

    print('')
    printcol(Colours.CYAN, 'JSON Database Stats', end='\n')
    print('')
    if 'version' in fulldict_hash:
        print(f'Version: {fulldict_hash["version"]}')
    print('')

    LOGGER.debug('Detail: %s', b_detail)

    total = 0
    total_hashes = 0

    for str_kind in fulldict_hash:
        if str_kind != 'version':
            if 'description' in fulldict_hash[str_kind]:
                print(fulldict_hash[str_kind]['description'])
            for core in fulldict_hash[str_kind].get('cores', {}):
                subtotal = 0
                subtotal_hashes = 0

                platforms = fulldict_hash[str_kind]['cores'][core].get(
                    'platforms', {})
                count, part = count_hashes(platforms)
                if count:
                    if b_detail:
                        print(f'{core}: {len(part):>4} ({count:03} hashes)')
                    subtotal += len(part)
                    subtotal_hashes += count

                total += subtotal
                total_hashes += subtotal_hashes

    print('')
    print(f'Total Cores: {total:>4} ({total_hashes:03} hashes)')
    print('')


def count_hashes(subdict_hash):
    """Used by print_stats to count elements and hashes"""

    i_cnt = 0
    dict_cnt = {}
    for chld in subdict_hash:
        if 'versions' in subdict_hash[chld]:
            i_hashes = len(subdict_hash[chld]['versions'])
            i_cnt += i_hashes
            dict_cnt[chld] = i_hashes

    return i_cnt, dict_cnt


if __name__ == "__main__":
    main()
