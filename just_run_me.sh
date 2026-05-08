#!/usr/bin/env bash
set -e

echo "提取deguard_me"
./ifdtool_src/ifdtool -x  -p sklkbl ./H11MDGS7.30

echo "拷贝工作文件"
rm -rf deguard/data/delta/medisable
mkdir deguard/data/delta/medisable
cp -f ./flashregion_2_intel_me.bin deguard/data/delta/medisable
echo "删除多余文件"
rm -rf ./flashregion*.bin

echo "生成deguard_me"
cd deguard
./finalimage.py --delta data/delta/medisable --version 11.6.0.1126 --pch H --sku 2M --fake-fpfs data/fpfs/zero --input data/delta/medisable/flashregion_2_intel_me.bin --output data/delta/medisable/me_deguard.bin
cd ..

echo "对烧录器固件进行patch"
./patch_fd_me.sh ./deguard/data/delta/medisable/me_deguard.bin ./BIOS_DUMP.bin
echo "删除工作目录"
rm -rf deguard/data/delta/medisable
