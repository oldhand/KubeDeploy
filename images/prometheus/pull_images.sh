#!/bin/bash

# 定义需要拉取的镜像列表
IMAGES=(
    "prom/node-exporter:v1.8.2"
    "prom/prometheus:v3.6.0"
    "prom/alertmanager:v0.28.1"
    "grafana/grafana:12.2"
    "k8s.gcr.io/kube-state-metrics/kube-state-metrics:v2.9.2"
)

# 拉取镜像并保存为tar文件（仅当本地不存在时）
for image in "${IMAGES[@]}"; do
    # 生成tar文件名（替换特殊字符）
    tar_file=$(echo "$image" | tr '/: ' '_' ).tar

    echo "检查 $image 是否存在..."
    # 通过docker images检查镜像是否存在
    if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${image}$"; then
        echo "$image 已存在于本地"

        # 检查tar文件是否存在，如果不存在则保存
        if [ ! -f "$tar_file" ]; then
            echo "tar文件 $tar_file 不存在，正在保存 $image 到 $tar_file ..."
            if docker save -o "$tar_file" "$image"; then
                echo "$image 保存成功"
            else
                echo "保存 $image 失败"
            fi
        else
            echo "tar文件 $tar_file 已存在，跳过保存"
        fi
    else
        echo "$image 不存在，正在拉取..."
        if docker pull "$image"; then
            echo "正在保存 $image 到 $tar_file ..."
            if docker save -o "$tar_file" "$image"; then
                echo "$image 保存成功"
            else
                echo "保存 $image 失败"
            fi
        else
            echo "拉取 $image 失败"
        fi
    fi

    echo "----------------------------------------"
done

echo "所有操作完成"
echo "本地已保存的镜像tar文件："
for image in "${IMAGES[@]}"; do
    tar_file=$(echo "$image" | tr '/: ' '_' ).tar
    echo "- $tar_file ($image)"
done
