import psutil
import time
import sys
import os

def allocate_memory(max_percent=90, duration_seconds=1800):  # 30分钟=1800秒
    """
    分配内存至不超过90%，持续指定时间（默认30分钟），支持Ctrl+C退出并释放内存
    """
    allocated_chunks = []  # 存储分配的内存块，用于最终释放
    try:
        # 获取系统内存信息
        mem = psutil.virtual_memory()
        total_memory = mem.total
        print(f"系统总内存: {total_memory / (1024**3):.2f} GB")
        print(f"初始内存使用: {mem.used / (1024**3):.2f} GB ({mem.percent}%)")

        # 每次分配100MB块，避免一次性分配过大
        chunk_size = 100 * 1024 * 1024  # 100MB/块
        allocated = 0

        print(f"\n开始分配内存（最大不超过{max_percent}%）...")
        while True:
            current_mem = psutil.virtual_memory()
            # 若当前使用率已达或超过最大值，停止分配
            if current_mem.percent >= max_percent:
                print(f"\n已达最大内存使用率 {current_mem.percent:.1f}%，停止分配")
                break

            # 计算剩余可分配空间（留1%缓冲，避免超上限）
            remaining = int((total_memory * (max_percent - 1) / 100) - current_mem.used)
            if remaining <= 0:
                print(f"\n剩余可分配内存不足，当前使用率 {current_mem.percent:.1f}%")
                break

            # 本次分配大小（不超过剩余空间和块大小）
            current_chunk = min(chunk_size, remaining)
            if current_chunk <= 0:
                break

            # 分配内存块
            try:
                chunk = bytearray(current_chunk)
                allocated_chunks.append(chunk)
                allocated += current_chunk

                # 每分配约1GB打印一次进度
                if allocated % (1024**3) < chunk_size:
                    print(f"已分配: {allocated / (1024**3):.2f} GB, 当前使用率: {current_mem.percent:.1f}%")

                time.sleep(0.1)  # 降低系统压力
            except MemoryError:
                print("\n内存分配失败，系统内存不足")
                break

        # 最终内存状态
        final_mem = psutil.virtual_memory()
        print(f"\n内存分配完成，最终使用率: {final_mem.percent:.1f}%")
        print(f"将保持此内存占用状态 {duration_seconds//60}分钟（{duration_seconds}秒），按Ctrl+C可提前退出并释放内存...")

        # 持续保持内存占用（30分钟）
        time.sleep(duration_seconds)

        # 时间结束后自动释放
        print(f"\n{duration_seconds}秒已结束，开始释放内存...")

    except KeyboardInterrupt:
        print("\n检测到Ctrl+C，正在释放内存...")
    except Exception as e:
        print(f"发生错误: {str(e)}")
    finally:
        # 释放所有分配的内存（无论正常结束还是异常退出）
        del allocated_chunks
        print("已释放所有分配的内存")
        print(f"释放后内存使用率: {psutil.virtual_memory().percent:.1f}%")
        sys.exit(0)


if __name__ == "__main__":
    # 检查依赖
    try:
        import psutil
    except ImportError:
        print("请先安装psutil: pip install psutil")
        sys.exit(1)

    # 执行内存分配（最大90%，持续30分钟）
    allocate_memory(90, 1800)
