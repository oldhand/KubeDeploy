#!/bin/bash

#######################################
# 第一步：检查并准备 Docker 镜像（本地SWR→本地缓存→拉取SWR远程）
#######################################

echo "===== 第一步：检查并准备 Docker 镜像 ====="
SWR_ALPINE_IMAGE="swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/library/alpine:3.18"
SWR_GOLANG_IMAGE="swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/golang:1.20.6-alpine3.18"
ALPINE_TAR="images/alpine_3.18.tar.gz"
GOLANG_ALPINE_TAR="images/golang_1.20.6-alpine3.18.tar.gz"

echo "确认Docker服务运行中..."
if ! docker info &> /dev/null; then
    echo "错误：Docker服务未运行，请启动（如：sudo systemctl start docker）"
    exit 1
fi

if [ ! -d "images" ]; then
    mkdir -p images || { echo "错误：创建images目录失败"; exit 1; }
fi

ALPINE_READY="false"
GOLANG_READY="false"

if docker inspect "$SWR_ALPINE_IMAGE" &> /dev/null; then
    echo "✅ 本地已存在SWR镜像：$SWR_ALPINE_IMAGE"
    ALPINE_READY="true"
else
    echo "❌ 本地未找到SWR镜像：$SWR_ALPINE_IMAGE"
fi

if docker inspect "$SWR_GOLANG_IMAGE" &> /dev/null; then
    echo "✅ 本地已存在SWR镜像：$SWR_GOLANG_IMAGE"
    GOLANG_READY="true"
else
    echo "❌ 本地未找到SWR镜像：$SWR_GOLANG_IMAGE"
fi

if [ "$ALPINE_READY" = "false" ]; then
    if [ -f "$ALPINE_TAR" ]; then
        echo "使用本地缓存tar包：$ALPINE_TAR"
        if ! tar -xzf "$ALPINE_TAR" -C images/; then
            echo "错误：解压$ALPINE_TAR失败"
            exit 1
        fi
        ALPINE_IMAGE="images/alpine_3.18.tar"
        if ! docker load -i "$ALPINE_IMAGE"; then
            echo "错误：加载$ALPINE_IMAGE失败"
            exit 1
        fi
        ALPINE_READY="true"
    else
        echo "从SWR远程拉取：$SWR_ALPINE_IMAGE"
        if ! docker pull "$SWR_ALPINE_IMAGE"; then
            echo "错误：拉取$SWR_ALPINE_IMAGE失败"
            exit 1
        fi
        ALPINE_READY="true"
    fi
fi

if [ "$GOLANG_READY" = "false" ]; then
    if [ -f "$GOLANG_ALPINE_TAR" ]; then
        echo "使用本地缓存tar包：$GOLANG_ALPINE_TAR"
        if ! tar -xzf "$GOLANG_ALPINE_TAR" -C images/; then
            echo "错误：解压$GOLANG_ALPINE_TAR失败"
            exit 1
        fi
        GOLANG_IMAGE="images/golang_1.20.6-alpine3.18.tar"
        if ! docker load -i "$GOLANG_IMAGE"; then
            echo "错误：加载$GOLANG_IMAGE失败"
            exit 1
        fi
        GOLANG_READY="true"
    else
        echo "从SWR远程拉取：$SWR_GOLANG_IMAGE"
        if ! docker pull "$SWR_GOLANG_IMAGE"; then
            echo "错误：拉取$SWR_GOLANG_IMAGE失败"
            exit 1
        fi
        GOLANG_READY="true"
    fi
fi

echo "Docker镜像准备完成"


#######################################
# 第二步：执行make docker打包镜像
#######################################

echo -e "\n===== 第二步：打包Docker镜像 ====="
if ! docker info &> /dev/null; then
    echo "错误：Docker服务已停止"
    exit 1
fi
if [ ! -f "Makefile" ]; then
    echo "错误：未找到Makefile"
    exit 1
fi

echo "执行make docker..."
if ! make docker; then
    echo "错误：make docker失败"
    exit 1
fi
echo "镜像打包完成，可通过docker images查看"


#######################################
# 第三步：创建目录并保存压缩Docker镜像（优化路径格式）
#######################################

echo -e "\n===== 第三步：保存并压缩镜像 ====="
TARGET_DIR="../../images/alert/x86_64"
IMAGE_NAME="feiyu563/prometheus-alert:v4.9.1"
ALERT_TAR_FILE="prometheus-alert_v4.9.1.tar"
TAR_FILE="${TARGET_DIR}/${ALERT_TAR_FILE}"
TAR_GZ_FILE="${ALERT_TAR_FILE}.gz"

# 1. 创建目标目录
echo "创建目录：${TARGET_DIR}"
if ! mkdir -p "${TARGET_DIR}"; then
    echo "错误：创建目录${TARGET_DIR}失败（检查路径权限）"
    exit 1
fi

# 2. 检查目标镜像是否存在
echo "检查镜像${IMAGE_NAME}是否存在..."
if ! docker inspect "${IMAGE_NAME}" &> /dev/null; then
    echo "错误：未找到镜像${IMAGE_NAME}，无法执行docker save"
    exit 1
fi

# 3. 保存镜像为tar文件
echo "保存镜像到${TAR_FILE}..."
if ! docker save "${IMAGE_NAME}" -o "${TAR_FILE}"; then
    echo "错误：docker save失败（检查路径写入权限）"
    exit 1
fi

echo "压缩为${ALERT_TAR_FILE}..."
if ! (cd "${TARGET_DIR}" && tar czvf "${TAR_GZ_FILE}" "${ALERT_TAR_FILE}"); then
    echo "错误：tar压缩失败（检查文件是否存在）"
    exit 1
fi

echo "全流程执行完成！"
