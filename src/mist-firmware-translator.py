#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# -*- mode: Python; tab-width: 4; indent-tabs-mode: nil; -*-
# Do not change the previous lines. See PEP 8, PEP 263.
"""
Mist firmware translator (text replacement in copy)

    Copyright (c) 2022 @Kounch

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
"""

import sys
import os
import argparse
import logging
import gettext
import shutil
import csv
from pathlib import Path

__MY_NAME__ = 'mist-firmware-translator.py'
__MY_VERSION__ = '0.1'

LOGGER = logging.getLogger(__name__)
LOGGER.setLevel(logging.INFO)
LOG_FORMAT = logging.Formatter(
    '%(asctime)s [%(levelname)-5.5s] - %(name)s: %(message)s')
LOG_STREAM = logging.StreamHandler(sys.stdout)
LOG_STREAM.setFormatter(LOG_FORMAT)
LOGGER.addHandler(LOG_STREAM)


def main():
    """Main Routine"""

    arg_data = parse_args()

    LOGGER.debug('Start...')

    dest_files = ['menu-8bit.c', 'menu.c']

    for str_file in dest_files:
        LOGGER.debug('Processing: %s...', str_file)
        dest_file = Path(arg_data['path'], str_file)
        orig_file = Path(arg_data['path'], str_file + '.bak')
        shutil.copy(dest_file, orig_file)

        with open(dest_file, newline='') as sourcefile:
            arr_lines = sourcefile.readlines()

        with open(arg_data['spath'], newline='') as csvfile:
            strreader = csv.reader(csvfile, delimiter='=', quotechar='"')
            for row in strreader:
                for i, str_line in enumerate(arr_lines):
                    if f'"{row[0]}"' in str_line:
                        arr_lines[i] = str_line.replace(f'"{row[0]}"', f'"{row[1]}"')

        with open(dest_file, 'w') as resultfile:
            resultfile.writelines(arr_lines)

    LOGGER.debug('Finished.')


# Functions
# ---------


def parse_args():
    """Command Line Parser"""

    parser = argparse.ArgumentParser(description='BAS translator')
    parser.add_argument('-v',
                        '--version',
                        action='version',
                        version='%(prog)s {}'.format(__MY_VERSION__))
    parser.add_argument('-s',
                        '--strings',
                        action='store',
                        dest='strings_path',
                        required=True,
                        help='Translation file path')
    parser.add_argument('-S',
                        '--source',
                        action='store',
                        required=True,
                        dest='source_path',
                        help='Path to source code')

    arguments = parser.parse_args()

    values = {}

    if arguments.strings_path:
        s_path = Path(arguments.strings_path)

    if arguments.source_path:
        o_path = Path(arguments.source_path)

    if not s_path.exists():
        LOGGER.error('Strings path not found: %s', s_path)
        raise IOError('Strings path does not exist!')

    if not o_path.exists():
        LOGGER.error('Source path not found: %s', o_path)
        raise IOError('There is no source path!')

    values['spath'] = s_path
    values['path'] = o_path

    return values


if __name__ == '__main__':
    main()
