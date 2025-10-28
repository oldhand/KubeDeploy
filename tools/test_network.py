import http.client
import time
import sys
import random
from datetime import datetime
import statistics

# 目标服务器配置（固定为httpbin.ceshiren.com）
TARGET_SERVER = {
    "host": "httpbin.ceshiren.com",
    "path": "/post",
    "ssl": True,
    "timeout": 15  # 连接超时时间（秒）
}

def generate_test_data(size_mb=10):
    """生成指定大小的随机测试数据（默认10MB，平衡精度与效率）"""
    try:
        size_bytes = int(size_mb * 1024 * 1024)  # 转换为字节
        return random.randbytes(size_bytes)  # 生成随机字节（避免服务器压缩）
    except MemoryError:
        print(f"❌ 生成{size_mb}MB数据失败（内存不足），尝试减小数据量")
        return None

def test_upload_speed(server, data):
    """测试单次上传速度并返回结果"""
    start_time = time.time()
    conn = None
    try:
        # 建立HTTPS连接
        conn = http.client.HTTPSConnection(
            server["host"],
            timeout=server["timeout"]
        )

        # 发送POST请求（上传测试数据）
        headers = {'Content-Type': 'application/octet-stream'}
        conn.request("POST", server["path"], body=data, headers=headers)
        response = conn.getresponse()

        # 验证响应状态（200-299为成功）
        if 200 <= response.status < 300:
            duration = time.time() - start_time  # 耗时（秒）
            data_size_mb = len(data) / (1024 * 1024)  # 数据大小（MB）
            speed_mbps = (data_size_mb * 8) / duration  # 转换为Mbps（1字节=8比特）
            return {
                "success": True,
                "speed": round(speed_mbps, 2),
                "duration": round(duration, 2)
            }
        else:
            return {
                "success": False,
                "reason": f"服务器响应异常（状态码：{response.status}）"
            }

    except Exception as e:
        return {
            "success": False,
            "reason": f"连接失败：{str(e)}"
        }
    finally:
        # 确保连接关闭，释放资源
        if conn:
            try:
                conn.close()
            except:
                pass

def main():
    print("=== httpbin.ceshiren.com 专用网速测试 ===")
    print(f"目标服务器：{TARGET_SERVER['host']}")
    print(f"测试类型：上传速度（持续30分钟）")
    print(f"数据大小：10MB | 无间隔测试 | 按Ctrl+C可提前退出\n")

    # 生成测试数据（仅生成一次，重复使用）
    test_data = generate_test_data(size_mb=10)
    if not test_data:
        sys.exit(1)

    results = []  # 存储所有有效测试结果
    total_duration = 1800  # 总测试时长（30分钟 = 1800秒）
    start_time = time.time()

    try:
        # 持续测试直到达到30分钟
        while time.time() - start_time < total_duration:
            # 执行单次上传测试
            result = test_upload_speed(TARGET_SERVER, test_data)
            timestamp = datetime.now().strftime('%H:%M:%S')  # 当前时间戳

            if result["success"]:
                # 记录成功结果并实时输出
                results.append(result["speed"])
                print(f"[{timestamp}] 上传速度：{result['speed']} Mbps | 耗时：{result['duration']}秒")
            else:
                # 输出失败信息（不中断测试）
                print(f"[{timestamp}] ❌ 测试失败：{result['reason']}")

            # 无间隔，立即开始下一次测试（如需减轻系统负载，可添加 time.sleep(0.1)）

        print("\n=== 30分钟测试已完成 ===")

    except KeyboardInterrupt:
        print("\n\n=== 检测到Ctrl+C，已停止测试 ===")
    finally:
        # 输出统计结果
        if results:
            print("\n===== 测试统计信息 =====")
            print(f"总测试次数：{len(results)}次")
            print(f"平均上传速度：{statistics.mean(results):.2f} Mbps")
            print(f"最高上传速度：{max(results):.2f} Mbps")
            print(f"最低上传速度：{min(results):.2f} Mbps")
            print(f"速度标准差：{statistics.stdev(results):.2f} Mbps（值越小越稳定）")
        else:
            print("未获取到有效测试数据")

        sys.exit(0)

if __name__ == "__main__":
    main()
