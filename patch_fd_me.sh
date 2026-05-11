#!/bin/sh

# 用法:
# ./patch_coffee_me.sh me_deguard.bin dump.bin

ME_FILE="$1"
DUMP_FILE="$2"

# 看了原厂备份，发现地址在0x3000
ME_OFFSET=$((0x3000))
ME_TARGET_SIZE=$((0x6FD000))
FD_OFFSET=$((0x102))
FD_OFFSET2=$((0x307))

if [ $# -ne 2 ]; then
    echo "用法: $0 <me_deguard.bin> <dump.bin>"
    exit 1
fi

if [ ! -f "$ME_FILE" ]; then
    echo "错误：找不到 ME 文件: $ME_FILE"
    exit 1
fi

if [ ! -f "$DUMP_FILE" ]; then
    echo "错误：找不到 dump 文件: $DUMP_FILE"
    exit 1
fi

echo "=============================="
echo " Step 5 - 补齐 ME 文件到 0x6FD000"
echo "=============================="

ME_ORIGINAL_SIZE=$(stat -c%s "$ME_FILE")

printf "原始 ME 文件大小: %d bytes (0x%X)\n" \
    "$ME_ORIGINAL_SIZE" \
    "$ME_ORIGINAL_SIZE"

if [ "$ME_ORIGINAL_SIZE" -gt "$ME_TARGET_SIZE" ]; then
    echo "错误：ME 文件已经大于 0x6FD000"
    exit 1
fi

ME_BACKUP="${ME_FILE}.bak"
cp "$ME_FILE" "$ME_BACKUP" || {
    echo "错误：ME 文件备份失败"
    exit 1
}

echo "已备份 ME 文件 -> $ME_BACKUP"

NEED_APPEND=$((ME_TARGET_SIZE - ME_ORIGINAL_SIZE))

printf "需要追加: %d bytes (0x%X) 的 0xFF\n" \
    "$NEED_APPEND" \
    "$NEED_APPEND"

if [ "$NEED_APPEND" -gt 0 ]; then
    dd if=/dev/zero bs=1 count="$NEED_APPEND" 2>/dev/null \
        | tr '\000' '\377' >> "$ME_FILE"
fi

ME_NEW_SIZE=$(stat -c%s "$ME_FILE")

printf "补齐后 ME 文件大小: %d bytes (0x%X)\n" \
    "$ME_NEW_SIZE" \
    "$ME_NEW_SIZE"

if [ "$ME_NEW_SIZE" -ne "$ME_TARGET_SIZE" ]; then
    echo "错误：ME 文件补齐失败"
    exit 1
fi

echo
echo "=============================="
echo " Step 6 - 写入 dump 的 ME 区域"
echo "=============================="

DUMP_BACKUP="${DUMP_FILE}.bak"
cp "$DUMP_FILE" "$DUMP_BACKUP" || {
    echo "错误：dump 备份失败"
    exit 1
}

echo "已备份 dump 文件 -> $DUMP_BACKUP"

dd if="$ME_FILE" \
   of="$DUMP_FILE" \
   bs=1 \
   seek="$ME_OFFSET" \
   count="$ME_TARGET_SIZE" \
   conv=notrunc \
   status=none

if [ $? -ne 0 ]; then
    echo "错误：ME 写入失败"
    exit 1
fi

echo "ME 已写入 dump"
printf "写入位置: offset 0x%X\n" "$ME_OFFSET"
printf "写入长度: 0x%X\n" "$ME_TARGET_SIZE"

echo
echo "=============================="
echo " Step 7 - 修改 FD offset 0x102"
echo "=============================="

OLD_VALUE=$(dd if="$DUMP_FILE" \
    bs=1 \
    skip="$FD_OFFSET" \
    count=1 \
    2>/dev/null \
    | od -An -tx1 \
    | tr -d ' \n')

echo "原值: 0x$OLD_VALUE"

printf '\x91' \
    | dd of="$DUMP_FILE" \
         bs=1 \
         seek="$FD_OFFSET" \
         count=1 \
         conv=notrunc \
         2>/dev/null

NEW_VALUE=$(dd if="$DUMP_FILE" \
    bs=1 \
    skip="$FD_OFFSET" \
    count=1 \
    2>/dev/null \
    | od -An -tx1 \
    | tr -d ' \n')

echo "新值: 0x$NEW_VALUE"

echo
echo "=============================="
echo " Step 8 - 修改 FD offset 0x307"
echo "=============================="
# 这里的 skip 必须加 $
OLD_VALUE2=$(dd if="$DUMP_FILE" \
    bs=1 \
    skip="$FD_OFFSET2" \
    count=1 \
    2>/dev/null \
    | od -An -tx1 \
    | tr -d ' \n')

echo "原值: 0x$OLD_VALUE2"

# 这里的 seek 必须加 $
printf '\xa0' \
    | dd of="$DUMP_FILE" \
         bs=1 \
         seek="$FD_OFFSET2" \
         count=1 \
         conv=notrunc \
         2>/dev/null

# 这里的 skip 必须加 $
NEW_VALUE2=$(dd if="$DUMP_FILE" \
    bs=1 \
    skip="$FD_OFFSET2" \
    count=1 \
    2>/dev/null \
    | od -An -tx1 \
    | tr -d ' \n')

echo "新值: 0x$NEW_VALUE2"

echo
echo "=============================="
echo " 全部完成"
echo "=============================="
echo "已完成:"
echo "  [5] 补齐 ME"
echo "  [6] 写入 dump 的 ME 区域"
echo "  [7] 修改 FD 0x102 -> 0x91"
echo "  [8] 修改 FD 0x307 -> 0xa0"
