import time
import math
from multiprocessing import Process, cpu_count

def cpu_work(duration):
    """单个核心的CPU密集型计算（填满指定时长）"""
    end_time = time.time() + duration
    temp = 0  # 避免计算被优化掉
    while time.time() < end_time:
        # 密集计算：通过复杂运算和循环确保CPU持续工作
        result = math.sin(0.12345) * math.cos(0.6789) * math.tan(0.13579)
        for _ in range(10000):  # 计算量可根据CPU性能调整
            temp += result

def core_worker(work_time, rest_time):
    """单个核心的工作-休息循环"""
    while True:
        cpu_work(work_time)  # 占用核心
        time.sleep(rest_time)  # 释放核心

def main():
    try:
        # 获取CPU核心数（决定启动多少个进程）
        core_num = cpu_count()
        print(f"检测到CPU核心数：{core_num}，开始控制总体CPU使用率在80%左右（按Ctrl+C停止）...")

        # 工作与休息时间比例1:1（单个核心理论使用率50%）
        work_time = 0.85  # 计算时长（秒）
        rest_time = 0.15  # 休息时长（秒）

        # 为每个核心启动一个进程
        processes = []
        for _ in range(core_num):
            p = Process(target=core_worker, args=(work_time, rest_time))
            p.start()
            processes.append(p)

        # 等待所有进程（避免主进程退出）
        for p in processes:
            p.join()

    except KeyboardInterrupt:
        print("\n已停止")
    finally:
        # 停止所有子进程
        for p in processes:
            if p.is_alive():
                p.terminate()

if __name__ == "__main__":
    main()
