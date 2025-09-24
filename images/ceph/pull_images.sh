#!/bin/bash

# 从docker images输出中提取的镜像列表
IMAGES=(
    "quay.io/rook/ceph:v1.18.2"
    "quay.io/ceph/ceph:v19.2.3"
    "quay.io/ceph/cosi:v0.1.2"
    "quay.io/cephcsi/cephcsi:v3.15.0"
    "quay.io/csiaddons/k8s-sidecar:v0.13.0"
    "registry.k8s.io/sig-storage/csi-resizer:v1.13.2"
    "registry.k8s.io/sig-storage/csi-snapshotter:v8.2.1"
    "registry.k8s.io/sig-storage/csi-attacher:v4.8.1"
    "registry.k8s.io/sig-storage/csi-provisioner:v5.2.0"
    "registry.k8s.io/sig-storage/csi-node-driver-registrar:v2.13.0"
    "gcr.io/k8s-staging-sig-storage/objectstorage-sidecar:v20240513-v0.1.0-35-gefb3255"
)

# 处理镜像：检查是否存在，不存在则拉取，然后保存为tar文件
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
