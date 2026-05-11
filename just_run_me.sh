#!/usr/bin/env bash
set -e

echo "开始提取deguard_me"
./ifdtool_src/ifdtool -x  -p sklkbl ./DELL_DUMP.bin

echo "1.拷贝工作文件"
rm -rf deguard/data/delta/optiplex_7050
cp -f ./flashregion_2_intel_me.bin ./deguard

echo "2.删除多余文件"
rm -rf ./flashregion*.bin
cd deguard
./generatedelta.py  --input ./flashregion_2_intel_me.bin --output data/delta/optiplex_7050
cd data/delta/optiplex_7050/home
rm -rf ./secureboot
rm -rf ./amt
rm -rf ./fwupdate
cd ../../../../

echo "3.生成deguard_me"
./finalimage.py --delta data/delta/optiplex_7050 --version 11.6.0.1126 --pch H --sku 2M --fake-fpfs data/fpfs/zero --input ./me_donor.bin --output me_deguard.bin
cp ./me_deguard.bin ../
rm ./me_deguard.bin
rm -rf deguard/data/delta/optiplex_7050
cd ..

echo "4.对烧录器固件进行patch"
./patch_fd_me.sh ./me_deguard.bin ./DELL_DUMP.bin
echo "8.删除工作目录"
rm -rf deguard/data/delta/medisable
