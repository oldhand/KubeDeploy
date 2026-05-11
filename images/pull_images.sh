#!/bin/bash


# 获取CPU架构
cpu_arch=$(uname -m)
echo "CPU架构: $cpu_arch"

# 定义华为云SWR容器仓库地址
SWR_REPOSITORY="swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io"

# 定义需要拉取的镜像列表（相对于SWR仓库的路径）
IMAGES=(
    "mysql:5.7.44"
    "redis:8.2.1"
    "openjdk:8-jdk-alpine"
    "minio/minio:RELEASE.2025-09-07T16-13-09Z"
)

# 拉取镜像并保存为tar文件（仅当本地不存在时）
for image in "${IMAGES[@]}"; do
    # 拼接完整的镜像地址
    full_image="${SWR_REPOSITORY}/${image}"

    # 生成tar文件名（仅使用原始镜像名，替换特殊字符）
    # 不包含SWR仓库路径，只使用IMAGES数组中的原始名称
    tar_file=$(echo "${image}" | tr '/: ' '_' ).tar

    echo "检查 ${full_image} 是否存在..."
    # 通过docker images检查镜像是否存在
    if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${full_image}$"; then
        echo "${full_image} 已存在于本地"

        # 检查tar文件是否存在，如果不存在则保存
        if [ ! -f "$tar_file" ]; then
            echo "tar文件 ${tar_file} 不存在，正在保存 ${full_image} 到 ${tar_file} ..."
            if docker save -o "$tar_file" "$full_image"; then
                echo "${full_image} 保存成功"
            else
                echo "保存 ${full_image} 失败"
            fi
        else
            echo "tar文件 ${tar_file} 已存在，跳过保存"
        fi
    else
        echo "${full_image} 不存在，正在拉取..."
        if docker pull "$full_image"; then
            echo "正在保存 ${full_image} 到 ${tar_file} ..."
            if docker save -o "$tar_file" "$full_image"; then
                echo "${full_image} 保存成功"
            else
                echo "保存 ${full_image} 失败"
            fi
        else
            echo "拉取 ${full_image} 失败"
        fi
    fi

    echo "----------------------------------------"
done

echo "所有操作完成"
echo "本地已保存的镜像tar文件："
for image in "${IMAGES[@]}"; do
    full_image="${SWR_REPOSITORY}/${image}"
    tar_file=$(echo "${image}" | tr '/: ' '_' ).tar
    echo "- ${tar_file} (对应原始镜像: ${image})"
done


mv -f *.tar $cpu_arch
