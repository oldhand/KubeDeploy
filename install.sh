#!/bin/bash



# 获取操作系统名称
os_name=$(cat /etc/os-release | grep NAME | head -n1 | cut -d= -f2 | sed 's/"//g' | cut -d' ' -f1)

# 获取CPU架构
cpu_arch=$(uname -m)

# 输出结果
echo "操作系统: $os_name"
echo "CPU架构: $cpu_arch"

ansible-playbook -i hosts.ini install.yml -k




