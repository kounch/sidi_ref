#/bin/sh

#    Copyright (c) 2020-2021 @Kounch
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.


mypath=`dirname "$0"`
cd "${mypath}"

echo Copiando...
for f in *.qsf; do cp "$f" "$f.bak" ; done

echo Sustituyendo...

sed -i "" 's/Cyclone III/Cyclone IV/g' *.qsf
sed -i "" 's/EP3C25E144C8/EP4CE22F17C8/g' *.qsf
sed -i "" 's/PIN_7 /PIN_G1 /g' *.qsf
sed -i "" 's/PIN_54/PIN_E1/g' *.qsf
sed -i "" 's/PIN_55/PIN_M2/g' *.qsf
sed -i "" 's/PIN_144/PIN_P16/g' *.qsf
sed -i "" 's/PIN_143/PIN_P15/g' *.qsf
sed -i "" 's/PIN_142/PIN_R16/g' *.qsf
sed -i "" 's/PIN_141/PIN_R14/g' *.qsf
sed -i "" 's/PIN_137/PIN_T15/g' *.qsf
sed -i "" 's/PIN_135/PIN_T14/g' *.qsf
sed -i "" 's/PIN_133/PIN_J16/g' *.qsf 
sed -i "" 's/PIN_132/PIN_J15/g' *.qsf
sed -i "" 's/PIN_125/PIN_J14/g' *.qsf
sed -i "" 's/PIN_121/PIN_K16/g' *.qsf
sed -i "" 's/PIN_120/PIN_K15/g' *.qsf
sed -i "" 's/PIN_115/PIN_J13/g' *.qsf
sed -i "" 's/PIN_114/PIN_F16/g' *.qsf
sed -i "" 's/PIN_113/PIN_F15/g' *.qsf
sed -i "" 's/PIN_112/PIN_L16/g' *.qsf
sed -i "" 's/PIN_111/PIN_L15/g' *.qsf
sed -i "" 's/PIN_110/PIN_N15/g' *.qsf
sed -i "" 's/PIN_106/PIN_N16/g' *.qsf
sed -i "" 's/PIN_136/PIN_T10/g' *.qsf
sed -i "" 's/PIN_119/PIN_T11/g' *.qsf
sed -i "" 's/PIN_65/PIN_T12/g' *.qsf
sed -i "" 's/PIN_80/PIN_T13/g' *.qsf
sed -i "" 's/PIN_105/PIN_T2/g' *.qsf
sed -i "" 's/PIN_88/PIN_R1/g' *.qsf
sed -i "" 's/PIN_126/PIN_T3/g' *.qsf
sed -i "" 's/PIN_127/PIN_T4/g' *.qsf
sed -i "" 's/PIN_91/PIN_G15/g' *.qsf
sed -i "" 's/PIN_13 /PIN_H2 /g' *.qsf
sed -i "" 's/PIN_49/PIN_B14/g' *.qsf
sed -i "" 's/PIN_44/PIN_C14/g' *.qsf
sed -i "" 's/PIN_42/PIN_C15/g' *.qsf
sed -i "" 's/PIN_39/PIN_C16/g' *.qsf
sed -i "" 's/PIN_4 /PIN_B16 /g' *.qsf
sed -i "" 's/PIN_6 /PIN_A15 /g' *.qsf
sed -i "" 's/PIN_8 /PIN_A14 /g' *.qsf
sed -i "" 's/PIN_10 /PIN_A13 /g' *.qsf
sed -i "" 's/PIN_11 /PIN_A12 /g' *.qsf
sed -i "" 's/PIN_28/PIN_D16/g' *.qsf
sed -i "" 's/PIN_50/PIN_B13/g' *.qsf
sed -i "" 's/PIN_30/PIN_D15/g' *.qsf
sed -i "" 's/PIN_32/PIN_D14/g' *.qsf
sed -i "" 's/PIN_83/PIN_C3/g' *.qsf
sed -i "" 's/PIN_79/PIN_C2/g' *.qsf
sed -i "" 's/PIN_77/PIN_A4/g' *.qsf
sed -i "" 's/PIN_76/PIN_B4/g' *.qsf
sed -i "" 's/PIN_72/PIN_A6/g' *.qsf
sed -i "" 's/PIN_71/PIN_D6/g' *.qsf
sed -i "" 's/PIN_69/PIN_A7/g' *.qsf
sed -i "" 's/PIN_68/PIN_B7/g' *.qsf
sed -i "" 's/PIN_86/PIN_E6/g' *.qsf
sed -i "" 's/PIN_87/PIN_C6/g' *.qsf
sed -i "" 's/PIN_98/PIN_B6/g' *.qsf
sed -i "" 's/PIN_99/PIN_B5/g' *.qsf
sed -i "" 's/PIN_100/PIN_A5/g' *.qsf
sed -i "" 's/PIN_101/PIN_B3/g' *.qsf
sed -i "" 's/PIN_103/PIN_A3/g' *.qsf
sed -i "" 's/PIN_104/PIN_A2/g' *.qsf
sed -i "" 's/PIN_58/PIN_A11/g' *.qsf
sed -i "" 's/PIN_51/PIN_B12/g' *.qsf
sed -i "" 's/PIN_85/PIN_C9/g' *.qsf
sed -i "" 's/PIN_67/PIN_C8/g' *.qsf
sed -i "" 's/PIN_60/PIN_A10/g' *.qsf
sed -i "" 's/PIN_64/PIN_B10/g' *.qsf
sed -i "" 's/PIN_66/PIN_D8/g' *.qsf
sed -i "" 's/PIN_59/PIN_B11/g' *.qsf
sed -i "" 's/PIN_33/PIN_C11/g' *.qsf
sed -i "" 's/PIN_43/PIN_R4/g' *.qsf
sed -i "" 's/PIN_31/PIN_B1/g' *.qsf
sed -i "" 's/PIN_46/PIN_D1/g' *.qsf
sed -i "" 's/PIN_90/PIN_G16/g' *.qsf
