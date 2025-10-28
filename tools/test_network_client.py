import socket
import time
import sys

def main():
    if len(sys.argv) != 2:
        print("使用方法: python client.py <服务器IP>")
        sys.exit(1)

    # 配置服务器地址和端口（与服务端保持一致）
    SERVER_IP = sys.argv[1]
    SERVER_PORT = 5050
    DURATION = 30 * 60  # 测试持续时间：30分钟（秒）
    DATA_BLOCK = 4 * 1024 * 1024  # 每次发送4MB数据块（可根据网络调整）

    # 创建TCP socket并连接服务器
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.connect((SERVER_IP, SERVER_PORT))
            print(f"已连接到服务器 {SERVER_IP}:{SERVER_PORT}，开始发送数据（持续30分钟，按Ctrl+C退出）...")

            start_time = time.time()
            data = b'x' * DATA_BLOCK  # 生成二进制数据块（内容不影响速率，仅填充字节）

            try:
                while time.time() - start_time < DURATION:
                    # 持续发送数据（sendall确保数据完全发送）
                    s.sendall(data)
            except KeyboardInterrupt:
                print("\n用户中断，停止发送数据")
            finally:
                elapsed = time.time() - start_time
                print(f"\n测试结束，实际持续时间: {elapsed:.2f} 秒")

    except ConnectionRefusedError:
        print(f"连接失败：服务器 {SERVER_IP}:{SERVER_PORT} 未响应")
    except Exception as e:
        print(f"发生错误: {e}")

if __name__ == "__main__":
    main()
