import socket
import time
import sys

def main():
    # 配置服务端监听地址和端口
    HOST = ''  # 监听所有可用网络接口
    PORT = 5050  # 自定义端口，确保未被占用

    # 创建TCP socket
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        try:
            s.bind((HOST, PORT))
            s.listen(1)  # 只接受一个客户端连接
            print(f"服务端启动，监听 {HOST}:{PORT} ...")

            # 等待客户端连接
            conn, addr = s.accept()
            with conn:
                print(f"客户端 {addr} 已连接")

                # 初始化统计变量
                total_bytes = 0
                last_time = time.time()
                last_bytes = 0
                interval = 1  # 每秒统计一次

                while True:
                    # 接收数据（每次最多接收4MB）
                    data = conn.recv(4 * 1024 * 1024)
                    if not data:  # 客户端断开连接
                        print("\n客户端已断开连接")
                        break

                    # 累计接收字节数
                    received = len(data)
                    total_bytes += received

                    # 每秒计算一次速率
                    current_time = time.time()
                    if current_time - last_time >= interval:
                        # 计算当前秒的接收字节数
                        bytes_per_sec = total_bytes - last_bytes
                        # 转换为Mbps（1字节=8比特，1Mbps=1e6比特/秒）
                        speed_mbps = (bytes_per_sec * 8) / (1024 * 1024)  # 用1024更贴合实际网络统计

                        # 打印统计信息
                        print(f"当前速度: {speed_mbps:.2f} Mbps | 累计接收: {total_bytes/(1024*1024):.2f} MB", end='\r')

                        # 更新时间和字节数基准
                        last_time = current_time
                        last_bytes = total_bytes

        except KeyboardInterrupt:
            print("\n服务端被用户中断")
        except Exception as e:
            print(f"发生错误: {e}")

if __name__ == "__main__":
    main()
