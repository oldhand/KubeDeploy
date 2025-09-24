#!/bin/bash

# 显示使用帮助
usage() {
    echo "用法: $0 <设备路径>"
    echo "示例: $0 /dev/sdb"
    exit 1
}

# 检查是否提供了设备参数
if [ $# -ne 1 ]; then
    echo "错误: 请指定要操作的设备"
    usage
fi

DEVICE="$1"

# 检查设备是否存在
if [ ! -b "$DEVICE" ]; then
    echo "错误: 设备 $DEVICE 不存在"
    exit 1
fi

# 检查是否以root权限运行
if [ "$(id -u)" -ne 0 ]; then
    echo "错误: 此脚本需要root权限运行"
    exit 1
fi

echo "===== 操作前的磁盘信息 ====="
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT,LABEL,SIZE

# 确认操作
read -p "即将对设备 $DEVICE 执行清理操作，这将删除所有数据。是否继续? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "操作已取消"
    exit 0
fi

# 1. 清除分区表（彻底删除所有分区）
echo "===== 清除分区表 ====="
sgdisk --zap-all "$DEVICE"

# 2. 擦除设备开头 100MB 数据（清除 Ceph 残留签名）
echo "===== 擦除开头100MB数据 ====="
dd if=/dev/zero of="$DEVICE" bs=1M count=100 oflag=direct

# 3. 检测设备大小并擦除整个设备
echo "===== 检测设备大小 ====="
DEVICE_SIZE=$(lsblk -b -n -o SIZE "$DEVICE")
# 转换为GB（向上取整）
GB_SIZE=$(( (DEVICE_SIZE + 1073741823) / 1073741824 ))
echo "设备 $DEVICE 大小约为 $GB_SIZE GB，开始全盘擦除..."

dd if=/dev/zero of="$DEVICE" bs=1G count="$GB_SIZE" oflag=direct

# 4. 检测是否仍有旧 OSD 残留（预期输出为空 {}）
echo "===== 检查OSD残留 ====="
ceph-volume raw list --format json

echo "===== 操作后的磁盘信息 ====="
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT,LABEL,SIZE

echo "设备 $DEVICE 清理完成"
