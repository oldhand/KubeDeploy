import os
import shutil
import time
import sys
import tempfile
from pathlib import Path

def get_root_path():
    """Linux系统根目录固定为/"""
    return "/"

def validate_root_permission(root_path):
    """验证对根目录的写入权限"""
    test_file = Path(root_path) / ".disk_test_perm_check.tmp"
    try:
        with open(test_file, "w") as f:
            f.write("permission check")
        os.remove(test_file)
        return True
    except PermissionError:
        print(f"错误：没有根目录 {root_path} 的写入权限，请使用sudo运行")
        return False
    except Exception as e:
        print(f"根目录权限验证失败：{str(e)}")
        return False

def calculate_disk_targets(root_path, target_pct=88, max_pct=90):
    """计算目标占用空间（确保不超过最大限制）"""
    disk = shutil.disk_usage(root_path)
    total = disk.total
    used = disk.used
    free = disk.free

    # 计算目标和最大允许占用字节数（转为整数避免浮点数问题）
    target_used = int(total * target_pct / 100)
    max_used = int(total * max_pct / 100)

    # 需要额外占用的空间（不能为负，且不超过最大允许增量）
    need_occupy = target_used - used
    need_occupy = max(0, min(need_occupy, max_used - used))

    return {
        "total": total,
        "used": used,
        "free": free,
        "target_used": target_used,
        "max_used": max_used,
        "need_occupy": need_occupy,
        "current_pct": (used / total) * 100
    }

def create_occupancy_files(root_path, need_occupy):
    """在根目录创建临时文件占用空间（使用专用目录管理）"""
    temp_dir = Path(root_path) / "disk_stress_test_tmp"
    temp_dir.mkdir(exist_ok=True, mode=0o700)  # 权限限制为仅所有者可访问
    temp_files = []
    occupied = 0
    chunk_size = 100 * 1024 * 1024  # 每次创建100MB文件

    print(f"临时文件存储目录：{temp_dir}")

    try:
        while occupied < need_occupy:
            # 实时检查当前使用率，防止超过90%
            current = shutil.disk_usage(root_path)
            current_pct = (current.used / current.total) * 100
            if current_pct >= 70:
                print(f"\n已达最大限制 {current_pct:.1f}%，停止创建文件")
                break

            # 计算本次创建的文件大小
            remaining = need_occupy - occupied
            current_file_size = min(chunk_size, remaining)
            if current_file_size <= 0:
                break

            # 创建临时文件（使用随机文件名避免冲突）
            with tempfile.NamedTemporaryFile(
                mode='wb',
                dir=temp_dir,
                prefix='disk_occupy_',
                delete=False
            ) as f:
                temp_files.append(f.name)
                # 分块写入（每次10MB，避免内存占用过高）
                wrote = 0
                while wrote < current_file_size:
                    write_block = min(10 * 1024 * 1024, current_file_size - wrote)
                    f.write(b'\x00' * write_block)  # 填充空字节
                    wrote += write_block

            occupied += current_file_size
            # 打印进度（转换为GB显示）
            print(f"已占用: {occupied / (1024**3):.2f} GB | 当前使用率: {current_pct:.1f}%", end='\r')

        print("\n文件创建完成")
        return temp_files, temp_dir

    except Exception as e:
        print(f"\n创建文件失败：{str(e)}")
        # 立即清理已创建的文件
        cleanup_files(temp_files, temp_dir)
        sys.exit(1)

def cleanup_files(file_list, temp_dir):
    """清理所有临时文件和目录"""
    if not file_list and not temp_dir.exists():
        return

    print("\n开始清理临时文件...")
    # 删除所有临时文件
    for file_path in file_list:
        try:
            if os.path.exists(file_path):
                os.remove(file_path)
                # 减少输出冗余，只显示前3个和最后1个文件
                if file_list.index(file_path) < 3 or file_list.index(file_path) == len(file_list)-1:
                    print(f"已删除: {file_path}")
        except Exception as e:
            print(f"删除失败 {file_path}: {str(e)}")

    # 删除临时目录
    if temp_dir and temp_dir.exists():
        try:
            temp_dir.rmdir()
            print(f"已删除临时目录: {temp_dir}")
        except OSError:
            print(f"警告：临时目录 {temp_dir} 未完全清空，可能需要手动清理")

def main():
    root = get_root_path()
    print(f"目标根目录：{root}")

    # 验证权限（Linux根目录通常需要sudo）
    if not validate_root_permission(root):
        sys.exit(1)

    # 计算磁盘目标占用
    disk_info = calculate_disk_targets(root)
    print(f"根目录总空间: {disk_info['total'] / (1024**3):.2f} GB")
    print(f"当前使用率: {disk_info['current_pct']:.1f}% ({disk_info['used'] / (1024**3):.2f} GB)")
    print(f"需要额外占用: {disk_info['need_occupy'] / (1024**3):.2f} GB 以达到 {88}%")

    # 若已满足条件，无需创建文件
    if disk_info['need_occupy'] <= 0:
        print("当前磁盘使用率已满足要求，无需操作")
        sys.exit(0)

    # 创建占用文件
    temp_files, temp_dir = create_occupancy_files(root, disk_info['need_occupy'])

    # 持续占用30分钟（1800秒）
    duration = 1800
    print(f"\n将保持磁盘占用状态 {duration//60} 分钟，按 Ctrl+C 可提前退出")
    try:
        # 每10秒更新一次状态
        for i in range(duration // 10):
            current = shutil.disk_usage(root)
            current_pct = (current.used / current.total) * 100
            remaining = duration - (i * 10)
            print(f"剩余时间: {remaining//60:02d}:{remaining%60:02d} | 当前使用率: {current_pct:.1f}%", end='\r')
            time.sleep(10)
        print("\n\n30分钟已结束，开始清理...")

    except KeyboardInterrupt:
        print("\n\n检测到 Ctrl+C，正在清理临时文件...")
    finally:
        # 确保无论何种退出方式都清理文件
        cleanup_files(temp_files, temp_dir)
        # 输出清理后的状态
        final = shutil.disk_usage(root)
        final_pct = (final.used / final.total) * 100
        print(f"清理完成，当前磁盘使用率: {final_pct:.1f}%")
        sys.exit(0)

if __name__ == "__main__":
    main()
