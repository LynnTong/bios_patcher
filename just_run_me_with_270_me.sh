#!/usr/bin/env bash
set -e

echo "1. 开始提取donor me"
./ifdtool_src/ifdtool -x  -p sklkbl ./H27P1.00
cp -f ./flashregion_2_intel_me.bin deguard/me_donor.bin
rm -rf ./flashregion*.bin

echo "2. 开始提取待patch me"
./ifdtool_src/ifdtool -x  -p sklkbl ./DELL_DUMP.bin
rm -rf deguard/data/delta/optiplex_7050
cp -f ./flashregion_2_intel_me.bin ./deguard
rm -rf ./flashregion*.bin

echo "3.提取待 patch me 信息"
cd deguard
./generatedelta.py  --input ./flashregion_2_intel_me.bin --output data/delta/optiplex_7050
cd data/delta/optiplex_7050/home
rm -rf ./secureboot
rm -rf ./amt
rm -rf ./fwupdate
cd ../../../../

echo "4.根据 donor me 生成 deguard_me"
./finalimage.py --delta data/delta/optiplex_7050 --version 11.6.0.1126 --pch H --sku 2M --fake-fpfs data/fpfs/zero --input ./me_donor.bin --output me_deguard.bin
cp ./me_deguard.bin ../
rm ./me_deguard.bin
rm ./me_donor.bin
rm -rf data/delta/optiplex_7050
rm -rf ./flashregion_2_intel_me.bin
cd ..

echo "4.对烧录器固件进行patch"
./patch_fd_me.sh ./me_deguard.bin ./DELL_DUMP.bin
echo "8.删除工作目录"
rm -rf ./me_deguard.bin*
